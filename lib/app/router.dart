import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common/models/app_models.dart';
import '../common/models/entities.dart';
import '../common/services/repository_providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/onboarding_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/role_selection_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/business/presentation/applicant_detail_page.dart';
import '../features/business/presentation/business_campaign_detail_page.dart';
import '../features/business/presentation/business_profile_page.dart';
import '../features/business/presentation/edit_campaign_page.dart';
import '../features/business/presentation/my_campaigns_page.dart';
import '../features/creator/presentation/browse_campaigns_page.dart';
import '../features/creator/presentation/campaign_detail_page.dart';
import '../features/creator/presentation/creator_profile_page.dart';
import '../features/creator/presentation/gig_detail_page.dart';
import '../features/creator/presentation/my_gigs_page.dart';
import '../features/creator/presentation/submit_proof_page.dart';
import '../features/creator/presentation/submit_sample_page.dart';
import '../features/wallet/presentation/business_wallet_page.dart';
import '../features/wallet/presentation/creator_wallet_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profile = ref.watch(currentAppUserProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = authState.value;
      final path = state.matchedLocation;
      final isPublicMarketplacePath = path == '/';
      final isPublicCampaignDetailPath = path.startsWith('/campaign/');
      final isPublicPath = isPublicMarketplacePath || isPublicCampaignDetailPath;

      if ((authState.isLoading || (auth != null && profile.isLoading)) &&
          !isPublicPath) {
        return path == '/splash' ? null : '/splash';
      }

      final isAuthPath = [
        '/login',
        '/register',
        '/role-selection',
      ].contains(path);
      final isOnboardingPath = path.startsWith('/onboarding');

      if (auth == null) {
        return (isAuthPath || isPublicPath) ? null : '/login';
      }

      if (profile.hasError) {
        return isPublicPath ? null : '/login';
      }

      final user = profile.value;
      if (user == null) {
        return (isOnboardingPath || isPublicPath)
            ? null
            : '/role-selection';
      }

      final requiresRoleSelection = _isPendingInitialSetup(user);
      if (requiresRoleSelection) {
        if (path == '/role-selection' || isOnboardingPath) {
          return null;
        }
        return '/role-selection';
      }

      if (user.role == UserRole.business && path == '/') {
        return '/business/browse';
      }

      if (isAuthPath || isOnboardingPath || path == '/splash') {
        return user.role == UserRole.creator
            ? '/creator/campaigns'
            : '/business/browse';
      }

      if (user.role == UserRole.creator && path.startsWith('/business')) {
        return '/creator/campaigns';
      }
      if (user.role == UserRole.business && path.startsWith('/creator')) {
        return '/business/browse';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/campaign/:campaignId',
        builder: (_, state) => CreatorCampaignDetailPage(
          campaignId: state.pathParameters['campaignId']!,
        ),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (_, __) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, state) {
          final value = state.uri.queryParameters['role'] ?? 'creator';
          return OnboardingPage(role: parseRole(value));
        },
      ),
      ShellRoute(
        builder: (context, state, child) => CreatorShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const BrowseCampaignsPage(),
          ),
          GoRoute(
            path: '/creator/campaigns',
            builder: (_, __) => const BrowseCampaignsPage(),
          ),
          GoRoute(
            path: '/creator/campaign/:campaignId',
            builder: (_, state) => CreatorCampaignDetailPage(
              campaignId: state.pathParameters['campaignId']!,
            ),
          ),
          GoRoute(
            path: '/creator/gigs',
            builder: (_, __) => const MyGigsPage(),
          ),
          GoRoute(
            path: '/creator/gig/:campaignId/:applicationId',
            builder: (_, state) => GigDetailPage(
              campaignId: state.pathParameters['campaignId']!,
              applicationId: state.pathParameters['applicationId']!,
            ),
          ),
          GoRoute(
            path: '/creator/gig/:campaignId/:applicationId/sample',
            builder: (_, state) => SubmitSamplePage(
              campaignId: state.pathParameters['campaignId']!,
              applicationId: state.pathParameters['applicationId']!,
            ),
          ),
          GoRoute(
            path: '/creator/gig/:campaignId/:applicationId/proof',
            builder: (_, state) => SubmitProofPage(
              campaignId: state.pathParameters['campaignId']!,
              applicationId: state.pathParameters['applicationId']!,
            ),
          ),
          GoRoute(
            path: '/creator/wallet',
            builder: (_, __) => const CreatorWalletPage(),
          ),
          GoRoute(
            path: '/creator/profile',
            builder: (_, __) => const CreatorProfilePage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => BusinessShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/business/browse',
            builder: (_, __) => const BrowseCampaignsPage(
              title: 'Browse',
              readOnly: true,
            ),
          ),
          GoRoute(
            path: '/business/campaigns',
            builder: (_, __) => const MyCampaignsPage(),
          ),
          GoRoute(
            path: '/business/campaign/new',
            builder: (_, __) => const EditCampaignPage(),
          ),
          GoRoute(
            path: '/business/campaign/:campaignId',
            builder: (_, state) => BusinessCampaignDetailPage(
              campaignId: state.pathParameters['campaignId']!,
            ),
          ),
          GoRoute(
            path: '/business/campaign/:campaignId/applicant/:applicationId',
            builder: (_, state) => ApplicantDetailPage(
              campaignId: state.pathParameters['campaignId']!,
              applicationId: state.pathParameters['applicationId']!,
            ),
          ),
          GoRoute(
            path: '/business/wallet',
            builder: (_, __) => const BusinessWalletPage(),
          ),
          GoRoute(
            path: '/business/profile',
            builder: (_, __) => const BusinessProfilePage(),
          ),
        ],
      ),
    ],
  );
});

