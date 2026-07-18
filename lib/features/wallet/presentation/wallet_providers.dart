import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/entities.dart';
import '../../../common/services/repository_providers.dart';

final myWalletProvider = StreamProvider<Wallet?>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(walletRepositoryProvider).watchWallet(user.uid);
});

final myLedgerProvider = StreamProvider<List<LedgerEntry>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(walletRepositoryProvider).watchLedger(user.uid);
});
