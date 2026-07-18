import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../ai/domain/ai_campaign_models.dart';
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
          final canUseCoach = uid != null && appUser?.role == UserRole.creator;

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
                                  backgroundColor: const Color(0xFFF7F9FD),
                                  label: Text(
                                    tag,
                                    style: const TextStyle(
                                      color: Color(0xFF244C82),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  avatar: const Icon(
                                    Icons.tag,
                                    size: 16,
                                    color: Color(0xFF0057FF),
                                  ),
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
                  if (canUseCoach) ...[
                    const SizedBox(height: 12),
                    _CreatorCoachCard(
                      onPressed: () => _openCreatorCoach(
                        data.id,
                        data.title,
                      ),
                    ),
                  ],
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

  Future<void> _openCreatorCoach(
    String campaignId,
    String campaignTitle,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatorCoachSheet(
        campaignId: campaignId,
        campaignTitle: campaignTitle,
      ),
    );
  }
}

class _CreatorCoachCard extends StatelessWidget {
  const _CreatorCoachCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF30205C), Color(0xFF174B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0x26FFFFFF),
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator Coach',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Brief-aware feedback from GPT-5.6',
                      style: TextStyle(
                        color: Color(0xFFC7D9FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Paste your hook, caption, or script. The coach checks it against '
            'this campaign and your creator profile before you submit.',
            style: TextStyle(
              color: Color(0xFFF0F4FF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2E2864),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Coach my draft'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coaching only — businesses still make every approval and payout '
            'decision.',
            style: TextStyle(
              color: Color(0xFFBCCCF1),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorCoachSheet extends ConsumerStatefulWidget {
  const _CreatorCoachSheet({
    required this.campaignId,
    required this.campaignTitle,
  });

  final String campaignId;
  final String campaignTitle;

  @override
  ConsumerState<_CreatorCoachSheet> createState() => _CreatorCoachSheetState();
}

class _CreatorCoachSheetState extends ConsumerState<_CreatorCoachSheet> {
  final _draft = TextEditingController();
  CreatorCoachResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DEED),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE5E9FF),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF4338A5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Creator Coach',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.campaignTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF5A6F8F)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result == null) _buildComposer() else _buildResult(result),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Draft to review',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _draft,
          enabled: !_loading,
          minLines: 7,
          maxLines: 12,
          maxLength: 5000,
          decoration: const InputDecoration(
            hintText:
                'Paste your hook, voiceover, caption, or full script here...',
            alignLabelWithHint: true,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                color: Color(0xFF24559A),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPT-5.6 receives the campaign requirements and relevant '
                  'creator profile context. It cannot approve work or release '
                  'funds.',
                  style: TextStyle(
                    color: Color(0xFF244C82),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _loading ? null : _review,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.fact_check_outlined),
            label: Text(
              _loading ? 'GPT-5.6 is reviewing...' : 'Review against brief',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(CreatorCoachResult result) {
    final scoreColor = result.score >= 85
        ? const Color(0xFF087A55)
        : result.score >= 60
            ? const Color(0xFFC25D12)
            : const Color(0xFFB42318);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE5F2)),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${result.score}',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.verdictLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.summary,
                      style: const TextStyle(height: 1.35),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Generated with ${result.meta.displayModel}',
                      style: const TextStyle(
                        color: Color(0xFF607898),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (result.checklist.isNotEmpty) ...[
          const SizedBox(height: 14),
          _CoachResultSection(
            title: 'Brief checklist',
            icon: Icons.checklist_rounded,
            child: Column(
              children: [
                for (final item in result.checklist) _ChecklistRow(item: item),
              ],
            ),
          ),
        ],
        if (result.strengths.isNotEmpty) ...[
          const SizedBox(height: 12),
          _StringListSection(
            title: 'What works',
            icon: Icons.thumb_up_alt_outlined,
            color: const Color(0xFF087A55),
            values: result.strengths,
          ),
        ],
        if (result.missingRequirements.isNotEmpty) ...[
          const SizedBox(height: 12),
          _StringListSection(
            title: 'Missing from the brief',
            icon: Icons.playlist_add_check_circle_outlined,
            color: const Color(0xFFC25D12),
            values: result.missingRequirements,
          ),
        ],
        if (result.riskFlags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _StringListSection(
            title: 'Claims and risk flags',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFB42318),
            values: result.riskFlags,
          ),
        ],
        const SizedBox(height: 12),
        _CoachResultSection(
          title: 'Recommended hook',
          icon: Icons.bolt_rounded,
          child: SelectableText(
            result.recommendedHook,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CoachResultSection(
          title: 'Revised draft',
          icon: Icons.edit_note_rounded,
          child: SelectableText(
            result.revisedDraft,
            style: const TextStyle(height: 1.5),
          ),
        ),
        if (result.shotList.isNotEmpty) ...[
          const SizedBox(height: 12),
          _StringListSection(
            title: 'Suggested shot list',
            icon: Icons.video_camera_back_outlined,
            color: const Color(0xFF24559A),
            values: result.shotList,
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6E8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'This score is coaching, not approval. Review the advice yourself '
            'and submit through the normal creator workflow.',
            style: TextStyle(
              color: Color(0xFF7A4B12),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              setState(() {
                _draft.text = result.revisedDraft;
                _draft.selection = TextSelection.collapsed(
                  offset: _draft.text.length,
                );
                _result = null;
                _error = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refine and review again'),
          ),
        ),
      ],
    );
  }

  Future<void> _review() async {
    final text = _draft.text.trim();
    if (text.length < 20) {
      setState(() {
        _error = 'Add at least 20 characters so the coach has enough context.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
          await ref.read(aiCampaignRepositoryProvider).coachCreatorDraft(
                campaignId: widget.campaignId,
                draft: text,
              );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }
}

class _CoachResultSection extends StatelessWidget {
  const _CoachResultSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF315D98)),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StringListSection extends StatelessWidget {
  const _StringListSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.values,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return _CoachResultSection(
      title: title,
      icon: icon,
      child: Column(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 7, color: color),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item});

  final AiChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (item.status) {
      'met' => (
          Icons.check_circle_rounded,
          const Color(0xFF087A55),
          'Met',
        ),
      'partial' => (
          Icons.adjust_rounded,
          const Color(0xFFC25D12),
          'Partial',
        ),
      _ => (
          Icons.cancel_rounded,
          const Color(0xFFB42318),
          'Missing',
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.requirement,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (item.evidence.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.evidence,
                    style: const TextStyle(
                      color: Color(0xFF60718B),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
