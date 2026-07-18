import 'package:flutter_test/flutter_test.dart';
import 'package:promozone/features/ai/domain/ai_campaign_models.dart';

void main() {
  test('campaign brief parses structured GPT-5.6 envelope', () {
    final suggestion = CampaignBriefSuggestion.fromEnvelope({
      'data': {
        'title': 'Mango Rush Launch',
        'description': 'An authentic first-sip creator campaign.',
        'platform': 'TikTok',
        'target_views': 12000,
        'payout_amount_ghs': 350,
        'creators_needed': 3,
        'mention': '@sparkbrewgh',
        'hashtags': ['#MangoRush', '#SparkBrew'],
        'do_dont': 'Show the can. Do not make health claims.',
        'creator_profile': 'Lifestyle creators in Accra',
        'success_metric': 'Clear product recall',
        'content_angles': [
          {
            'hook': 'My honest 3pm reset',
            'concept': 'A day-in-the-life product moment',
          },
        ],
      },
      'meta': {
        'provider': 'OpenAI',
        'requested_model': 'gpt-5.6',
        'model': 'gpt-5.6-sol',
        'feature': 'campaign_architect',
        'usage': {
          'input_tokens': 100,
          'output_tokens': 200,
          'total_tokens': 300,
        },
      },
    });

    expect(suggestion.title, 'Mango Rush Launch');
    expect(suggestion.targetViews, 12000);
    expect(suggestion.hashtags, ['#MangoRush', '#SparkBrew']);
    expect(suggestion.contentAngles.single.hook, 'My honest 3pm reset');
    expect(suggestion.meta.displayModel, 'GPT-5.6');
    expect(suggestion.meta.totalTokens, 300);
  });

  test('creator coach parses checklist and clamps score', () {
    final result = CreatorCoachResult.fromEnvelope({
      'data': {
        'score': 120,
        'verdict': 'revise',
        'summary': 'Add the brand mention.',
        'strengths': ['Strong hook'],
        'missing_requirements': ['Brand mention'],
        'risk_flags': [],
        'recommended_hook': 'My honest first sip',
        'revised_draft': 'My honest first sip with @sparkbrewgh.',
        'shot_list': ['Show the can'],
        'checklist': [
          {
            'requirement': 'Brand mention',
            'status': 'missing',
            'evidence': 'No mention was found.',
          },
        ],
      },
      'meta': {
        'provider': 'OpenAI',
        'requested_model': 'gpt-5.6',
        'model': 'gpt-5.6-sol',
        'feature': 'creator_coach',
      },
    });

    expect(result.score, 100);
    expect(result.verdictLabel, 'Revise first');
    expect(result.checklist.single.status, 'missing');
    expect(result.riskFlags, isEmpty);
  });
}
