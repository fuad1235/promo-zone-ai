import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/models/entities.dart';
import '../../../common/services/api_client.dart';

class WalletRepository {
  WalletRepository(this._firestore) : _apiClient = null;

  WalletRepository.api(this._apiClient) : _firestore = null;

  final FirebaseFirestore? _firestore;
  final ApiClient? _apiClient;

  Stream<Wallet?> watchWallet(String uid) {
    if (_apiClient != null) {
      return _pollWallet();
    }

    return _firestore!.collection('wallets').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return Wallet.fromJson(data);
    });
  }

  Stream<List<LedgerEntry>> watchLedger(String uid) {
    if (_apiClient != null) {
      return _pollLedger();
    }

    return _firestore!
        .collection('wallets')
        .doc(uid)
        .collection('ledger')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => LedgerEntry.fromJson(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> requestWithdraw({
    required String uid,
    required int amount,
    required Map<String, dynamic> payoutMethod,
  }) async {
    if (_apiClient != null) {
      await _apiClient.post('/api/wallet/withdraw-request', body: {
        'amount': amount,
        'network': payoutMethod['network'] ?? 'MTN',
        'number': payoutMethod['number'] ?? '',
      });
      return;
    }

    await _firestore!.collection('withdrawRequests').add({
      'uid': uid,
      'amount': amount,
      'payoutMethod': payoutMethod,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Wallet?> _pollWallet() async* {
    while (true) {
      final payload = await _apiClient!.getJson('/api/wallet');
      final walletJson = payload['wallet'] as Map<String, dynamic>?;
      if (walletJson == null) {
        yield null;
      } else {
        yield Wallet.fromJson({
          'uid': walletJson['user_id'] ?? '',
          'role': walletJson['role'] ?? 'creator',
          'availableBalance': walletJson['available_balance'] ?? 0,
          'heldBalance': walletJson['held_balance'] ?? 0,
          'updatedAt': walletJson['updated_at'],
        });
      }
      await Future<void>.delayed(const Duration(seconds: 4));
    }
  }

  Stream<List<LedgerEntry>> _pollLedger() async* {
    while (true) {
      final payload = await _apiClient!.getJson('/api/wallet');
      final list = (payload['ledger'] as List?) ?? const [];
      yield list.whereType<Map<String, dynamic>>().map((entry) {
        return LedgerEntry.fromJson(entry['id'].toString(), {
          'type': entry['type'] ?? 'adjustment',
          'amount': entry['amount'] ?? 0,
          'direction': entry['direction'] ?? 'in',
          'status': entry['status'] ?? 'pending',
          'reference': {
            'campaignId': entry['campaign_id'],
            'applicationId': entry['application_id'],
            'holdId': entry['hold_id'],
          },
          'createdAt': entry['created_at'],
        });
      }).toList();
      await Future<void>.delayed(const Duration(seconds: 4));
    }
  }
}
