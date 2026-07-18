import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/services/repository_providers.dart';
import '../../../common/widgets/async_value_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class CreatorProfilePage extends ConsumerWidget {
  const CreatorProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AsyncValueWidget(
        value: user,
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF0E2A54),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Text(
                        ((profile?.displayName ?? 'C').trim().isEmpty
                                ? 'C'
                                : profile!.displayName.trim()[0])
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.displayName ?? 'Creator account',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? 'No email',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Role'),
                      subtitle: Text(profile?.role.name ?? 'creator'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone'),
                      subtitle: Text(
                        profile?.phone == null || profile!.phone!.isEmpty
                            ? 'Not set'
                            : profile.phone!,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFF19804C)),
                  title: Text('Account integrity'),
                  subtitle: Text(
                    'Your creator actions are tracked through workflow milestones and review gates.',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
