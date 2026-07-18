import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/models/entities.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/status_chip.dart';
import '../../campaigns/presentation/campaign_providers.dart';

enum _SortMode { newest, payoutHigh, deadlineSoon }

class _PayoutBand {
  const _PayoutBand(this.label, this.min, this.max);
  final String label;
  final int? min;
  final int? max;
}

class BrowseCampaignsPage extends ConsumerStatefulWidget {
  const BrowseCampaignsPage({
    super.key,
    this.title = 'Home',
    this.readOnly = false,
  });

  final String title;
  final bool readOnly;

  @override
  ConsumerState<BrowseCampaignsPage> createState() =>
      _BrowseCampaignsPageState();
}

class _BrowseCampaignsPageState extends ConsumerState<BrowseCampaignsPage> {
  _SortMode _sortMode = _SortMode.newest;

  static const _payoutBands = <_PayoutBand>[
    _PayoutBand('All payouts', null, null),
    _PayoutBand('Starter <200', null, 199),
    _PayoutBand('Growth 200-500', 200, 500),
    _PayoutBand('Premium 500+', 501, null),
  ];

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(publishedCampaignsProvider);
    final filter = ref.watch(campaignFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search brand, niche or product',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (value) {
                ref.read(campaignFilterProvider.notifier).state =
                    filter.copyWith(
                  search: value,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'TikTok', 'Instagram', 'YouTube', 'X']
                          .map((platform) {
                        final selected =
                            (platform == 'All' && filter.platform.isEmpty) ||
                                platform == filter.platform;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            label: Text(
                              platform,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF00339E)
                                    : const Color(0xFF334155),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            selected: selected,
                            selectedColor: const Color(0xFFD9E7FF),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFD1DCEE)),
                            checkmarkColor: const Color(0xFF00339E),
                            onSelected: (_) {
                              ref.read(campaignFilterProvider.notifier).state =
                                  filter.copyWith(
                                platform: platform == 'All' ? '' : platform,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<int>(
                  tooltip: 'Payout',
                  onSelected: (value) {
                    final band = _payoutBands[value];
                    ref.read(campaignFilterProvider.notifier).state =
                        filter.copyWith(
                      minPayout: band.min,
                      maxPayout: band.max,
                    );
                  },
                  itemBuilder: (_) => [
                    for (var i = 0; i < _payoutBands.length; i++)
                      PopupMenuItem<int>(
                        value: i,
                        child: Text(_payoutBands[i].label),
                      ),
                  ],
                  child: const _CompactMenuChip(
                    icon: Icons.tune_rounded,
                    label: 'Payout',
                    semanticsLabel: 'Filter by payout range',
                  ),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<_SortMode>(
                  tooltip: 'Sort',
                  onSelected: (value) => setState(() => _sortMode = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _SortMode.newest,
                      child: Text('Newest'),
                    ),
                    PopupMenuItem(
                      value: _SortMode.payoutHigh,
                      child: Text('Highest payout'),
                    ),
                    PopupMenuItem(
                      value: _SortMode.deadlineSoon,
                      child: Text('Deadline soon'),
                    ),
                  ],
                  child: const _CompactMenuChip(
                    icon: Icons.sort_rounded,
                    label: 'Sort',
                    semanticsLabel: 'Sort campaign list',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              value: campaigns,
              data: (items) {
                final filtered = _filterAndSort(items, filter);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'No campaigns found',
                    subtitle: 'Try another filter or expand your payout range.',
                  );
                }
                final avgPayout = filtered.fold<int>(
                        0, (sum, item) => sum + item.payoutAmountGhs) ~/
                    filtered.length;
                final urgent = filtered
                    .where(
                        (e) => e.endDate.difference(DateTime.now()).inDays <= 3)
                    .length;
                final topPayoutAmount = filtered
                    .map((e) => e.payoutAmountGhs)
                    .reduce((a, b) => a >= b ? a : b);
                final closestDeadline = filtered
                    .map((e) => max(0, e.endDate.difference(DateTime.now()).inDays))
                    .reduce((a, b) => a <= b ? a : b);

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(publishedCampaignsProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _MarketPulseCard(
                          activeCount: filtered.length,
                          averagePayoutText: '$avgPayout GHS',
                          urgentCount: urgent,
                          topPayoutAmount: topPayoutAmount,
                          closestDeadline: closestDeadline,
                        );
                      }
                      final campaign = filtered[index - 1];
                      return _CampaignTile(
                        campaign: campaign,
                        readOnly: widget.readOnly,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Campaign> _filterAndSort(List<Campaign> input, CampaignFilter filter) {
    final list = input.where((campaign) {
      final query = filter.search.trim().toLowerCase();
      if (query.isEmpty) return true;
      return campaign.title.toLowerCase().contains(query) ||
          campaign.description.toLowerCase().contains(query);
    }).toList();

    switch (_sortMode) {
      case _SortMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortMode.payoutHigh:
        list.sort((a, b) => b.payoutAmountGhs.compareTo(a.payoutAmountGhs));
      case _SortMode.deadlineSoon:
        list.sort((a, b) => a.endDate.compareTo(b.endDate));
    }
    return list;
  }
}

class _MarketPulseCard extends StatelessWidget {
  const _MarketPulseCard({
    required this.activeCount,
    required this.averagePayoutText,
    required this.urgentCount,
    required this.topPayoutAmount,
    required this.closestDeadline,
  });

  final int activeCount;
  final String averagePayoutText;
  final int urgentCount;
  final int topPayoutAmount;
  final int closestDeadline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF13233A),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
              children: [
                _PulseMetric(label: 'Active', value: '$activeCount'),
                _PulseMetric(label: 'Avg payout', value: averagePayoutText),
                _PulseMetric(label: 'Urgent', value: '$urgentCount'),
                _PulseMetric(label: 'Top payout', value: 'GHS $topPayoutAmount'),
                _PulseMetric(
                  label: 'Closest deadline',
                  value:
                      closestDeadline == 0 ? 'Today' : '$closestDeadline days',
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x2BFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({
    required this.campaign,
    required this.readOnly,
  });
  final Campaign campaign;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat('#,###');
    final daysLeft = max(0, campaign.endDate.difference(DateTime.now()).inDays);
    final heat =
        ((campaign.targetViews / max(campaign.creatorsNeeded, 1)) / 1000)
            .clamp(1, 99)
            .round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label:
            'Campaign ${campaign.title}. Platform ${campaign.platform}. Payout GHS ${number.format(campaign.payoutAmountGhs)} per creator. $daysLeft days left.',
        child: Card(
          shadowColor: const Color(0x220A2C66),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push('/campaign/${campaign.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PlatformBadge(platform: campaign.platform),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          campaign.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      StatusChip(label: campaign.status.name),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campaign.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                          icon: Icons.videocam_rounded,
                          text: campaign.platform),
                      _InfoPill(
                        icon: Icons.remove_red_eye_outlined,
                        text: '${number.format(campaign.targetViews)} views',
                      ),
                      _InfoPill(icon: Icons.bolt_rounded, text: 'Heat $heat'),
                      _InfoPill(
                        icon: Icons.timer_outlined,
                        text: daysLeft == 0
                            ? 'Ends today'
                            : '$daysLeft days left',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'GHS ${number.format(campaign.payoutAmountGhs)} per creator',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0048D8),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Need ${campaign.creatorsNeeded} creators • Ends ${DateFormat.yMMMd().format(campaign.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Color(0xFF5D7EB5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    final firstLetter = platform.trim().isEmpty ? 'A' : platform.trim()[0];
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFDCE8FF),
      child: Text(
        firstLetter.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF11449A),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF35507A)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF35507A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMenuChip extends StatelessWidget {
  const _CompactMenuChip({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD1DCEE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF334155)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
