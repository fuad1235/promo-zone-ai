import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promozone/features/business/presentation/edit_campaign_page.dart';

void main() {
  testWidgets('campaign form exposes the GPT-5.6 architect workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: EditCampaignPage()),
      ),
    );

    expect(find.text('Campaign Architect'), findsOneWidget);
    expect(find.text('Powered by GPT-5.6'), findsOneWidget);
    expect(find.text('Build brief with GPT-5.6'), findsOneWidget);

    await tester.tap(find.text('Build brief with GPT-5.6'));
    await tester.pumpAndSettle();

    expect(find.text('Target audience'), findsOneWidget);
    expect(find.text('Campaign goal'), findsOneWidget);
    expect(find.text('Generate editable brief'), findsOneWidget);
    expect(
      find.textContaining('These business-controlled values'),
      findsOneWidget,
    );
  });
}
