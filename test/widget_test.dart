// Unit tests for pure app logic that don't require a live Supabase/Firebase
// backend to run. The previous version of this file was the unmodified
// `flutter create` counter-app template (asserting on a "0"/"1" counter that
// doesn't exist anywhere in this app), so it always failed and verified
// nothing about CSE Club Hub.
import 'package:flutter_test/flutter_test.dart';

import 'package:cseclubhub/models/user_profile.dart';
import 'package:cseclubhub/core/router/app_router.dart';

void main() {
  group('UserRole.fromString', () {
    test('maps known Super Admin aliases', () {
      expect(UserRole.fromString('Super Admin'), UserRole.superAdmin);
      expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
      expect(UserRole.fromString('Advisor/Admin'), UserRole.superAdmin);
      expect(UserRole.fromString('admin'), UserRole.superAdmin);
    });

    test('maps known Club Executive aliases', () {
      expect(UserRole.fromString('Club Executive'), UserRole.executive);
      expect(UserRole.fromString('executive'), UserRole.executive);
    });

    test('defaults unknown or blank roles to member', () {
      expect(UserRole.fromString('Regular Student'), UserRole.member);
      expect(UserRole.fromString('something-unexpected'), UserRole.member);
      expect(UserRole.fromString(''), UserRole.member);
    });
  });

  group('UserProfile role helpers', () {
    UserProfile profileWithRole(UserRole role) => UserProfile(
          id: 'u1',
          fullName: 'Test User',
          email: 'test@example.com',
          role: role,
          status: 'active',
          isApproved: true,
          joinedAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

    test('isAdmin/isExecutive/isMember reflect the role exclusively', () {
      final admin = profileWithRole(UserRole.superAdmin);
      expect(admin.isAdmin, isTrue);
      expect(admin.isExecutive, isFalse);
      expect(admin.isMember, isFalse);

      final exec = profileWithRole(UserRole.executive);
      expect(exec.isAdmin, isFalse);
      expect(exec.isExecutive, isTrue);
      expect(exec.isMember, isFalse);

      final member = profileWithRole(UserRole.member);
      expect(member.isAdmin, isFalse);
      expect(member.isExecutive, isFalse);
      expect(member.isMember, isTrue);
    });
  });

  group('AppRoutes', () {
    test('admin routes are nested under /admin for the router guard', () {
      expect(AppRoutes.adminDashboard.startsWith('/admin'), isTrue);
      expect(AppRoutes.adminMembers.startsWith('/admin'), isTrue);
      expect(AppRoutes.adminClubs.startsWith('/admin'), isTrue);
      expect(AppRoutes.adminExecutives.startsWith('/admin'), isTrue);
      expect(AppRoutes.adminEvents.startsWith('/admin'), isTrue);
      expect(AppRoutes.adminModeration.startsWith('/admin'), isTrue);
      expect(AppRoutes.adminBlogs.startsWith('/admin'), isTrue);
    });

    test('profile setup and club post detail routes are registered', () {
      expect(AppRoutes.profileSetup, '/profile-setup');
      expect(AppRoutes.clubPostDetail, '/clubs/:clubId/posts/:postId');
    });
  });
}
