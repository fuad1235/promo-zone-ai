import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../../common/widgets/empty_state.dart';
import 'wallet_providers.dart';

class BusinessWalletPage extends ConsumerStatefulWidget {
  const BusinessWalletPage({super.key});

  @override
  ConsumerState<BusinessWalletPage> createState() => _BusinessWalletPageState();
}

class _BusinessWalletPageState extends ConsumerState<BusinessWalletPage> {
  String? _optimisticNote;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(myWalletProvider);
    final ledger = ref.watch(myLedgerProvider);
    final format = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('Business Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncValueWidget(
            value: wallet,
            onRetry: () => ref.invalidate(myWalletProvider),
            errorTitle: 'Unable to load wallet balance',
            data: (w) => _BusinessWalletHero(
              available: 'GHS ${format.format(w?.availableBalance ?? 0)}',
              held: 'GHS ${format.format(w?.heldBalance ?? 0)}',
            ),
          ),
          const SizedBox(height: 10),
          const _WalletSignalTile(
            icon: Icons.shield_rounded,
            title: 'Escrow-backed execution',
            subtitle:
                'Approved creator gigs reserve campaign budget before work begins.',
          ),
          if (_optimisticNote != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timelapse_rounded,
                    color: Color(0xFF124B9D)),
                title: const Text('Deposit queued'),
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
            onPressed: () => _depositDialog(context),
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: const Text('Simulated Deposit'),
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
                  subtitle: 'Deposits, holds and payouts show here.',
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
                        : const Color(0xFF9D3B28);
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
      LedgerType.hold => 'Campaign hold',
      LedgerType.release => 'Hold release',
      LedgerType.payout => 'Creator payout',
      LedgerType.refund => 'Refund',
      LedgerType.adjustment => 'Adjustment',
    };
  }

  Future<void> _depositDialog(BuildContext pageContext) async {
    final amount = TextEditingController();
    bool submitting = false;
    await showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Deposit credits'),
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
                          if (value == null || value <= 0 || uid == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter a valid deposit amount'),
                                ),
                              );
                            }
                            return;
                          }
                          setDialogState(() => submitting = true);
                          try {
                            await ref.read(actionTelemetryProvider).run<void>(
                                  action: 'deposit_credits',
                                  meta: {
                                    'businessId': uid,
                                    'amount': value,
                                  },
                                  task: () {
                                    return ref
                                        .read(callableServiceProvider)
                                        .depositCredits(
                                          businessId: uid,
                                          amount: value,
                                        );
                                  },
                                );
                            if (!mounted || !pageContext.mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            setState(() {
                              _optimisticNote =
                                  'Deposit of GHS $value is processing and will post to ledger soon.';
                            });
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              const SnackBar(
                                  content: Text('Deposit request submitted')),
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
                  child: Text(submitting ? 'Depositing...' : 'Deposit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BusinessWalletHero extends StatelessWidget {
  const _BusinessWalletHero({
    required this.available,
    required this.held,
  });

  final String available;
  final String held;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1B273A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign liquidity',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            available,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Held in active campaigns: $held',
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
        leading: Icon(icon, color: const Color(0xFF1A7C4E)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
