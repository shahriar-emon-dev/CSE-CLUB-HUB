import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/unified_post_detail_screen.dart';
import '../../features/home/screens/create_post_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/create_event_screen.dart';
import '../../features/events/screens/edit_event_screen.dart';
import '../../features/clubs/screens/clubs_discovery_screen.dart';
import '../../features/clubs/screens/club_profile_screen.dart';
import '../../features/blogs/screens/blogs_list_screen.dart';
import '../../features/blogs/screens/blog_detail_screen.dart';
import '../../features/admin/widgets/admin_shell.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_members_screen.dart';
import '../../features/admin/screens/admin_moderation_screen.dart';
import '../../features/blogs/screens/write_blog_screen.dart';
import '../../features/notices/screens/notices_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/gallery/screens/album_detail_screen.dart';
import '../../features/members/screens/members_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/forum/screens/forum_screen.dart';
import '../../features/forum/screens/thread_detail_screen.dart';
import '../../features/forum/screens/create_thread_screen.dart';
import '../../features/admin/screens/admin_blogs_screen.dart';
import '../../features/admin/screens/admin_clubs_screen.dart';
import '../../features/admin/screens/admin_executives_screen.dart';
import '../../features/admin/screens/admin_events_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/profile/screens/profile_setup_screen.dart';
import '../../features/clubs/screens/club_post_detail_screen.dart';
import '../widgets/main_shell.dart';
import '../widgets/permission_denied_screen.dart';

// Route name constants
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/verify-email';
  static const String profileSetup = '/profile-setup';

  static const String home = '/home';
  static const String clubs = '/clubs';
  static const String clubDetail = '/clubs/:id';
  static const String clubPostDetail = '/clubs/:clubId/posts/:postId';
  static const String createPost = '/post/create';
  static const String postDetail = '/post/:id';
  static const String events = '/events';
  static const String createEvent = '/events/create';
  static const String eventDetail = '/events/:id';
  static const String editEvent = '/events/:id/edit';
  static const String blogs = '/blogs';
  static const String blogDetail = '/blogs/:id';
  static const String writeBlog = '/blogs/write';
  static const String notices = '/notices';
  static const String gallery = '/gallery';
  static const String albumDetail = '/gallery/:id';
  static const String members = '/members';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String memberProfile = '/members/:id';
  static const String forum = '/forum';
  static const String threadDetail = '/forum/thread/:id';
  static const String createThread = '/forum/create';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String permissionDenied = '/permission-denied';

  static const String adminDashboard = '/admin';
  static const String adminMembers = '/admin/members';
  static const String adminClubs = '/admin/clubs';
  static const String adminExecutives = '/admin/executives';
  static const String adminEvents = '/admin/events';
  static const String adminModeration = '/admin/moderation';
  static const String adminBlogs = '/admin/blogs';
  static const String settings = '/profile/edit';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod auth/profile state changes into GoRouter's
/// [Listenable]-based refresh mechanism. This lets `redirect` re-evaluate
/// on auth/profile changes WITHOUT the [GoRouter] instance itself being
/// recreated, which would otherwise wipe the navigation stack.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(currentProfileProvider, (_, _) => notifyListeners());
  }
}

/// Router is built exactly once for the lifetime of the app. It does not
/// `ref.watch` any reactive provider directly (that would recreate the
/// GoRouter, and with it the whole navigation stack, on every emission).
/// Auth/profile changes instead flow through [_RouterRefreshNotifier] via
/// `refreshListenable`, and `redirect` reads live state with `ref.read`.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // The splash screen is a neutral zone: it always renders for its full
      // fixed duration regardless of auth state, then navigates itself to
      // login — where the existing rules below take over unchanged.
      if (state.fullPath == AppRoutes.splash) {
        return null;
      }

      final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;
      final profile = ref.read(currentProfileProvider).valueOrNull;
      final isAuthRoute = state.fullPath == AppRoutes.login ||
          state.fullPath == AppRoutes.register ||
          state.fullPath == AppRoutes.forgotPassword ||
          state.fullPath == AppRoutes.emailVerification;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      // Role-based Route Guards
      if (isLoggedIn && profile != null) {
        final fullPath = state.fullPath ?? '';

        // Admin Routes Guard
        if (fullPath.startsWith('/admin') && !profile.isAdmin) {
          return AppRoutes.permissionDenied;
        }

        // Executive Routes Guard (Admins can also access)
        final isExecutiveRoute = fullPath == AppRoutes.createPost ||
            fullPath == AppRoutes.createEvent ||
            fullPath.endsWith('/edit') ||
            fullPath == AppRoutes.writeBlog;

        if (isExecutiveRoute && !profile.isExecutive && !profile.isAdmin) {
          return AppRoutes.permissionDenied;
        }
      }

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.emailVerification, builder: (_, _) => const EmailVerificationScreen()),
      GoRoute(path: AppRoutes.profileSetup, builder: (_, _) => const ProfileSetupScreen()),
      GoRoute(path: AppRoutes.permissionDenied, builder: (_, _) => const PermissionDeniedScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: AppRoutes.clubs,
            builder: (_, _) => const ClubsDiscoveryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ClubProfileScreen(clubId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'posts/:postId',
                    builder: (_, state) => ClubPostDetailScreen(postId: state.pathParameters['postId']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: AppRoutes.createPost, builder: (_, _) => const CreatePostScreen()),
          GoRoute(
            path: AppRoutes.postDetail,
            builder: (_, state) => UnifiedPostDetailScreen(postId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.events,
            builder: (_, _) => const EventsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, _) => const CreateEventScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => EditEventScreen(eventId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.blogs,
            builder: (_, _) => const BlogsListScreen(),
            routes: [
              GoRoute(path: 'write', builder: (_, _) => const WriteBlogScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => BlogDetailScreen(blogId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: AppRoutes.notices, builder: (_, _) => const NoticesScreen()),
          GoRoute(
            path: AppRoutes.gallery,
            builder: (_, _) => const GalleryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => AlbumDetailScreen(albumId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.members,
            builder: (_, _) => const MembersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ProfileScreen(userId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
            routes: [
              GoRoute(path: 'edit', builder: (_, _) => const EditProfileScreen()),
            ],
          ),
          GoRoute(
            path: AppRoutes.forum,
            builder: (_, _) => const ForumScreen(),
            routes: [
              GoRoute(path: 'create', builder: (_, _) => const CreateThreadScreen()),
              GoRoute(
                path: 'thread/:id',
                builder: (_, state) => ThreadDetailScreen(threadId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
          GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen()),

// admin routes removed from here
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.adminDashboard, builder: (_, _) => const AdminDashboardScreen()),
          GoRoute(path: AppRoutes.adminMembers, builder: (_, _) => const AdminMembersScreen()),
          GoRoute(path: AppRoutes.adminClubs, builder: (_, _) => const AdminClubsScreen()),
          GoRoute(path: AppRoutes.adminExecutives, builder: (_, _) => const AdminExecutivesScreen()),
          GoRoute(path: AppRoutes.adminEvents, builder: (_, _) => const AdminEventsScreen()),
          GoRoute(path: AppRoutes.adminModeration, builder: (_, _) => const AdminModerationScreen()),
          GoRoute(path: AppRoutes.adminBlogs, builder: (_, _) => const AdminBlogsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
