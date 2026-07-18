import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../../common/widgets/status_chip.dart';
import '../../campaigns/presentation/campaign_providers.dart';

class GigDetailPage extends ConsumerWidget {
  const GigDetailPage({
    super.key,
    required this.campaignId,
    required this.applicationId,
  });

  final String campaignId;
  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(campaignApplicationsProvider(campaignId));

    return Scaffold(
      appBar: AppBar(title: const Text('Gig Execution')),
      body: AsyncValueWidget(
        value: apps,
        data: (items) {
          final app = items.where((e) => e.id == applicationId).isEmpty
              ? null
              : items.firstWhere((e) => e.id == applicationId);
          if (app == null) {
            return const Center(child: Text('Application not found'));
          }
          final steps = _timelineSteps(app.status);
          final stepIndex = _timelineIndex(app.status);
          final progress = ((stepIndex + 1) / 7).clamp(0, 1).toDouble();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  StatusChip(label: app.status.name),
                  const SizedBox(width: 8),
                  Text(
                    'Safety checks active',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF128A52),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _GigStatusCard(status: app.status),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Execution progress',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: const Color(0xFFE3EAF6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(progress * 100).round()}% complete',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workflow timeline',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      ...steps,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Trust & payout protection',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8),
                      Text(
                          'Approved creators are protected by hold-based budget reservation.'),
                      SizedBox(height: 4),
                      Text(
                          'Payout releases only after proof review and target checks.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (app.status == ApplicationStatus.approvedByBusiness ||
                  app.status == ApplicationStatus.sampleRejected)
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/creator/gig/$campaignId/$applicationId/sample',
                  ),
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Submit Sample'),
                ),
              if (app.status == ApplicationStatus.sampleApproved)
                FilledButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref
                        .read(applicationRepositoryProvider)
                        .transitionStatus(
                          campaignId: campaignId,
                          applicationId: applicationId,
                          from: app.status,
                          to: ApplicationStatus.posted,
                        );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Marked as posted')),
                    );
                  },
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Mark Posted'),
                ),
              if (app.status == ApplicationStatus.posted ||
                  app.status == ApplicationStatus.proofRejected)
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/creator/gig/$campaignId/$applicationId/proof',
                  ),
                  icon: const Icon(Icons.fact_check_rounded),
                  label: const Text('Submit Proof'),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _timelineSteps(ApplicationStatus status) {
    final current = _timelineIndex(status);
    const labels = [
      'Applied',
      'Approved',
      'Sample Submitted',
      'Sample Approved',
      'Posted',
      'Proof Submitted',
      'Paid',
    ];
    return List.generate(labels.length, (index) {
      final done = index < current;
      final active = index == current;
      return _TimelineTile(
        label: labels[index],
        done: done,
        active: active,
      );
    });
  }

  int _timelineIndex(ApplicationStatus status) {
    return switch (status) {
      ApplicationStatus.applied => 0,
      ApplicationStatus.approvedByBusiness => 1,
      ApplicationStatus.sampleSubmitted => 2,
      ApplicationStatus.sampleApproved => 3,
      ApplicationStatus.posted => 4,
      ApplicationStatus.proofSubmitted => 5,
      ApplicationStatus.proofApproved || ApplicationStatus.paid => 6,
      ApplicationStatus.rejected => 1,
      ApplicationStatus.sampleRejected => 2,
      ApplicationStatus.proofRejected => 5,
    };
  }
}

class _GigStatusCard extends StatelessWidget {
  const _GigStatusCard({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0E2A54),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage(status),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusMessage(ApplicationStatus status) {
    return switch (status) {
      ApplicationStatus.approvedByBusiness =>
        'You are approved. Submit sample content next.',
      ApplicationStatus.sampleSubmitted =>
        'Sample submitted. Business review in progress.',
      ApplicationStatus.sampleApproved =>
        'Sample approved. Publish and mark posted.',
      ApplicationStatus.posted =>
        'Post is live. Upload proof to secure payout.',
      ApplicationStatus.proofSubmitted =>
        'Proof submitted. Final review in progress.',
      ApplicationStatus.paid => 'Gig completed and payout posted.',
      ApplicationStatus.sampleRejected ||
      ApplicationStatus.proofRejected =>
        'Changes requested. Re-submit to continue.',
      ApplicationStatus.rejected => 'Application was rejected by business.',
      _ => 'Application created. Waiting for business decision.',
    };
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        done || active ? const Color(0xFF0A5BDF) : const Color(0xFFB1C1DD);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done
            ? Icons.check_circle
            : active
                ? Icons.timelapse_rounded
                : Icons.circle_outlined,
        color: color,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? const Color(0xFF1E3156) : null,
        ),
      ),
      subtitle: active ? const Text('Current step') : null,
    );
  }
}
