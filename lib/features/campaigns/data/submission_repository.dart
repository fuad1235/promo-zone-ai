import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/api_client.dart';

class SubmissionRepository {
  SubmissionRepository(this._firestore) : _apiClient = null;

  SubmissionRepository.api(this._apiClient) : _firestore = null;

  final FirebaseFirestore? _firestore;
  final ApiClient? _apiClient;

  CollectionReference<Map<String, dynamic>> _submissions(
    String campaignId,
    String applicationId,
  ) =>
      _firestore!
          .collection('campaigns')
          .doc(campaignId)
          .collection('applications')
          .doc(applicationId)
          .collection('submissions');

  Stream<List<Submission>> watch(String campaignId, String applicationId) {
    if (_apiClient != null) {
      return _poll(() => _fetchSubmissions(applicationId));
    }

    return _submissions(campaignId, applicationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Submission.fromJson(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> create({
    required String campaignId,
    required String applicationId,
    required SubmissionType type,
    required String message,
    required List<String> mediaUrls,
    String? postUrl,
    List<String> screenshots = const [],
    int? declaredViews,
  }) async {
    if (_apiClient != null) {
      await _apiClient
          .post('/api/applications/$applicationId/submissions', body: {
        'type': type.name,
        'message': message,
        'mediaUrls': mediaUrls,
        'postUrl': postUrl,
        'screenshots': screenshots,
        'declaredViews': declaredViews,
      });
      return;
    }

    await _submissions(campaignId, applicationId).add({
      'type': type.name,
      'message': message,
      'mediaUrls': mediaUrls,
      'postUrl': postUrl,
      'screenshots': screenshots,
      'declaredViews': declaredViews,
      'status': ReviewStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> review({
    required String campaignId,
    required String applicationId,
    required String submissionId,
    required ReviewStatus status,
    String? reviewerMessage,
  }) async {
    if (_apiClient != null) {
      await _apiClient.post('/api/submissions/$submissionId/review', body: {
        'status': status.name,
        'reviewerMessage': reviewerMessage,
      });
      return;
    }

    await _submissions(campaignId, applicationId).doc(submissionId).update({
      'status': status.name,
      'reviewerMessage': reviewerMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Submission>> _poll(
      Future<List<Submission>> Function() loader) async* {
    while (true) {
      yield await loader();
      await Future<void>.delayed(const Duration(seconds: 4));
    }
  }

  Future<List<Submission>> _fetchSubmissions(String applicationId) async {
    final payload = await _apiClient!
        .getJson('/api/applications/$applicationId/submissions');
    final list = (payload['data'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_submissionFromApi)
        .toList();
  }

  Submission _submissionFromApi(Map<String, dynamic> json) {
    final media = (json['media'] as List?) ?? const [];
    final screenshots = (json['screenshots'] as List?) ?? const [];
    return Submission.fromJson(json['id'].toString(), {
      'type': json['type'] ?? 'sample',
      'message': json['message'] ?? '',
      'mediaUrls': media,
      'postUrl': json['post_url'],
      'screenshots': screenshots,
      'declaredViews': json['declared_views'],
      'status': json['status'] ?? 'pending',
      'reviewerMessage': json['reviewer_message'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    });
  }
}
