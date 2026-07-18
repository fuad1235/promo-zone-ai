import 'package:flutter_test/flutter_test.dart';
import 'package:promozone/common/models/app_models.dart';
import 'package:promozone/common/utils/status_machine.dart';

void main() {
  group('StatusMachine', () {
    test('allows valid transitions', () {
      expect(
        StatusMachine.canTransition(
          ApplicationStatus.applied,
          ApplicationStatus.approvedByBusiness,
        ),
        isTrue,
      );

      expect(
        StatusMachine.canTransition(
          ApplicationStatus.sampleApproved,
          ApplicationStatus.posted,
        ),
        isTrue,
      );

      expect(
        StatusMachine.canTransition(
          ApplicationStatus.proofApproved,
          ApplicationStatus.paid,
        ),
        isTrue,
      );
    });

    test('blocks invalid transitions', () {
      expect(
        StatusMachine.canTransition(
          ApplicationStatus.applied,
          ApplicationStatus.sampleApproved,
        ),
        isFalse,
      );

      expect(
        StatusMachine.canTransition(
          ApplicationStatus.paid,
          ApplicationStatus.proofRejected,
        ),
        isFalse,
      );
    });
  });
}
