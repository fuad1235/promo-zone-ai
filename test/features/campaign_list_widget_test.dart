import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promozone/common/models/app_models.dart';
import 'package:promozone/common/models/entities.dart';
import 'package:promozone/features/campaigns/presentation/campaign_providers.dart';
import 'package:promozone/features/creator/presentation/browse_campaigns_page.dart';

void main() {
  testWidgets('renders campaign cards', (tester) async {
    final sample = Campaign(
      id: 'c1',
      businessId: 'b1',
      title: 'Snack Brand Push',
      description: 'Create short video',
      productImages: const [],
      platform: 'TikTok',
      targetViews: 2500,
      payoutAmountGhs: 300,
      creatorsNeeded: 2,
      rules: const {
        'hashtags': ['#snack'],
        'mention': '@snack',
        'doDont': 'Keep it family safe',
      },
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 12),
      status: CampaignStatus.published,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publishedCampaignsProvider.overrideWith(
            (ref) => Stream.value([sample]),
          ),
        ],
        child: const MaterialApp(home: BrowseCampaignsPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Snack Brand Push'), findsAtLeastNWidgets(1));
    expect(find.text('Create short video'), findsOneWidget);
    expect(find.textContaining('GHS 300'), findsAtLeastNWidgets(1));
  });
}
