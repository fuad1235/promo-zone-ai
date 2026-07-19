import 'package:flutter_test/flutter_test.dart';
import 'package:promozone/common/services/app_config.dart';

void main() {
  test('default API timeout allows production AI requests to complete', () {
    expect(AppConfig.apiTimeoutMs, 60000);
  });
}
