import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_repository.dart';
import '../../features/ai/data/ai_campaign_repository.dart';
import '../../features/campaigns/data/application_repository.dart';
import '../../features/campaigns/data/campaign_repository.dart';
import '../../features/campaigns/data/submission_repository.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../models/entities.dart';
import 'action_telemetry_service.dart';
import 'api_client.dart';
import 'callable_service.dart';
import 'network_status_service.dart';
import 'storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final aiCampaignRepositoryProvider = Provider<AiCampaignRepository>((ref) {
  return AiCampaignRepository(ref.watch(apiClientProvider));
});

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository.api(ref.watch(apiClientProvider));
});

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository.api(ref.watch(apiClientProvider));
});

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository.api(ref.watch(apiClientProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository.api(ref.watch(apiClientProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(httpClientProvider));
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(httpClientProvider));
});

final callableServiceProvider = Provider<CallableService>((ref) {
  return CallableService(ref.watch(apiClientProvider));
});

final actionTelemetryProvider = Provider<ActionTelemetryService>((ref) {
  return ActionTelemetryService();
});

final networkStatusServiceProvider = Provider<NetworkStatusService>((ref) {
  final service = NetworkStatusService();
  ref.onDispose(service.dispose);
  return service;
});

final networkStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(networkStatusServiceProvider).stream;
});

final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(authRepositoryProvider).restoreSession();
});

final authStateProvider = StreamProvider<SessionUser?>((ref) {
  return ref.watch(authRepositoryProvider).authChanges();
});

final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return null;
  return ref.read(authRepositoryProvider).fetchProfile(auth.uid);
});
