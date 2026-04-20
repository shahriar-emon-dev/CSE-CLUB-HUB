# CSE Club Hub - Developer Quick Reference

**Last Updated:** April 20, 2026

---

## 🚀 Quick Start

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Set environment variables
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"

# 3. Run the app
flutter run -d web  # or -d chrome, -d android, etc.
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, Supabase init |
| `lib/app.dart` | App configuration, routing |
| `lib/core/router/app_router.dart` | Go Router configuration |
| `lib/core/constants/app_colors.dart` | Theme colors |
| `lib/features/auth/` | Authentication system |
| `lib/features/feed/` | Feed logic and repositories |
| `lib/features/home/` | Home screens and widgets |
| `lib/shared/widgets/` | Reusable components |

---

## 🔐 Authentication

### User Roles

```dart
enum AppUserRole { student, executive, admin }
```

**Path:** `student → executive (via request) → admin (via admin panel)`

### Login Flow

```dart
// In auth_repository_impl.dart
Future<AuthSuccess> login(String email, String password) async {
  final response = await _authService.login(email, password);
  // Returns user + profile with role
}
```

### Executive Request

```dart
// Student initiates request
await _authService.requestExecutiveAccess();
// Updates profile.role_request = true

// Admin approves in admin panel
// UPDATE profiles SET role = 'executive', role_request = false 
// WHERE user_id = <student_id>
```

### Withdrawal

```dart
// Student withdraws request
await _authService.withdrawExecutiveRequest();
// Calls RPC function that sets role_request = false
```

---

## 📰 Feed System

### Architecture

```
FeedRepository
├── getHomeFeed(mode)  // Calls RPC get_home_feed_v2
├── setFeedPreference(mode)  // Updates profiles.feed_preference
├── getEffectiveFeedMode()  // Determines Global vs Personalized
└── getFollowedClubCount()  // Counts user's club follows
```

### Modes

**Global Mode:** All posts from all clubs  
**Personalized Mode:** Only posts from clubs you follow (requires >= 1 follow)

### Mode Switching

```dart
// In live_home_feed_section.dart
// User clicks Global/Personalized tab
// State updates → feed_repository.getHomeFeed(newMode)
// UI displays filtered posts

// After following 1st club:
// feed_preference auto-switches to 'personalized'
```

### RPC Functions

```sql
-- Get mode-aware feed
get_home_feed_v2(p_limit INT, p_offset INT, p_mode VARCHAR)
RETURNS TABLE (posts with author, club, reactions)

-- Get effective mode based on follows
get_effective_feed_mode()
RETURNS VARCHAR ('global' or 'personalized')
```

---

## 📤 Post Creation

### Restrictions

- ✅ **Executives** can create posts
- ✅ **Admins** can create posts
- ❌ **Students** cannot create posts (RLS policy blocks)

### Flow

```dart
// In post creation form (executive-only UI)
final post = await FeedRepository.createPost(
  content: 'Post text',
  image: imageFile,  // Optional
);
// RLS policy verifies: author_id = auth.uid() AND is_executive_or_admin()
```

### Error Handling

```dart
try {
  await feedRepository.createPost(...);
} on PostgrestException catch (e) {
  if (e.code == '42501') {
    // RLS policy violation - user not authorized
    showError('Only executives and admins can create posts');
  }
}
```

---

## 📅 Events & RSVP

### Event Creation (Executive-Only)

```dart
await eventRepository.createEvent(
  title: 'Event Name',
  description: 'Details',
  clubId: clubId,
  eventDatetime: DateTime.now().add(Duration(days: 1)),
  location: 'Location',
);
```

### RSVP States

```dart
// User can be in one state per event:
'going'      // Confirmed attendance
'interested' // Considering attendance
```

### RSVP Flow

```dart
// Upsert RSVP (creates or updates)
await eventRepository.upsertRSVP(
  eventId: eventId,
  status: 'going',  // or 'interested'
);

// Database handles unique constraint (event_id, user_id)
// Update if exists, insert if new
```

### 24-Hour Reminder Logic

```sql
-- Trigger on event creation:
IF event_datetime >= now() + '24 hours' THEN
  -- Schedule 24-hour reminder notification
ELSE
  -- Queue immediate "starting soon" notification
END;
```

---

## 🔔 Notifications

### Notification Types

- `event_reminder_24h` - Reminder 24 hours before event
- `event_starting_soon` - Event starting in < 24 hours
- `new_post` - Someone posted in followed club
- `new_comment` - Someone replied to your post
- `rsvp_change` - Event RSVP status changed

### Backend Queue

```sql
-- Notifications stored in notification_queue table
-- Scheduled_for column determines when to display
-- Consumer service (future) reads queue and sends to frontend
```

### Realtime Subscription (Future)

```dart
// Listen for new notifications in real-time
Supabase.instance.client
  .from('notification_queue')
  .on(RealtimeListenTypes.postgresChanges,
      event: 'INSERT',
      schema: 'public',
      callback: (payload) {
        // Display new notification
      })
  .subscribe();
```

---

## 🏢 Role-Based Access

### Helper Functions

```sql
is_admin(user_id)
  → true if profile.role = 'admin'

is_executive_or_admin(user_id)
  → true if profile.role IN ('executive', 'admin')
```

### RLS Policies

```sql
-- Example: Post creation (executive-only)
CREATE POLICY "Only executives and admins can create posts"
ON feed_posts FOR INSERT
WITH CHECK (
  author_id = auth.uid() AND 
  is_executive_or_admin(auth.uid())
);

-- Example: Club management (admin-only)
CREATE POLICY "Only admins can modify clubs"
ON clubs FOR UPDATE
WITH CHECK (is_admin(auth.uid()));
```

