import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../../common/widgets/status_chip.dart';
import '../../campaigns/presentation/campaign_providers.dart';

class ApplicantDetailPage extends ConsumerStatefulWidget {
  const ApplicantDetailPage({
    super.key,
    required this.campaignId,
    required this.applicationId,
  });

  final String campaignId;
  final String applicationId;

  @override
  ConsumerState<ApplicantDetailPage> createState() =>
      _ApplicantDetailPageState();
}

class _ApplicantDetailPageState extends ConsumerState<ApplicantDetailPage> {
  bool _actionInProgress = false;
  ApplicationStatus? _optimisticStatus;

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(campaignApplicationsProvider(widget.campaignId));
    final submissions = ref.watch(
      applicationSubmissionsProvider(
        (campaignId: widget.campaignId, applicationId: widget.applicationId),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Applicant Detail')),
      body: AsyncValueWidget(
        value: apps,
        onRetry: () =>
            ref.invalidate(campaignApplicationsProvider(widget.campaignId)),
        errorTitle: 'Unable to load applicant data',
        data: (items) {
          final app = items.where((e) => e.id == widget.applicationId).isEmpty
              ? null
              : items.firstWhere((e) => e.id == widget.applicationId);
          if (app == null) {
            return const Center(child: Text('Applicant not found'));
          }
          final effectiveStatus = _optimisticStatus ?? app.status;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ApplicantHero(app: app, statusOverride: effectiveStatus),
              if (_actionInProgress)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creator profile',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      _MetaRow(
                          label: 'Handle',
                          value: '${app.creatorHandleRef['username'] ?? '-'}'),
                      _MetaRow(
                          label: 'Platform',
                          value: '${app.creatorHandleRef['platform'] ?? '-'}'),
                      _MetaRow(
                          label: 'Profile URL',
                          value:
                              '${app.creatorHandleRef['profileUrl'] ?? '-'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submission intelligence',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      AsyncValueWidget(
                        value: submissions,
                        onRetry: () => ref.invalidate(
                          applicationSubmissionsProvider(
                            (
                              campaignId: widget.campaignId,
                              applicationId: widget.applicationId
                            ),
                          ),
                        ),
                        errorTitle: 'Unable to load submissions',
                        data: (list) {
                          if (list.isEmpty) {
                            return const Text(
                                'No samples/proofs submitted yet.');
                          }
                          return Column(
                            children: list
                                .take(4)
                                .map(
                                  (item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      item.type == SubmissionType.sample
                                          ? Icons.image_search_rounded
                                          : Icons.fact_check_rounded,
                                    ),
                                    title: Text(
                                        '${item.type.name} • ${item.status.name}'),
                                    subtitle: Text(
                                      '${DateFormat.yMMMd().add_Hm().format(item.createdAt)}'
                                      '${item.declaredViews == null ? '' : ' • ${item.declaredViews} views'}',
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (effectiveStatus == ApplicationStatus.applied)
                FilledButton.icon(
                  onPressed: _actionInProgress
                      ? null
                      : () => _runOptimistic(
                            actionName: 'approve_creator',
                            optimisticStatus:
                                ApplicationStatus.approvedByBusiness,
                            action: () async {
                              await ref
                                  .read(callableServiceProvider)
                                  .approveCreator(
                                    campaignId: widget.campaignId,
                                    applicationId: widget.applicationId,
                                  );
                            },
                            success: 'Creator approved and budget held',
                          ),
                  icon: const Icon(Icons.verified_rounded),
                  label: Text(
                      _actionInProgress ? 'Approving...' : 'Approve Creator'),
                ),
              if (effectiveStatus == ApplicationStatus.sampleSubmitted ||
                  effectiveStatus == ApplicationStatus.proofSubmitted)
                FilledButton.icon(
                  onPressed: _actionInProgress
                      ? null
                      : () => _reviewLatest(context, effectiveStatus),
                  icon: const Icon(Icons.rate_review_rounded),
                  label: Text(
                    effectiveStatus == ApplicationStatus.sampleSubmitted
                        ? (_actionInProgress ? 'Reviewing...' : 'Review Sample')
                        : (_actionInProgress ? 'Reviewing...' : 'Review Proof'),
                  ),
                ),
              if (effectiveStatus == ApplicationStatus.applied)
                OutlinedButton.icon(
                  onPressed: _actionInProgress
                      ? null
                      : () => _runOptimistic(
                            actionName: 'reject_applicant',
                            optimisticStatus: ApplicationStatus.rejected,
                            action: () async {
                              await ref
                                  .read(applicationRepositoryProvider)
                                  .transitionStatus(
                                    campaignId: widget.campaignId,
                                    applicationId: widget.applicationId,
                                    from: app.status,
                                    to: ApplicationStatus.rejected,
                                    rejectionMessage:
                                        'Not a fit for this campaign',
                                  );
                            },
                            success: 'Applicant rejected',
                          ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(
                      _actionInProgress ? 'Rejecting...' : 'Reject Applicant'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reviewLatest(
    BuildContext context,
    ApplicationStatus status,
  ) async {
    final note = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            status == ApplicationStatus.sampleSubmitted
                ? 'Review Sample'
                : 'Review Proof',
          ),
          content: TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Message (optional)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Reject'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
    if (approved == null || !mounted) return;

    if (status == ApplicationStatus.proofSubmitted && approved) {
      await _runOptimistic(
        actionName: 'approve_proof',
        optimisticStatus: ApplicationStatus.paid,
        action: () async {
          await ref.read(callableServiceProvider).approveProof(
                campaignId: widget.campaignId,
                applicationId: widget.applicationId,
              );
        },
        success: 'Proof approved and payout released',
      );
      return;
    }

    final to = switch ((status, approved)) {
      (ApplicationStatus.sampleSubmitted, true) =>
        ApplicationStatus.sampleApproved,
      (ApplicationStatus.sampleSubmitted, false) =>
        ApplicationStatus.sampleRejected,
      (ApplicationStatus.proofSubmitted, false) =>
        ApplicationStatus.proofRejected,
      _ => status,
    };

    await _runOptimistic(
      actionName: 'review_submission',
      optimisticStatus: to,
      action: () async {
        final apps = await ref
            .read(campaignApplicationsProvider(widget.campaignId).future);
        final app = apps.firstWhere((e) => e.id == widget.applicationId);
        await ref.read(applicationRepositoryProvider).transitionStatus(
              campaignId: widget.campaignId,
              applicationId: widget.applicationId,
              from: app.status,
              to: to,
              rejectionMessage: note.text.trim(),
            );
      },
      success: 'Review completed: ${to.name}',
    );
  }

  Future<void> _runOptimistic({
    required String actionName,
    required Future<void> Function() action,
    required ApplicationStatus optimisticStatus,
    required String success,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final previous = _optimisticStatus;
    setState(() {
      _actionInProgress = true;
      _optimisticStatus = optimisticStatus;
    });
    try {
      await ref.read(actionTelemetryProvider).run<void>(
            action: actionName,
            meta: {
              'campaignId': widget.campaignId,
              'applicationId': widget.applicationId,
              'toStatus': optimisticStatus.name,
            },
            task: action,
          );
      messenger?.showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      setState(() => _optimisticStatus = previous);
      messenger?.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() => _actionInProgress = false);
      }
    }
  }
}

class _ApplicantHero extends StatelessWidget {
  const _ApplicantHero({required this.app, required this.statusOverride});

  final Application app;
  final ApplicationStatus statusOverride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1B273A),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.creatorHandleRef['username']?.toString().isNotEmpty ==
                          true
                      ? app.creatorHandleRef['username'].toString()
                      : 'Applicant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pipeline stage: ${statusOverride.name}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          StatusChip(label: statusOverride.name),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

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
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5C6B87),
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
