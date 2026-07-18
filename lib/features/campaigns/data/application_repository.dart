import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/api_client.dart';
import '../../../common/utils/status_machine.dart';

class ApplicationRepository {
  ApplicationRepository(this._firestore) : _apiClient = null;

  ApplicationRepository.api(this._apiClient) : _firestore = null;

  final FirebaseFirestore? _firestore;
  final ApiClient? _apiClient;

  CollectionReference<Map<String, dynamic>> _apps(String campaignId) =>
      _firestore!
          .collection('campaigns')
          .doc(campaignId)
          .collection('applications');

  Stream<List<Application>> watchCreatorApplications(String creatorId) {
    if (_apiClient != null) {
      return _poll(() => _fetchApplications('/api/creator/applications'));
    }

    return _firestore!
        .collectionGroup('applications')
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Application.fromJson(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<Application>> watchCampaignApplications(String campaignId) {
    if (_apiClient != null) {
      return _poll(
          () => _fetchApplications('/api/campaigns/$campaignId/applications'));
    }

    return _apps(campaignId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Application.fromJson(d.id, d.data()))
              .toList(),
        );
  }

  Future<bool> hasApplied(String campaignId, String creatorId) async {
    if (_apiClient != null) {
      final apps = await _fetchApplications('/api/creator/applications');
      return apps
          .any((a) => a.campaignId == campaignId && a.creatorId == creatorId);
    }

    final docs = await _apps(
      campaignId,
    ).where('creatorId', isEqualTo: creatorId).limit(1).get();
    return docs.docs.isNotEmpty;
  }

  Future<String> apply({
    required String campaignId,
    required String businessId,
    required String creatorId,
    required Map<String, dynamic> creatorHandleRef,
    required Map<String, dynamic> creatorSnapshot,
  }) async {
    if (_apiClient != null) {
      final payload =
          await _apiClient.postJson('/api/campaigns/$campaignId/apply', body: {
        'creatorHandleId': creatorHandleRef['handleId'],
      });
      return payload['id']?.toString() ?? '';
    }

    if (await hasApplied(campaignId, creatorId)) {
      throw StateError('Already applied to this campaign.');
    }
    final doc = _apps(campaignId).doc();
    await doc.set({
      'campaignId': campaignId,
      'businessId': businessId,
      'creatorId': creatorId,
      'creatorHandleRef': creatorHandleRef,
      'creatorSnapshot': creatorSnapshot,
      'status': ApplicationStatus.applied.name,
      'timestamps': {'appliedAt': FieldValue.serverTimestamp()},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> transitionStatus({
    required String campaignId,
    required String applicationId,
    required ApplicationStatus from,
    required ApplicationStatus to,
    String? rejectionMessage,
  }) async {
    if (!StatusMachine.canTransition(from, to)) {
      throw StateError(
        'Invalid status transition from ${from.name} to ${to.name}',
      );
    }

    if (_apiClient != null) {
      await _apiClient
          .post('/api/applications/$applicationId/transition', body: {
        'to': applicationStatusToApi(to),
        'reviewerMessage': rejectionMessage,
      });
      return;
    }

    final tsField = switch (to) {
      ApplicationStatus.approvedByBusiness => 'approvedAt',
      ApplicationStatus.sampleSubmitted => 'sampleSubmittedAt',
      ApplicationStatus.sampleApproved => 'sampleApprovedAt',
      ApplicationStatus.posted => 'postedAt',
      ApplicationStatus.proofSubmitted => 'proofSubmittedAt',
      ApplicationStatus.proofApproved => 'proofApprovedAt',
      ApplicationStatus.paid => 'paidAt',
      _ => null,
    };

    final payload = <String, dynamic>{
      'status': to.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (tsField != null) {
      payload['timestamps.$tsField'] = FieldValue.serverTimestamp();
    }
    if (rejectionMessage != null && rejectionMessage.trim().isNotEmpty) {
      payload['timestamps.reviewerMessage'] = rejectionMessage.trim();
    }

    await _apps(campaignId).doc(applicationId).update(payload);
  }

  Stream<List<Application>> _poll(
      Future<List<Application>> Function() loader) async* {
    while (true) {
      yield await loader();
      await Future<void>.delayed(const Duration(seconds: 4));
    }
  }

  Future<List<Application>> _fetchApplications(String path) async {
    final payload = await _apiClient!.getJson(path);
    final list = (payload['data'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_applicationFromApi)
        .toList();
  }

  Application _applicationFromApi(Map<String, dynamic> json) {
    return Application.fromJson(json['id'].toString(), {
      'campaignId': json['campaign_id'] ?? '',
      'businessId': json['business_id'] ?? '',
      'creatorId': json['creator_id'] ?? '',
      'creatorHandleRef': {
        'platform': json['creator_handle_platform'] ?? '',
        'username': json['creator_handle_username'] ?? '',
        'profileUrl': json['creator_handle_profile_url'] ?? '',
        'handleId': json['creator_handle_id'],
      },
      'creatorSnapshot': {
        'displayName': json['creator_display_name'] ?? '',
        'niches': json['creator_niches'] ?? <String>[],
        'metrics': json['creator_metrics'] ?? <String, dynamic>{},
      },
      'status': json['status'] ?? 'applied',
      'timestamps': <String, dynamic>{
        'appliedAt': json['applied_at'],
        'approvedAt': json['approved_at'],
        'sampleSubmittedAt': json['sample_submitted_at'],
        'sampleApprovedAt': json['sample_approved_at'],
        'postedAt': json['posted_at'],
        'proofSubmittedAt': json['proof_submitted_at'],
        'proofApprovedAt': json['proof_approved_at'],
        'paidAt': json['paid_at'],
      },
      'holdId': json['hold_id'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    });
  }
}
