class AiGenerationMeta {
  const AiGenerationMeta({
    required this.provider,
    required this.requestedModel,
    required this.model,
    required this.feature,
    this.responseId,
    this.generatedAt,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
  });

  final String provider;
  final String requestedModel;
  final String model;
  final String feature;
  final String? responseId;
  final DateTime? generatedAt;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  factory AiGenerationMeta.fromJson(Map<String, dynamic> json) {
    final usage = _asMap(json['usage']);
    return AiGenerationMeta(
      provider: json['provider']?.toString() ?? 'OpenAI',
      requestedModel: json['requested_model']?.toString() ?? 'gpt-5.6',
      model: json['model']?.toString() ?? 'gpt-5.6',
      feature: json['feature']?.toString() ?? '',
      responseId: json['response_id']?.toString(),
      generatedAt: DateTime.tryParse(
        json['generated_at']?.toString() ?? '',
      ),
      inputTokens: _asInt(usage['input_tokens']),
      outputTokens: _asInt(usage['output_tokens']),
      totalTokens: _asInt(usage['total_tokens']),
    );
  }

  String get displayModel {
    final normalized = model.toLowerCase();
    if (normalized.startsWith('gpt-5.6')) return 'GPT-5.6';
    return model;
  }
}

class AiContentAngle {
  const AiContentAngle({
    required this.hook,
    required this.concept,
  });

  final String hook;
  final String concept;

  factory AiContentAngle.fromJson(Map<String, dynamic> json) {
    return AiContentAngle(
      hook: json['hook']?.toString() ?? '',
      concept: json['concept']?.toString() ?? '',
    );
  }
}

class CampaignBriefSuggestion {
  const CampaignBriefSuggestion({
    required this.title,
    required this.description,
    required this.platform,
    required this.targetViews,
    required this.payoutAmountGhs,
    required this.creatorsNeeded,
    required this.mention,
    required this.hashtags,
    required this.doDont,
    required this.creatorProfile,
    required this.successMetric,
    required this.contentAngles,
    required this.meta,
  });

  final String title;
  final String description;
  final String platform;
  final int targetViews;
  final int payoutAmountGhs;
  final int creatorsNeeded;
  final String mention;
  final List<String> hashtags;
  final String doDont;
  final String creatorProfile;
  final String successMetric;
  final List<AiContentAngle> contentAngles;
  final AiGenerationMeta meta;

  factory CampaignBriefSuggestion.fromEnvelope(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return CampaignBriefSuggestion(
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      platform: data['platform']?.toString() ?? '',
      targetViews: _asInt(data['target_views']),
      payoutAmountGhs: _asInt(data['payout_amount_ghs']),
      creatorsNeeded: _asInt(data['creators_needed']),
      mention: data['mention']?.toString() ?? '',
      hashtags: _asStringList(data['hashtags']),
      doDont: data['do_dont']?.toString() ?? '',
      creatorProfile: data['creator_profile']?.toString() ?? '',
      successMetric: data['success_metric']?.toString() ?? '',
      contentAngles: _asMapList(data['content_angles'])
          .map(AiContentAngle.fromJson)
          .toList(growable: false),
      meta: AiGenerationMeta.fromJson(_asMap(json['meta'])),
    );
  }
}

class AiChecklistItem {
  const AiChecklistItem({
    required this.requirement,
    required this.status,
    required this.evidence,
  });

  final String requirement;
  final String status;
  final String evidence;

  factory AiChecklistItem.fromJson(Map<String, dynamic> json) {
    return AiChecklistItem(
      requirement: json['requirement']?.toString() ?? '',
      status: json['status']?.toString() ?? 'missing',
      evidence: json['evidence']?.toString() ?? '',
    );
  }
}

class CreatorCoachResult {
  const CreatorCoachResult({
    required this.score,
    required this.verdict,
    required this.summary,
    required this.strengths,
    required this.missingRequirements,
    required this.riskFlags,
    required this.recommendedHook,
    required this.revisedDraft,
    required this.shotList,
    required this.checklist,
    required this.meta,
  });

  final int score;
  final String verdict;
  final String summary;
  final List<String> strengths;
  final List<String> missingRequirements;
  final List<String> riskFlags;
  final String recommendedHook;
  final String revisedDraft;
  final List<String> shotList;
  final List<AiChecklistItem> checklist;
  final AiGenerationMeta meta;

  factory CreatorCoachResult.fromEnvelope(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return CreatorCoachResult(
      score: _asInt(data['score']).clamp(0, 100),
      verdict: data['verdict']?.toString() ?? 'revise',
      summary: data['summary']?.toString() ?? '',
      strengths: _asStringList(data['strengths']),
      missingRequirements: _asStringList(data['missing_requirements']),
      riskFlags: _asStringList(data['risk_flags']),
      recommendedHook: data['recommended_hook']?.toString() ?? '',
      revisedDraft: data['revised_draft']?.toString() ?? '',
      shotList: _asStringList(data['shot_list']),
      checklist: _asMapList(data['checklist'])
          .map(AiChecklistItem.fromJson)
          .toList(growable: false),
      meta: AiGenerationMeta.fromJson(_asMap(json['meta'])),
    );
  }

  String get verdictLabel {
    return switch (verdict) {
      'ready' => 'Ready for human review',
      'off_brief' => 'Off brief',
      _ => 'Revise first',
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_asMap).toList(growable: false);
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
