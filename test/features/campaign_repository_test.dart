import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promozone/common/models/app_models.dart';
import 'package:promozone/common/models/entities.dart';
import 'package:promozone/features/campaigns/data/campaign_repository.dart';

void main() {
  group('CampaignRepository', () {
    late FakeFirebaseFirestore firestore;
    late CampaignRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = CampaignRepository(firestore);
    });

    test('createCampaign persists campaign doc', () async {
      final campaign = Campaign(
        id: '',
        businessId: 'biz1',
        title: 'Launch Promo',
        description: 'New product launch',
        productImages: const [],
        platform: 'TikTok',
        targetViews: 1000,
        payoutAmountGhs: 200,
        creatorsNeeded: 1,
        rules: const {
          'hashtags': ['promo'],
          'mention': '@brand',
          'doDont': 'No profanity',
        },
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 10),
        status: CampaignStatus.published,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final id = await repository.createCampaign(campaign);
      final doc = await firestore.collection('campaigns').doc(id).get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], 'Launch Promo');
      expect(doc.data()!['status'], 'published');
    });
  });
}
