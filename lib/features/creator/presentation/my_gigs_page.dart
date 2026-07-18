import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/status_chip.dart';
import '../../campaigns/presentation/campaign_providers.dart';

class MyGigsPage extends ConsumerWidget {
  const MyGigsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(creatorApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Gigs')),
      body: AsyncValueWidget(
        value: applications,
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No gigs yet',
              subtitle: 'Apply to a campaign to see it here.',
            );
          }
          final inReview = items
              .where((item) =>
                  item.status == ApplicationStatus.proofSubmitted ||
                  item.status == ApplicationStatus.sampleSubmitted)
              .length;
          final live = items
              .where((item) =>
                  item.status == ApplicationStatus.sampleApproved ||
                  item.status == ApplicationStatus.posted)
              .length;
          final paid = items
              .where((item) => item.status == ApplicationStatus.paid)
              .length;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _GigPulseCard(
                  active: items.length,
                  inReview: inReview,
                  live: live,
                  paid: paid,
                );
              }
              final app = items[index - 1];
              return _GigCard(app: app);
            },
          );
        },
      ),
    );
  }
}

class _GigPulseCard extends StatelessWidget {
  const _GigPulseCard({
    required this.active,
    required this.inReview,
    required this.live,
    required this.paid,
  });

  final int active;
  final int inReview;
  final int live;
  final int paid;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1B273A),
      ),
      child: Row(
        children: [
          _PulseMetric(label: 'Active', value: '$active'),
          _PulseMetric(label: 'In review', value: '$inReview'),
          _PulseMetric(label: 'Live now', value: '$live'),
          _PulseMetric(label: 'Paid', value: '$paid'),
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({required this.label, required this.value});

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
              fontSize: 16,
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

class _GigCard extends StatelessWidget {
  const _GigCard({required this.app});

  final Application app;

  @override
  Widget build(BuildContext context) {
    final step = _stepIndex(app.status);
    final progress = step / 6;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/creator/gig/${app.campaignId}/${app.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Campaign ${app.campaignId.substring(0, 6)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  StatusChip(label: app.status.name),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Next action: ${_nextAction(app.status)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: const Color(0xFF0A5BDF),
                  backgroundColor: const Color(0xFFDCE6F8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Progress: ${step.clamp(0, 6)}/6 milestones',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF567097),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _stepIndex(ApplicationStatus status) {
    return switch (status) {
      ApplicationStatus.applied => 0,
      ApplicationStatus.approvedByBusiness => 1,
      ApplicationStatus.sampleSubmitted => 2,
      ApplicationStatus.sampleApproved => 3,
      ApplicationStatus.posted => 4,
      ApplicationStatus.proofSubmitted => 5,
      ApplicationStatus.proofApproved || ApplicationStatus.paid => 6,
      ApplicationStatus.rejected ||
      ApplicationStatus.sampleRejected ||
      ApplicationStatus.proofRejected =>
        1,
    };
  }

  String _nextAction(ApplicationStatus status) {
    return switch (status) {
      ApplicationStatus.approvedByBusiness ||
      ApplicationStatus.sampleRejected =>
        'Submit sample',
      ApplicationStatus.sampleApproved => 'Mark as posted',
      ApplicationStatus.posted ||
      ApplicationStatus.proofRejected =>
        'Submit proof',
      ApplicationStatus.proofSubmitted => 'Waiting for business review',
      ApplicationStatus.paid ||
      ApplicationStatus.proofApproved =>
        'Payout processing',
      ApplicationStatus.rejected => 'Campaign closed for this application',
      _ => 'Track updates',
    };
  }
}
