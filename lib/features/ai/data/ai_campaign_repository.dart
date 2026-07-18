import '../../../common/services/api_client.dart';
import '../domain/ai_campaign_models.dart';

class AiCampaignRepository {
  const AiCampaignRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CampaignBriefSuggestion> generateCampaignBrief({
    required String productName,
    required String productDescription,
    required String audience,
    required String campaignGoal,
    required String platform,
    required String tone,
    required int targetViews,
    required int payoutAmountGhs,
    required int creatorsNeeded,
    required String brandMention,
  }) async {
    final envelope = await _apiClient.postJson(
      '/api/ai/campaign-brief',
      body: {
        'productName': productName,
        'productDescription': productDescription,
        'audience': audience,
        'campaignGoal': campaignGoal,
        'platform': platform,
        'tone': tone,
        'targetViews': targetViews,
        'payoutAmountGhs': payoutAmountGhs,
        'creatorsNeeded': creatorsNeeded,
        'brandMention': brandMention,
      },
    );

    return CampaignBriefSuggestion.fromEnvelope(envelope);
  }

  Future<CreatorCoachResult> coachCreatorDraft({
    required String campaignId,
    required String draft,
  }) async {
    final envelope = await _apiClient.postJson(
      '/api/ai/campaigns/$campaignId/creator-coach',
      body: {'draft': draft},
    );

    return CreatorCoachResult.fromEnvelope(envelope);
  }
}
