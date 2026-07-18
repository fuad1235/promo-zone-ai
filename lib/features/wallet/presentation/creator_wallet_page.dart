import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../../common/widgets/empty_state.dart';
import 'wallet_providers.dart';

class CreatorWalletPage extends ConsumerStatefulWidget {
  const CreatorWalletPage({super.key});

  @override
  ConsumerState<CreatorWalletPage> createState() => _CreatorWalletPageState();
}

class _CreatorWalletPageState extends ConsumerState<CreatorWalletPage> {
  String? _optimisticNote;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(myWalletProvider);
    final ledger = ref.watch(myLedgerProvider);
    final format = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('Creator Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncValueWidget(
            value: wallet,
            onRetry: () => ref.invalidate(myWalletProvider),
            errorTitle: 'Unable to load wallet balance',
            data: (w) => _WalletHero(
              title: 'Available balance',
              amount: 'GHS ${format.format(w?.availableBalance ?? 0)}',
              subtitle:
                  'Held for quality checks: GHS ${format.format(w?.heldBalance ?? 0)}',
              accent: const [Color(0xFF0A5BDF), Color(0xFF2E8DFF)],
            ),
          ),
          const SizedBox(height: 10),
          const _WalletSignalTile(
            icon: Icons.verified_user_rounded,
            title: 'Payout trust layer',
            subtitle:
                'Withdrawals move through review to prevent fraud and payout disputes.',
          ),
          if (_optimisticNote != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timelapse_rounded,
                    color: Color(0xFF0A5BDF)),
                title: const Text('Request queued'),
                subtitle: Text(_optimisticNote!),
                trailing: TextButton(
                  onPressed: () => setState(() => _optimisticNote = null),
                  child: const Text('Dismiss'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _withdrawDialog(context),
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Withdraw Request'),
          ),
          const SizedBox(height: 16),
          Text('Ledger', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueWidget(
            value: ledger,
            onRetry: () => ref.invalidate(myLedgerProvider),
            errorTitle: 'Unable to load wallet ledger',
            data: (entries) {
              if (entries.isEmpty) {
                return const EmptyState(
                  title: 'No transactions',
                  subtitle: 'Your payouts and wallet history will appear here.',
                );
              }
              return Card(
                child: ListView.separated(
                  itemCount: entries.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final incoming = e.direction == LedgerDirection.inFlow;
                    final tone = incoming
                        ? const Color(0xFF0B7D47)
                        : const Color(0xFFA63F2A);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: tone.withValues(alpha: 0.14),
                        child: Icon(
                          incoming
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: tone,
                        ),
                      ),
                      title: Text(_ledgerTypeLabel(e.type)),
                      subtitle: Text(
                        '${e.status.name} • ${DateFormat.yMMMd().add_Hm().format(e.createdAt)}',
                      ),
                      trailing: Text(
                        '${incoming ? '+' : '-'} GHS ${e.amount}',
                        style:
                            TextStyle(color: tone, fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _ledgerTypeLabel(LedgerType type) {
    return switch (type) {
      LedgerType.deposit => 'Deposit',
      LedgerType.hold => 'Escrow hold',
      LedgerType.release => 'Hold release',
      LedgerType.payout => 'Creator payout',
      LedgerType.refund => 'Refund',
      LedgerType.adjustment => 'Adjustment',
    };
  }

  Future<void> _withdrawDialog(BuildContext pageContext) async {
    final amount = TextEditingController();
    final network = TextEditingController(text: 'MTN');
    final number = TextEditingController();
    bool submitting = false;

    await showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Withdraw request'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Amount (GHS)'),
                    ),
                    TextField(
                      controller: network,
                      decoration: const InputDecoration(
                        labelText: 'Network (MTN/Vodafone/AirtelTigo)',
                      ),
                    ),
                    TextField(
                      controller: number,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'MoMo number'),
                    ),
                    if (submitting) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final value = int.tryParse(amount.text.trim());
                          final uid =
                              ref.read(authRepositoryProvider).currentUser?.uid;
                          if (value == null ||
                              value <= 0 ||
                              uid == null ||
                              number.text.trim().isEmpty ||
                              network.text.trim().isEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enter amount, network and MoMo number.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          setDialogState(() => submitting = true);
                          try {
                            await ref.read(actionTelemetryProvider).run<void>(
                                  action: 'request_withdraw',
                                  meta: {
                                    'uid': uid,
                                    'amount': value,
                                    'network': network.text.trim(),
                                  },
                                  task: () {
                                    return ref
                                        .read(walletRepositoryProvider)
                                        .requestWithdraw(
                                      uid: uid,
                                      amount: value,
                                      payoutMethod: {
                                        'type': 'momo',
                                        'network': network.text.trim(),
                                        'number': number.text.trim(),
                                      },
                                    );
                                  },
                                );
                            if (!mounted || !pageContext.mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            setState(() {
                              _optimisticNote =
                                  'Withdrawal of GHS $value is in review and will appear in ledger shortly.';
                            });
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              const SnackBar(
                                  content: Text('Withdraw request submitted')),
                            );
                          } catch (e) {
                            if (!mounted || !pageContext.mounted) return;
                            if (dialogContext.mounted) {
                              setDialogState(() => submitting = false);
                            }
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        },
                  child: Text(submitting ? 'Submitting...' : 'Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String amount;
  final String subtitle;
  final List<Color> accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: accent.first,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _WalletSignalTile extends StatelessWidget {
  const _WalletSignalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1F7D4E)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
