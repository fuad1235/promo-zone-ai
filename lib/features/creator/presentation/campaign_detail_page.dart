import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../campaigns/presentation/campaign_providers.dart';

class CreatorCampaignDetailPage extends ConsumerStatefulWidget {
  const CreatorCampaignDetailPage({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<CreatorCampaignDetailPage> createState() =>
      _CreatorCampaignDetailPageState();
}

class _CreatorCampaignDetailPageState
    extends ConsumerState<CreatorCampaignDetailPage> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final campaign = ref.watch(campaignByIdProvider(widget.campaignId));

    return Scaffold(
      appBar: AppBar(title: const Text('Campaign')),
      body: AsyncValueWidget(
        value: campaign,
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Campaign not found'));
          }

          final uid = ref.read(authRepositoryProvider).currentUser?.uid;
          final appUser = ref.watch(currentAppUserProvider).valueOrNull;
          final canApply = uid != null &&
              (appUser == null || appUser.role == UserRole.creator);
          final canCheckApplied = canApply;

          return FutureBuilder<bool>(
            future: canCheckApplied
                ? ref
                    .read(applicationRepositoryProvider)
                    .hasApplied(data.id, uid)
                : Future.value(false),
            builder: (context, snapshot) {
              final applied = snapshot.data ?? false;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _DetailHero(
                    payout: data.payoutAmountGhs,
                    targetViews: data.targetViews,
                    creatorsNeeded: data.creatorsNeeded,
                    endDate: data.endDate,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(data.description),
                  const SizedBox(height: 14),
                  if (data.productImages.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: PageView(
                        children: data.productImages
                            .map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return const ColoredBox(
                                        color: Color(0xFFEFF3F9),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, _, __) {
                                      return const ColoredBox(
                                        color: Color(0xFFEFF3F9),
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 36,
                                            color: Color(0xFF6C86AA),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (data.productImages.isNotEmpty) const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Content Rules',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RuleRow(
                          label: 'Mention',
                          value: (data.rules['mention'] ?? '-').toString(),
                        ),
                        _RuleRow(
                          label: 'Do / Don\'t',
                          value: (data.rules['doDont'] ?? '-').toString(),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ((data.rules['hashtags'] ?? []) as List)
                              .map((e) => e.toString())
                              .where((e) => e.trim().isNotEmpty)
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  avatar: const Icon(Icons.tag, size: 16),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Timeline',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RuleRow(
                          label: 'Starts',
                          value: DateFormat.yMMMd().format(data.startDate),
                        ),
                        _RuleRow(
                          label: 'Ends',
                          value: DateFormat.yMMMd().format(data.endDate),
                        ),
                        _RuleRow(
                          label: 'Platform',
                          value: data.platform,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (uid == null)
                    OutlinedButton.icon(
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Login to apply'),
                    )
                  else if (!canApply)
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Business accounts cannot apply'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: applied || _isApplying
                          ? null
                          : () => _applyToCampaign(
                                data.id,
                                data.businessId,
                                data.platform,
                              ),
                      icon: Icon(applied
                          ? Icons.check_circle
                          : Icons.flash_on_rounded),
                      label: Text(
                        applied
                            ? 'Already applied'
                            : _isApplying
                                ? 'Submitting...'
                                : 'Apply to campaign',
                      ),
                    ),
                  if (!applied &&
                      snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _applyToCampaign(
    String campaignId,
    String businessId,
    String platform,
  ) async {
    final profileUrl = TextEditingController();
    final username = TextEditingController();

    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Submit campaign application',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: profileUrl,
                decoration: const InputDecoration(
                  labelText: 'Profile URL',
                  hintText: 'https://your-profile-link',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: username,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: '@creator',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final valid = profileUrl.text.trim().isNotEmpty &&
                            username.text.trim().isNotEmpty;
                        if (!valid) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (submit != true) return;
    if (!mounted) return;

    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _isApplying = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(applicationRepositoryProvider).apply(
        campaignId: campaignId,
        businessId: businessId,
        creatorId: uid,
        creatorHandleRef: {
          'platform': platform,
          'username': username.text.trim(),
          'profileUrl': profileUrl.text.trim(),
        },
        creatorSnapshot: {
          'displayName': uid,
          'niches': const <String>[],
          'metrics': const <String, dynamic>{},
        },
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Application submitted for review')),
      );
      ref.invalidate(campaignByIdProvider(widget.campaignId));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.payout,
    required this.targetViews,
    required this.creatorsNeeded,
    required this.endDate,
  });

  final int payout;
  final int targetViews;
  final int creatorsNeeded;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final viewsPerCreator = targetViews / max(1, creatorsNeeded);
    final fitScore = (45 + min(viewsPerCreator / 120, 45)).round();
    final daysLeft = max(0, endDate.difference(DateTime.now()).inDays);
    final format = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0E2A54),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign overview',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'GHS ${format.format(payout)} payout',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroMetric(label: 'Target', value: format.format(targetViews)),
              _HeroMetric(label: 'Need', value: '$creatorsNeeded creators'),
              _HeroMetric(
                label: 'Deadline',
                value: daysLeft == 0 ? 'Today' : '$daysLeft days',
              ),
              _HeroMetric(label: 'Fit score', value: '$fitScore%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A6784),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
