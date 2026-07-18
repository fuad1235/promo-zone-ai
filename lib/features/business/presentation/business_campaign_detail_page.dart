import 'dart:math';

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

class BusinessCampaignDetailPage extends ConsumerWidget {
  const BusinessCampaignDetailPage({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(businessCampaignByIdProvider(campaignId));
    final applications = ref.watch(campaignApplicationsProvider(campaignId));
    final campaignData = campaign.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Campaign Performance')),
      floatingActionButton: campaignData != null &&
              campaignData.status == CampaignStatus.draft
          ? FloatingActionButton.extended(
              onPressed: () => _publishDraft(context, ref, campaignData.id),
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Publish'),
            )
          : null,
      body: AsyncValueWidget(
        value: campaign,
        data: (c) {
          if (c == null) {
            return const Center(child: Text('Campaign not found'));
          }
          return AsyncValueWidget(
            value: applications,
            data: (items) {
              final approved = items
                  .where(
                      (e) => e.status == ApplicationStatus.approvedByBusiness)
                  .length;
              final posted = items
                  .where((e) => e.status == ApplicationStatus.posted)
                  .length;
              final paid =
                  items.where((e) => e.status == ApplicationStatus.paid).length;
              final reviewQueue = items
                  .where((e) =>
                      e.status == ApplicationStatus.sampleSubmitted ||
                      e.status == ApplicationStatus.proofSubmitted)
                  .length;
              final conversionRate =
                  items.isEmpty ? 0 : ((approved / items.length) * 100).round();
              final committed = approved * c.payoutAmountGhs;
              final payoutExposure = c.creatorsNeeded * c.payoutAmountGhs;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: items.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CampaignAnalyticsHero(
                      campaign: c,
                      totalApplicants: items.length,
                      approved: approved,
                      reviewQueue: reviewQueue,
                      conversionRate: conversionRate,
                      committedText:
                          'GHS ${NumberFormat('#,###').format(committed)}',
                      exposureText:
                          'GHS ${NumberFormat('#,###').format(payoutExposure)}',
                    );
                  }
                  if (index == 1) {
                    return _FunnelCard(
                      applicants: items.length,
                      approved: approved,
                      posted: posted,
                      paid: paid,
                    );
                  }
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: EmptyState(
                        title: 'No applicants yet',
                        subtitle:
                            'Share campaign link to attract targeted creators.',
                      ),
                    );
                  }

                  final app = items[index - 2];
                  return _ApplicantCard(
                    campaignId: campaignId,
                    app: app,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _publishDraft(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(campaignRepositoryProvider).updateCampaign(id, {
        'status': CampaignStatus.published.name,
      });
      ref.invalidate(businessCampaignsProvider);
      ref.invalidate(businessCampaignByIdProvider(campaignId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign published')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e')),
        );
      }
    }
  }
}

class _CampaignAnalyticsHero extends StatelessWidget {
  const _CampaignAnalyticsHero({
    required this.campaign,
    required this.totalApplicants,
    required this.approved,
    required this.reviewQueue,
    required this.conversionRate,
    required this.committedText,
    required this.exposureText,
  });

  final Campaign campaign;
  final int totalApplicants;
  final int approved;
  final int reviewQueue;
  final int conversionRate;
  final String committedText;
  final String exposureText;

  @override
  Widget build(BuildContext context) {
    final daysLeft = max(0, campaign.endDate.difference(DateTime.now()).inDays);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1B273A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              StatusChip(label: campaign.status.name),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${campaign.platform} • ${daysLeft == 0 ? 'Ends today' : '$daysLeft days left'}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroMetric(label: 'Applicants', value: '$totalApplicants'),
              _HeroMetric(label: 'Approved', value: '$approved'),
              _HeroMetric(label: 'In review', value: '$reviewQueue'),
              _HeroMetric(label: 'Conv rate', value: '$conversionRate%'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Committed budget: $committedText • Max exposure: $exposureText',
            style: const TextStyle(color: Colors.white70),
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
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

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({
    required this.applicants,
    required this.approved,
    required this.posted,
    required this.paid,
  });

  final int applicants;
  final int approved;
  final int posted;
  final int paid;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversion funnel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _FunnelRow(label: 'Applied', value: applicants),
            _FunnelRow(label: 'Approved', value: approved),
            _FunnelRow(label: 'Posted', value: posted),
            _FunnelRow(label: 'Paid', value: paid),
          ],
        ),
      ),
    );
  }
}

class _FunnelRow extends StatelessWidget {
  const _FunnelRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEFB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF204172),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.campaignId, required this.app});

  final String campaignId;
  final Application app;

  @override
  Widget build(BuildContext context) {
    final score = _velocityScore(app.status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          title: Text(
            app.creatorHandleRef['username']?.toString().isNotEmpty == true
                ? app.creatorHandleRef['username'].toString()
                : 'Creator',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${app.status.name}'),
              const SizedBox(height: 4),
              Text(
                'Progress score: $score • Applied ${_appliedAt(app)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(
            '/business/campaign/$campaignId/applicant/${app.id}',
          ),
        ),
      ),
    );
  }

  int _velocityScore(ApplicationStatus status) {
    return switch (status) {
      ApplicationStatus.applied => 20,
      ApplicationStatus.approvedByBusiness => 35,
      ApplicationStatus.sampleSubmitted => 50,
      ApplicationStatus.sampleApproved => 65,
      ApplicationStatus.posted => 78,
      ApplicationStatus.proofSubmitted => 88,
      ApplicationStatus.proofApproved || ApplicationStatus.paid => 100,
      ApplicationStatus.rejected => 0,
      ApplicationStatus.sampleRejected || ApplicationStatus.proofRejected => 40,
    };
  }

  String _appliedAt(Application app) {
    final raw = app.timestamps['appliedAt'];
    final parsed = parseDate(raw);
    return DateFormat.yMMMd().format(parsed);
  }
}
