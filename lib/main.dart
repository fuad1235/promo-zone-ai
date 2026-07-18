import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'unhandled_platform_error',
      name: 'promozone.runtime',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  runZonedGuarded(
    () => runApp(const ProviderScope(child: PromoZoneApp())),
    (error, stack) {
      developer.log(
        'unhandled_zone_error',
        name: 'promozone.runtime',
        error: error,
        stackTrace: stack,
      );
    },
  );
}
