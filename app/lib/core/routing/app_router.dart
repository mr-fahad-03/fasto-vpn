import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_choice_screen.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/bootstrap/presentation/splash_screen.dart';
import '../../features/bootstrap/state/bootstrap_controller.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/proxies/presentation/proxy_details_route_screen.dart';
import '../../features/proxies/presentation/proxy_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/subscription/presentation/subscription_status_screen.dart';
import '../constants/app_routes.dart';
import '../models/proxy_node.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final bootstrap = ref.watch(bootstrapControllerProvider);
  final auth = ref.watch(authControllerProvider);

  String? redirectLogic(GoRouterState state) {
    final path = state.uri.path;

    if (bootstrap.isLoading || auth.isLoading) {
      return path == AppRoutes.splash ? null : AppRoutes.splash;
    }

    if (bootstrap.hasError) {
      return path == AppRoutes.splash ? null : AppRoutes.splash;
    }

    if (auth.hasError) {
      return path == AppRoutes.authChoice ? null : AppRoutes.authChoice;
    }

    final onboardingDone = bootstrap.valueOrNull?.onboardingDone ?? false;
    final authenticated = auth.valueOrNull?.session != null;

    if (!onboardingDone) {
      return path == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }

    if (!authenticated) {
      return path == AppRoutes.authChoice ? null : AppRoutes.authChoice;
    }

    if (path == AppRoutes.splash || path == AppRoutes.onboarding || path == AppRoutes.authChoice) {
      return AppRoutes.home;
    }

    return null;
  }

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (_, state) => redirectLogic(state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.authChoice,
        builder: (context, state) => const AuthChoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.proxies,
        builder: (context, state) => const ProxyListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.proxyDetails}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProxyDetailsRouteScreen(
            proxyId: id,
            initialProxy: state.extra is ProxyNode ? state.extra as ProxyNode : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const HomeScreen(initialTab: 1),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const HomeScreen(initialTab: 2),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionStatus,
        builder: (context, state) => const SubscriptionStatusScreen(),
      ),
    ],
  );
});