bool _isPendingInitialSetup(AppUser user) {
  return user.displayName.trim().toLowerCase() == 'promo zone user';
}

class CreatorShellScaffold extends StatelessWidget {
  const CreatorShellScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = location.startsWith('/creator/gigs')
        ? 1
        : location.startsWith('/creator/wallet')
            ? 2
            : location.startsWith('/creator/profile')
                ? 3
                : 0;

    final interceptToBrowse = location == '/creator/gigs' ||
        location == '/creator/wallet' ||
        location == '/creator/profile';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (interceptToBrowse) {
          context.go('/creator/campaigns');
        }
      },
      child: Scaffold(
        body: _EdgeSwipeBackLayer(
          onSwipeBack: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            if (interceptToBrowse) {
              context.go('/creator/campaigns');
            }
          },
          child: child,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A101828),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: NavigationBar(
              height: 70,
              backgroundColor: Colors.transparent,
              selectedIndex: index,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.campaign), label: 'Browse'),
                NavigationDestination(icon: Icon(Icons.work), label: 'Work'),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                NavigationDestination(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/creator/campaigns');
                  case 1:
                    context.go('/creator/gigs');
                  case 2:
                    context.go('/creator/wallet');
                  case 3:
                    context.go('/creator/profile');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BusinessShellScaffold extends StatelessWidget {
  const BusinessShellScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = location.startsWith('/business/browse')
        ? 0
        : location.startsWith('/business/wallet')
            ? 2
            : location.startsWith('/business/profile')
                ? 3
                : 1;

    final interceptToCampaigns =
        location == '/business/wallet' || location == '/business/profile';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (interceptToCampaigns) {
          context.go('/business/campaigns');
        }
      },
      child: Scaffold(
        body: _EdgeSwipeBackLayer(
          onSwipeBack: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            if (interceptToCampaigns) {
              context.go('/business/campaigns');
            }
          },
          child: child,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A101828),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: NavigationBar(
              height: 70,
              backgroundColor: Colors.transparent,
              selectedIndex: index,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.travel_explore_rounded), label: 'Browse'),
                NavigationDestination(
                  icon: Icon(Icons.work_outline_rounded),
                  label: 'Work',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                NavigationDestination(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/business/browse');
                  case 1:
                    context.go('/business/campaigns');
                  case 2:
                    context.go('/business/wallet');
                  case 3:
                    context.go('/business/profile');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeSwipeBackLayer extends StatefulWidget {
  const _EdgeSwipeBackLayer({
    required this.child,
    required this.onSwipeBack,
  });

  final Widget child;
  final VoidCallback onSwipeBack;

  @override
  State<_EdgeSwipeBackLayer> createState() => _EdgeSwipeBackLayerState();
}

class _EdgeSwipeBackLayerState extends State<_EdgeSwipeBackLayer> {
  static const double _triggerDistance = 56;
  double _dragDx = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 22,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragDx = 0,
            onHorizontalDragUpdate: (details) {
              if (details.delta.dx > 0) {
                _dragDx += details.delta.dx;
              }
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              final shouldPop = _dragDx >= _triggerDistance || velocity > 520;
              _dragDx = 0;
              if (shouldPop) {
                widget.onSwipeBack();
              }
            },
            onHorizontalDragCancel: () => _dragDx = 0,
          ),
        ),
      ],
    );
  }
}
