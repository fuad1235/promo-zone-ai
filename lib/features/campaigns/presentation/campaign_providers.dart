import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/entities.dart';
import '../../../common/services/repository_providers.dart';

class CampaignFilter {
  const CampaignFilter({
    this.platform = '',
    this.minPayout,
    this.maxPayout,
    this.search = '',
  });

  final String platform;
  final int? minPayout;
  final int? maxPayout;
  final String search;

  static const _unset = Object();

  CampaignFilter copyWith({
    String? platform,
    Object? minPayout = _unset,
    Object? maxPayout = _unset,
    String? search,
  }) {
    return CampaignFilter(
      platform: platform ?? this.platform,
      minPayout:
          identical(minPayout, _unset) ? this.minPayout : minPayout as int?,
      maxPayout:
          identical(maxPayout, _unset) ? this.maxPayout : maxPayout as int?,
      search: search ?? this.search,
    );
  }
}

final campaignFilterProvider = StateProvider<CampaignFilter>(
  (ref) => const CampaignFilter(),
);

final publishedCampaignsProvider = StreamProvider<List<Campaign>>((ref) {
  final filter = ref.watch(campaignFilterProvider);
  return ref.watch(campaignRepositoryProvider).watchPublishedCampaigns(
        platform: filter.platform.isEmpty ? null : filter.platform,
        minPayout: filter.minPayout,
        maxPayout: filter.maxPayout,
      );
});

final businessCampaignsProvider = StreamProvider<List<Campaign>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(campaignRepositoryProvider).watchBusinessCampaigns(user.uid);
});

final campaignByIdProvider = FutureProvider.family<Campaign?, String>((
  ref,
  id,
) {
  return ref.watch(campaignRepositoryProvider).fetchById(id);
});

final businessCampaignByIdProvider = FutureProvider.family<Campaign?, String>((
  ref,
  id,
) async {
  final businessCampaigns = await ref.watch(businessCampaignsProvider.future);
  for (final campaign in businessCampaigns) {
    if (campaign.id == id) return campaign;
  }
  return ref.watch(campaignRepositoryProvider).fetchById(id);
});

final creatorApplicationsProvider = StreamProvider<List<Application>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref
      .watch(applicationRepositoryProvider)
      .watchCreatorApplications(user.uid);
});

final campaignApplicationsProvider =
    StreamProvider.family<List<Application>, String>((ref, campaignId) {
  return ref
      .watch(applicationRepositoryProvider)
      .watchCampaignApplications(campaignId);
});

final applicationSubmissionsProvider = StreamProvider.family<List<Submission>,
    ({String campaignId, String applicationId})>(
  (ref, key) {
    return ref
        .watch(submissionRepositoryProvider)
        .watch(key.campaignId, key.applicationId);
  },
);
