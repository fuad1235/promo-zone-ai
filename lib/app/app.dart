import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/services/repository_providers.dart';
import '../common/theme/app_theme.dart';
import 'router.dart';

class PromoZoneApp extends ConsumerWidget {
  const PromoZoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(authBootstrapProvider);
    final router = ref.watch(appRouterProvider);

    return bootstrap.when(
      data: (_) => MaterialApp.router(
        title: 'Promo Zone',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        routerConfig: router,
        builder: (context, child) {
          final network = ref.watch(networkStatusProvider);
          final online = network.value ?? true;
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F7FF),
                  ),
                  child: Stack(
                    children: const [
                      Positioned(
                        top: -80,
                        right: -70,
                        child: _AmbientOrb(
                          size: 220,
                          color: Color(0x180A66C2),
                        ),
                      ),
                      Positioned(
                        top: 240,
                        left: -90,
                        child: _AmbientOrb(
                          size: 200,
                          color: Color(0x14FF6A3D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (child != null) child,
              if (!online)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 10,
                  child: SafeArea(
                    bottom: false,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAF3B2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'You are offline. Some actions may be delayed.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(networkStatusServiceProvider)
                                    .forceCheck();
                              },
                              child: const Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      loading: () => const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (e, _) => MaterialApp(
          home: Scaffold(body: Center(child: Text('Init failed: $e')))),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
