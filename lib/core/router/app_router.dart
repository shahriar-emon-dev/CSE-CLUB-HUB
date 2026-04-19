import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/admin_panel_screen.dart';
import '../../features/home/presentation/screens/club_profile_screen.dart';
import '../../features/home/presentation/screens/clubs_screen.dart';
import '../../features/home/presentation/screens/events_screen.dart';
import '../../features/home/presentation/screens/executive_dashboard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/home/presentation/screens/profile_dashboard_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
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
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.clubs,
        builder: (context, state) => const ClubsScreen(),
      ),
      GoRoute(
        path: AppRoutes.clubProfile,
        builder: (context, state) => const ClubProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.events,
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileDashboard,
        builder: (context, state) => const ProfileDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.executiveDashboard,
        builder: (context, state) => const ExecutiveDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPanel,
        builder: (context, state) => const AdminPanelScreen(),
      ),
    ],
    redirect: routerNotifier.redirect,
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<AsyncValue<User?>>(
      authSessionProvider,
      (_, __) {
        notifyListeners();
      },
    );

    ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final sessionState = ref.read(authSessionProvider);
    final authState = ref.read(authNotifierProvider);
    final location = state.matchedLocation;
    final isAuthenticated = sessionState.valueOrNull != null;
    final role = authState.role;

    final isAuthRoute =
        location == AppRoutes.login || location == AppRoutes.signup;

    if (sessionState.isLoading) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    if (!isAuthenticated) {
      return isAuthRoute ? null : AppRoutes.login;
    }

    if (
        location == AppRoutes.splash ||
        isAuthRoute ||
        location == AppRoutes.profileSetup) {
      return AppRoutes.home;
    }

    if (location == AppRoutes.executiveDashboard) {
      final isExecutiveOrAdmin =
          role == AppUserRole.executive || role == AppUserRole.admin;
      if (!isExecutiveOrAdmin) return AppRoutes.home;
    }

    if (location == AppRoutes.adminPanel && role != AppUserRole.admin) {
      return AppRoutes.home;
    }

    return null;
  }
}
