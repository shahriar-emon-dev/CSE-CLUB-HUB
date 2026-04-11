import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../constants/app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);
  ref.onDispose(routerNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerNotifier,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: routerNotifier.redirect,
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authNotifierProvider);
    final isLoading = authState.isLoading;
    final isAuthenticated = authState.isAuthenticated;
    final needsProfileSetup = authState.needsProfileSetup;
    final location = state.matchedLocation;

    final isAuthRoute =
        location == AppRoutes.login || location == AppRoutes.signup;

    if (isLoading) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    if (!isAuthenticated) {
      return isAuthRoute ? null : AppRoutes.login;
    }

    if (needsProfileSetup) {
      return location == AppRoutes.profileSetup ? null : AppRoutes.profileSetup;
    }

    if (
        location == AppRoutes.splash ||
        isAuthRoute ||
        location == AppRoutes.profileSetup) {
      return AppRoutes.home;
    }

    return null;
  }
}
