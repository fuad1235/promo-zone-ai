import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/status_chip.dart';
import '../../campaigns/presentation/campaign_providers.dart';

class MyCampaignsPage extends ConsumerWidget {
  const MyCampaignsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(businessCampaignsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Hub')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/business/campaign/new'),
        label: const Text('Create'),
        icon: const Icon(Icons.add),
      ),
      body: AsyncValueWidget(
        value: campaigns,
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No campaigns yet',
              subtitle: 'Create your first campaign.',
              ctaLabel: 'Create campaign',
              onCta: () => context.push('/business/campaign/new'),
            );
          }

          final publishedCount =
              items.where((e) => e.status == CampaignStatus.published).length;
          final draftCount =
              items.where((e) => e.status == CampaignStatus.draft).length;
          final budget =
              items.fold<int>(0, (sum, e) => sum + e.payoutAmountGhs);
          final number = NumberFormat('#,###');

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final topCampaign = items.reduce(
                  (a, b) => a.payoutAmountGhs >= b.payoutAmountGhs ? a : b,
                );
                final urgentCampaign = items.reduce(
                  (a, b) => a.endDate.isBefore(b.endDate) ? a : b,
                );
                return Column(
                  children: [
                    _CampaignInsightsCard(
                      publishedCount: publishedCount,
                      draftCount: draftCount,
                      totalBudget: 'GHS ${number.format(budget)}',
                    ),
                    _OpsSignalCard(
                      topPayoutTitle: topCampaign.title,
                      topPayout: topCampaign.payoutAmountGhs,
                      urgentTitle: urgentCampaign.title,
                      daysLeft: urgentCampaign.endDate
                          .difference(DateTime.now())
                          .inDays
                          .clamp(0, 365),
                    ),
                  ],
                );
              }
              final campaign = items[index - 1];
              return _CampaignCard(campaign: campaign);
            },
          );
        },
      ),
    );
  }
}

class _OpsSignalCard extends StatelessWidget {
  const _OpsSignalCard({
    required this.topPayoutTitle,
    required this.topPayout,
    required this.urgentTitle,
    required this.daysLeft,
  });

  final String topPayoutTitle;
  final int topPayout;
  final String urgentTitle;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat('#,###');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _OpsSignalRow(
            icon: Icons.trending_up_rounded,
            label: 'Top payout live',
            value: 'GHS ${number.format(topPayout)}',
            subtitle: topPayoutTitle,
          ),
          const Divider(color: Color(0x1FFFFFFF), height: 14),
          _OpsSignalRow(
            icon: Icons.schedule_rounded,
            label: 'Most urgent brief',
            value: daysLeft == 0 ? 'Ends today' : '$daysLeft days left',
            subtitle: urgentTitle,
          ),
        ],
      ),
    );
  }
}

class _OpsSignalRow extends StatelessWidget {
  const _OpsSignalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0x2BFFFFFF),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB7CBEA),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF82A5D9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampaignInsightsCard extends StatelessWidget {
  const _CampaignInsightsCard({
    required this.publishedCount,
    required this.draftCount,
    required this.totalBudget,
  });

  final int publishedCount;
  final int draftCount;
  final String totalBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B273A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _BusinessMetric(label: 'Published', value: '$publishedCount'),
          _BusinessMetric(label: 'Drafts', value: '$draftCount'),
          _BusinessMetric(label: 'Planned budget', value: totalBudget),
        ],
      ),
    );
  }
}

class _BusinessMetric extends StatelessWidget {
  const _BusinessMetric({required this.label, required this.value});

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
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends ConsumerWidget {
  const _CampaignCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final number = NumberFormat('#,###');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x2206285A),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/business/campaign/${campaign.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    StatusChip(label: campaign.status.name),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  campaign.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CampaignPill(
                        text: campaign.platform,
                        icon: Icons.smart_display_rounded),
                    _CampaignPill(
                      text: '${campaign.creatorsNeeded} creators',
                      icon: Icons.groups_2_rounded,
                    ),
                    _CampaignPill(
                      text: '${number.format(campaign.targetViews)} views',
                      icon: Icons.remove_red_eye_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Payout GHS ${number.format(campaign.payoutAmountGhs)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A5BDF),
                      ),
                ),
                if (campaign.status == CampaignStatus.draft) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        try {
                          await ref
                              .read(campaignRepositoryProvider)
                              .updateCampaign(campaign.id, {
                            'status': CampaignStatus.published.name,
                          });
                          ref.invalidate(businessCampaignsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Draft published'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to publish: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('Publish'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignPill extends StatelessWidget {
  const _CampaignPill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF35507A)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF35507A),
            ),
          ),
        ],
      ),
    );
  }
}
