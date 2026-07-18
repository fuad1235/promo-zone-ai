import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/session_storage.dart';

class CampaignRepository {
  CampaignRepository(this._firestore) : _apiClient = null;

  CampaignRepository.api(this._apiClient) : _firestore = null;

  final FirebaseFirestore? _firestore;
  final ApiClient? _apiClient;

  CollectionReference<Map<String, dynamic>> get _campaigns =>
      _firestore!.collection('campaigns');

  Stream<List<Campaign>> watchPublishedCampaigns({
    String? platform,
    int? minPayout,
    int? maxPayout,
  }) {
    if (_apiClient != null) {
      return _poll(() => _fetchPublishedCampaigns(
            platform: platform,
            minPayout: minPayout,
            maxPayout: maxPayout,
          ));
    }

    Query<Map<String, dynamic>> q = _campaigns.where(
      'status',
      isEqualTo: CampaignStatus.published.name,
    );
    if (platform != null && platform.isNotEmpty) {
      q = q.where('platform', isEqualTo: platform);
    }
    if (minPayout != null) {
      q = q.where('payoutAmountGhs', isGreaterThanOrEqualTo: minPayout);
    }
    if (maxPayout != null) {
      q = q.where('payoutAmountGhs', isLessThanOrEqualTo: maxPayout);
    }
    return q.orderBy('createdAt', descending: true).snapshots().map(
          (snap) =>
              snap.docs.map((d) => Campaign.fromJson(d.id, d.data())).toList(),
        );
  }

  Stream<List<Campaign>> watchBusinessCampaigns(String uid) {
    if (_apiClient != null) {
      return _poll(_fetchBusinessCampaigns);
    }

    return _campaigns
        .where('businessId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Campaign.fromJson(d.id, d.data())).toList(),
        );
  }

  Future<Campaign?> fetchById(String id) async {
    if (_apiClient != null) {
      final token = await SessionStorage.readToken();
      try {
        final data = await _apiClient.getJson(
          '/api/campaigns/$id',
          authenticated: token != null && token.isNotEmpty,
        );
        if (data.isEmpty) return null;
        return _campaignFromApi(data);
      } on ApiException catch (e) {
        final message = e.message.toLowerCase();
        if (message.contains('campaign not found')) {
          return null;
        }
        rethrow;
      }
    }

    final doc = await _campaigns.doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return Campaign.fromJson(doc.id, data);
  }

  Future<String> createCampaign(Campaign campaign) async {
    if (_apiClient != null) {
      final payload = await _apiClient.postJson('/api/campaigns', body: {
        'title': campaign.title,
        'description': campaign.description,
        'platform': campaign.platform,
        'targetViews': campaign.targetViews,
        'payoutAmountGhs': campaign.payoutAmountGhs,
        'creatorsNeeded': campaign.creatorsNeeded,
        'hashtags': (campaign.rules['hashtags'] ?? []) as List,
        'mention': campaign.rules['mention'],
        'doDont': campaign.rules['doDont'] ?? '',
        'productImages': campaign.productImages,
        'startDate': campaign.startDate.toIso8601String(),
        'endDate': campaign.endDate.toIso8601String(),
        'status': campaign.status.name,
      });
      return payload['id']?.toString() ?? '';
    }

    final doc = _campaigns.doc();
    await doc.set(campaign.toJson());
    return doc.id;
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> payload) async {
    if (_apiClient != null) {
      final apiPayload = <String, dynamic>{};
      if (payload['title'] != null) {
        apiPayload['title'] = payload['title'];
      }
      if (payload['description'] != null) {
        apiPayload['description'] = payload['description'];
      }
      if (payload['platform'] != null) {
        apiPayload['platform'] = payload['platform'];
      }
      if (payload['targetViews'] != null) {
        apiPayload['targetViews'] = payload['targetViews'];
      }
      if (payload['payoutAmountGhs'] != null) {
        apiPayload['payoutAmountGhs'] = payload['payoutAmountGhs'];
      }
      if (payload['creatorsNeeded'] != null) {
        apiPayload['creatorsNeeded'] = payload['creatorsNeeded'];
      }
      if (payload['rules'] is Map<String, dynamic>) {
        final rules = payload['rules'] as Map<String, dynamic>;
        apiPayload['hashtags'] = rules['hashtags'] ?? <String>[];
        apiPayload['mention'] = rules['mention'];
        apiPayload['doDont'] = rules['doDont'] ?? '';
      }
      if (payload['productImages'] != null) {
        apiPayload['productImages'] = payload['productImages'];
      }
      final start = payload['startDate'];
      if (start is DateTime) {
        apiPayload['startDate'] = start.toIso8601String();
      }
      final end = payload['endDate'];
      if (end is DateTime) {
        apiPayload['endDate'] = end.toIso8601String();
      }
      if (payload['status'] != null) {
        apiPayload['status'] = payload['status'];
      }

      await _apiClient.putJson('/api/campaigns/$id', body: apiPayload);
      return;
    }
    await _campaigns.doc(id).update(payload);
  }

  Stream<List<Campaign>> _poll(
      Future<List<Campaign>> Function() loader) async* {
    while (true) {
      yield await loader();
      await Future<void>.delayed(const Duration(seconds: 4));
    }
  }

  Future<List<Campaign>> _fetchPublishedCampaigns({
    String? platform,
    int? minPayout,
    int? maxPayout,
  }) async {
    final query = <String, String>{};
    if (platform != null && platform.isNotEmpty) query['platform'] = platform;
    if (minPayout != null) query['minPayout'] = '$minPayout';
    if (maxPayout != null) query['maxPayout'] = '$maxPayout';

    final qs = query.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = qs.isEmpty ? '/api/campaigns' : '/api/campaigns?$qs';
    final payload = await _apiClient!.getJson(path, authenticated: false);
    final list = (payload['data'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_campaignFromApi)
        .toList();
  }

  Future<List<Campaign>> _fetchBusinessCampaigns() async {
    final payload = await _apiClient!.getJson('/api/business/campaigns');
    final list = (payload['data'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_campaignFromApi)
        .toList();
  }

  Campaign _campaignFromApi(Map<String, dynamic> json) {
    return Campaign.fromJson(json['id'].toString(), {
      'businessId': json['business_id'] ?? '',
      'title': json['title'] ?? '',
      'description': json['description'] ?? '',
      'productImages': json['product_images'] ?? <String>[],
      'platform': json['platform'] ?? '',
      'targetViews': json['target_views'] ?? 0,
      'payoutAmountGhs': json['payout_amount_ghs'] ?? 0,
      'creatorsNeeded': json['creators_needed'] ?? 1,
      'rules': {
        'hashtags': json['hashtags'] ?? <String>[],
        'mention': json['mention'],
        'doDont': json['do_dont'] ?? '',
      },
      'startDate': json['start_date'],
      'endDate': json['end_date'],
      'status': json['status'] ?? 'draft',
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    });
  }
}
