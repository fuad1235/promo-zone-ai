import 'api_client.dart';

class CallableService {
  const CallableService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> depositCredits({
    required String businessId,
    required int amount,
  }) async {
    await _apiClient.post('/api/wallet/deposit', body: {'amount': amount});
  }

  Future<void> approveCreator({
    required String campaignId,
    required String applicationId,
  }) async {
    await _apiClient.post(
      '/api/campaigns/$campaignId/applications/$applicationId/approve',
    );
  }

  Future<void> approveProof({
    required String campaignId,
    required String applicationId,
  }) async {
    await _apiClient.post(
      '/api/campaigns/$campaignId/applications/$applicationId/approve-proof',
    );
  }

  Future<void> refundHold({required String holdId}) async {
    await _apiClient.post('/api/holds/refund', body: {'holdId': holdId});
  }
}
