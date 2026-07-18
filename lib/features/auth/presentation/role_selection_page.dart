import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/models/app_models.dart';
import 'auth_controller.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  UserRole? _pendingRole;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go('/login');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Choose Your Role')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF0E2A54),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your operating mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pick one now and start using the app immediately. You can complete profile details later.',
                    style: TextStyle(color: Color(0xFFC4DDFF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              title: 'Creator',
              subtitle:
                  'Start browsing gigs now. Finish creator profile later.',
              icon: Icons.video_camera_front_rounded,
              onTap:
                  state.isLoading ? null : () => _chooseRole(UserRole.creator),
              loading: state.isLoading && _pendingRole == UserRole.creator,
            ),
            const SizedBox(height: 10),
            _RoleCard(
              title: 'Business',
              subtitle:
                  'Start posting campaigns now. Finish company profile later.',
              icon: Icons.storefront_rounded,
              onTap:
                  state.isLoading ? null : () => _chooseRole(UserRole.business),
              loading: state.isLoading && _pendingRole == UserRole.business,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseRole(UserRole role) async {
    if (mounted) {
      setState(() => _pendingRole = role);
    }
    await ref.read(authControllerProvider.notifier).chooseRole(role);
    final nextState = ref.read(authControllerProvider);
    if (!mounted) return;
    if (nextState.hasError) {
      setState(() => _pendingRole = null);
      return;
    }

    if (role == UserRole.business) {
      context.go('/business/campaigns');
    } else {
      context.go('/creator/campaigns');
    }
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.loading,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title role. $subtitle',
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFE7F0FF),
                  child: Icon(icon, color: const Color(0xFF124B9D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