### Testing Policies

```dart
// Test as student (should fail)
try {
  await feedRepository.createPost(...);
} catch (e) {
  print('Expected error: $e');
}

// Test as executive (should succeed)
await authRepository.login(executiveEmail, password);
await feedRepository.createPost(...);
```

---

## 🎨 UI Components

### Reusable Widgets

#### StatsCard
```dart
StatsCard(
  label: 'Clubs followed',
  value: '5',
  icon: Icons.groups_outlined,
  accentColor: AppColors.cta,
)
```

#### ClubCard
```dart
ClubCard(
  name: 'ML Club',
  members: 45,
  icon: Icons.memory_outlined,  // Material IconData
  category: 'Tech',
)
```

#### PostCard
```dart
PostCard(
  author: 'Name',
  clubName: 'ML Club',
  content: 'Post text',
  imageUrl: 'url',  // Optional
  timestamp: DateTime.now(),
  onLike: () {},
  onComment: () {},
  onShare: () {},
)
```

#### AvatarWidget
```dart
AvatarWidget(
  userName: 'John Doe',
  size: 48,
)
```

---

## 🧪 Common Patterns

### Riverpod State Management

```dart
// Define provider
final feedProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.read(feedRepositoryProvider);
  return repo.getHomeFeed();
});

// Use in widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final feedAsync = ref.watch(feedProvider);
  
  return feedAsync.when(
    loading: () => CircularProgressIndicator(),
    error: (err, stack) => ErrorWidget(error: err),
    data: (posts) => ListView(children: posts),
  );
}
```

### Realtime Streams

```dart
// Listen to events table
Stream<List<Event>> getUpcomingEvents() {
  return Supabase.instance.client
    .from('events')
    .stream(primaryKey: ['id'])
    .gt('event_datetime', DateTime.now().toIso8601String())
    .order('event_datetime', ascending: true)
    .map((maps) => maps.map((m) => Event.fromJson(m)).toList());
}
```

### RPC Calls

```dart
// Call Supabase RPC function
Future<void> requestExecutiveAccess() async {
  await Supabase.instance.client.rpc(
    'request_executive_access',
    // params: {} if function takes no args
  );
}

Future<List<Post>> getModeFeed(String mode) async {
  final result = await Supabase.instance.client.rpc(
    'get_home_feed_v2',
    params: {
      'p_limit': 20,
      'p_offset': 0,
      'p_mode': mode,  // 'global' or 'personalized'
    },
  );
  return result.map((m) => Post.fromJson(m)).toList();
}
```

---

## 🐛 Debugging

### Flutter Logs

```bash
flutter logs  # Stream device logs
```

### Supabase Dashboard

```
https://app.supabase.com
→ Project → Database → SQL Editor
→ Project → Logs → API Requests
```

### Common Issues

#### "Function does not exist"
- Check migration order - helpers must run first
- Verify migration was deployed successfully

#### "RLS policy violation"
- Check user's role in profiles table
- Verify auth.uid() matches expectations

#### "UNIQUE constraint violation"
- Check for duplicate (event_id, user_id) pairs in event_rsvps
- Use UPSERT pattern, not INSERT

#### "Async context warning"
- Capture ScaffoldMessenger/Navigator before async operation
- Use `if (!context.mounted) return;` guard

---

## 📝 Code Style

### Naming
- `camelCase` for variables, methods
- `PascalCase` for classes, widgets
- `UPPER_SNAKE_CASE` for constants
- Descriptive names (avoid `x`, `tmp`, `data`)

### Structure
- Section headers with comment blocks
- Logical organization (imports → constants → functions)
- Blank lines between logical sections
- 80-120 character line limit

### Documentation
- Purpose comments before functions
- Explain "why", not "what" (code is already obvious)
- Comments near complex logic or non-obvious decisions

### Example

```dart
// ==========================================
// AUTH SERVICE
// ==========================================
// Why: Centralizes Supabase auth operations
// to prevent scattered client calls.

class SupabaseAuthService {
  final SupabaseClient _client;

  /// Purpose: Authenticate user with email/password
  /// Returns: User + Profile data on success
  /// Throws: AuthException if credentials invalid
  Future<(User, UserProfile)> login(String email, String password) async {
    try {
      final AuthResponse(:session, :user) = 
        await _client.auth.signInWithPassword(...);
      final profile = await _loadProfile(user.id);
      return (user, profile);
    } on AuthException catch (e) {
      throw AuthException('Login failed: ${e.message}');
    }
  }
}
```

---

## 📞 Getting Help

### Resources

- [Supabase Docs](https://supabase.com/docs)
- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Go Router Docs](https://pub.dev/packages/go_router)

### Debugging Steps

1. Check Flutter logs: `flutter logs`
2. Check Supabase dashboard logs
3. Search GitHub issues for similar problems
4. Verify environment variables are set
5. Check migration order in supabase/migrations/
6. Test individual components in isolation

---

## ✅ Pre-Deployment Checklist

- [ ] `flutter analyze` passes
- [ ] All migrations deployed
- [ ] Auth flow tested (signup, login, logout)
- [ ] Feed system tested (Global ↔ Personalized)
- [ ] Post creation tested (executive-only)
- [ ] RSVP tested (going ↔ interested)
- [ ] Events and notifications verified
- [ ] Profile page renders without overflow
- [ ] No debug prints in code
- [ ] No hardcoded mock data

---

**Quick Reference Created:** April 20, 2026
