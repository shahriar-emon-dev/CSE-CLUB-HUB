# CSE Club Hub - Database Schema Reference

**Last Updated:** April 20, 2026  
**Status:** ✅ Production Ready

---

## 📊 Core Tables

### auth.users (Supabase Built-in)

```sql
-- Supabase Auth table (managed by Supabase)
-- Fields: id, email, raw_user_meta_data, created_at, etc.
```

### profiles

```sql
CREATE TABLE profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Personal info
  full_name varchar(255),
  email varchar(255) NOT NULL,
  student_id varchar(50),
  batch varchar(50),
  section varchar(50),
  bio varchar(500),
  avatar_url varchar(500),
  
  -- Role system: student → executive → admin
  role varchar(20) CHECK (role IN ('student', 'executive', 'admin')),
  
  -- Executive request flow
  role_request boolean DEFAULT false,
  
  -- Feed preference: 'global' (all posts) or 'personalized' (followed clubs only)
  feed_preference varchar(20) DEFAULT 'global',
  
  -- Timestamps
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  
  UNIQUE(email)
);

-- RLS Policies:
-- - Students can only read/update their own profile
-- - Executives can read all profiles, update own
-- - Admins can read/update all profiles
-- - Role change only via admin approval (not direct update)
```

### clubs

```sql
CREATE TABLE clubs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Club info
  name varchar(255) NOT NULL UNIQUE,
  description text,
  logo_url varchar(500),
  category varchar(100),  -- 'Tech', 'Creative', 'Sports', etc.
  
  -- Status
  is_active boolean DEFAULT true,
  
  -- Admin management
  created_by uuid NOT NULL REFERENCES profiles(user_id),
  
  -- Timestamps
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Note: Removed 6-club limit - now supports unlimited clubs
-- Seed data: 6 clubs (ML, CP, IoT, Web, Software, Security)
-- RLS Policies:
-- - Authenticated users can read active clubs
-- - Only admins can create/update/delete clubs
```

### user_club_follows

```sql
CREATE TABLE user_club_follows (
  user_id uuid NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  club_id uuid NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  
  followed_at timestamp DEFAULT now(),
  
  PRIMARY KEY (user_id, club_id)
);

-- Why unique constraint: Prevent duplicate follows
-- RLS Policies:
-- - Authenticated users can follow/unfollow clubs
-- - Read: Own follows only
-- - Insert/Delete: Own follows only
```

### feed_posts

```sql
CREATE TABLE feed_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Content
  author_id uuid NOT NULL REFERENCES profiles(user_id),
  club_id uuid NOT NULL REFERENCES clubs(id),
  content text NOT NULL,
  image_url varchar(500),
  
  -- Status
  is_pinned boolean DEFAULT false,
  is_deleted boolean DEFAULT false,
  
  -- Timestamps
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  
  -- For feed queries
  INDEX idx_feed_posts_club_created (club_id, created_at DESC),
  INDEX idx_feed_posts_created (created_at DESC)
);

-- RLS Policy (CRITICAL):
-- INSERT: Only executives and admins can create posts
--   - Checks: author_id = auth.uid() AND is_executive_or_admin(auth.uid())
-- SELECT: Authenticated users can read all posts
-- UPDATE: Only author (if executive/admin) can edit
-- DELETE: Only author or admin can delete
```

### post_reactions

```sql
CREATE TABLE post_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  post_id uuid NOT NULL REFERENCES feed_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  
  -- Reaction types: 'like', 'fire', 'clap', 'rocket'
  reaction_type varchar(50) NOT NULL,
  
  created_at timestamp DEFAULT now(),
  
  -- Why unique: One reaction per user per type
  UNIQUE (post_id, user_id, reaction_type),
  
  -- For quick queries
  INDEX idx_reactions_post (post_id)
);

-- RLS Policies:
-- - Authenticated users can react to posts
-- - Read: All reactions visible
-- - Insert: Create own reactions
-- - Delete: Delete own reactions
```

### post_comments

```sql
CREATE TABLE post_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  post_id uuid NOT NULL REFERENCES feed_posts(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES profiles(user_id),
  
  content text NOT NULL,
  is_deleted boolean DEFAULT false,
  
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  
  INDEX idx_comments_post (post_id),
  INDEX idx_comments_created (created_at DESC)
);

-- RLS Policies:
-- - Authenticated users can comment on posts
-- - Read: All comments visible
-- - Insert: Create own comments
-- - Update/Delete: Own comments or admin
```

### events

```sql
CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Event info
  club_id uuid NOT NULL REFERENCES clubs(id),
  title varchar(255) NOT NULL,
  description text,
  location varchar(255),
  
  -- Schedule (CRITICAL for 24-hour reminder logic)
  event_datetime timestamp NOT NULL,
  
  -- Created by (must be executive/admin)
  created_by uuid NOT NULL REFERENCES profiles(user_id),
  
  -- Timestamps
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  
  -- For notification queue queries
  INDEX idx_events_datetime (event_datetime),
  INDEX idx_events_club (club_id)
);

-- TRIGGER: On event creation
-- → Calls enqueue_event_notifications(event_id)
-- → If event >= 24h away: Queue 24-hour reminder
-- → If event < 24h away: Queue immediate "starting soon" notification

-- RLS Policies:
-- - Authenticated users can read all events
-- - Only executives/admins can create events
```

### event_rsvps

```sql
CREATE TABLE event_rsvps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  
  -- Status: 'going' or 'interested'
  status varchar(20) NOT NULL CHECK (status IN ('going', 'interested')),
  
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  
  -- Why UNIQUE: Prevent duplicate RSVPs per user per event
  -- Upsert pattern: ON CONFLICT (event_id, user_id) DO UPDATE
  UNIQUE (event_id, user_id),
  
  INDEX idx_rsvps_user (user_id),
  INDEX idx_rsvps_event (event_id)
);

-- RLS Policies:
-- - Authenticated users can RSVP to events
-- - Read: All RSVPs visible (for attendance counts)
-- - Insert/Update: Use RPC upsert_event_rsvp() for atomic operations
-- - Delete: Own RSVPs only
```

### notification_queue

```sql
CREATE TABLE notification_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Notification metadata
  type varchar(50) NOT NULL,  -- 'event_reminder_24h', 'event_starting_soon', etc.
  target_user_id uuid NOT NULL REFERENCES profiles(user_id),
  
  -- Event reference (if applicable)
  event_id uuid REFERENCES events(id) ON DELETE SET NULL,
  
  -- Scheduling
  scheduled_for timestamp NOT NULL,  -- When to display notification
  sent_at timestamp,  -- When consumer service sends it
  
  created_at timestamp DEFAULT now(),
  
  -- For consumer service queries
  INDEX idx_queue_scheduled (scheduled_for),
  INDEX idx_queue_user_sent (target_user_id, sent_at)
);

-- Purpose: Queue notifications for async delivery
-- Consumer service (future) reads unsent notifications and delivers them
-- Scheduled_for field allows delayed notifications (e.g., 24-hour reminders)
```

---

## 🔧 Helper Functions

### is_admin(user_id uuid)

```sql
CREATE FUNCTION is_admin(p_user_id uuid) RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = p_user_id AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Purpose: Check if user is admin
-- Used in: RLS policies, triggers
-- Performance: Fast (indexed on user_id)
```

### is_executive_or_admin(user_id uuid)

```sql
CREATE FUNCTION is_executive_or_admin(p_user_id uuid) RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = p_user_id AND role IN ('executive', 'admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Purpose: Check if user can create posts/events
-- Used in: RLS policies for post/event INSERT
-- Performance: Fast (indexed on user_id)
```

---

## 🔑 Key RPC Functions

### request_executive_access()

```sql
CREATE FUNCTION request_executive_access() RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET role_request = true 
  WHERE user_id = auth.uid() AND role = 'student';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Purpose: Student initiates executive access request
-- Updates: profiles.role_request = true
-- Admin later sets: role = 'executive', role_request = false
```

### withdraw_executive_request()

```sql
CREATE FUNCTION withdraw_executive_request() RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET role_request = false 
  WHERE user_id = auth.uid() AND role_request = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Purpose: Student withdraws pending request
-- Updates: profiles.role_request = false
```

### get_effective_feed_mode() → varchar

```sql
CREATE FUNCTION get_effective_feed_mode() RETURNS varchar AS $$
DECLARE
  v_follow_count INT;
  v_preference VARCHAR(20);
BEGIN
  SELECT feed_preference INTO v_preference 
  FROM profiles WHERE user_id = auth.uid();
  
  SELECT COUNT(*) INTO v_follow_count 
  FROM user_club_follows WHERE user_id = auth.uid();
  
  -- If personalized selected but no follows, force global
  IF v_preference = 'personalized' AND v_follow_count = 0 THEN
    RETURN 'global';
  END IF;
  
  RETURN COALESCE(v_preference, 'global');
END;
$$ LANGUAGE plpgsql;

-- Purpose: Determine effective feed mode
-- Logic: 
--   - If personalized AND no follows: return 'global'
--   - Otherwise: return stored preference
-- Used: Frontend to show which tab is active
```

### get_home_feed_v2(p_limit int, p_offset int, p_mode varchar)

```sql
CREATE FUNCTION get_home_feed_v2(
  p_limit INT, 
  p_offset INT, 
  p_mode VARCHAR
) RETURNS TABLE (
  id uuid, 
  author_id uuid, 
  club_id uuid, 
  content text, 
  image_url varchar,
  created_at timestamp,
  -- ... other fields
) AS $$
BEGIN
  IF p_mode = 'personalized' THEN
    RETURN QUERY
    SELECT * FROM feed_posts_v1
    WHERE club_id IN (
      SELECT club_id FROM user_club_follows 
      WHERE user_id = auth.uid()
    )
    AND is_deleted = false
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset;
  ELSE
    -- Global mode: all posts
    RETURN QUERY
    SELECT * FROM feed_posts_v1
    WHERE is_deleted = false
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Purpose: Mode-aware feed query
-- Parameters:
--   - p_limit: Number of posts per page (typically 20)
--   - p_offset: Page offset (0, 20, 40, etc.)
--   - p_mode: 'global' or 'personalized'
-- Returns: Filtered feed posts with metadata
```

### upsert_event_rsvp(p_event_id uuid, p_status varchar)

```sql
CREATE FUNCTION upsert_event_rsvp(
  p_event_id uuid, 
  p_status varchar
) RETURNS void AS $$
BEGIN
  INSERT INTO event_rsvps (id, event_id, user_id, status)
  VALUES (gen_random_uuid(), p_event_id, auth.uid(), p_status)
  ON CONFLICT (event_id, user_id) DO UPDATE
  SET status = p_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Purpose: Atomic RSVP create/update
-- Behavior:
--   - If (event_id, user_id) new: INSERT
--   - If exists: UPDATE status
-- Prevents: Duplicates, race conditions
```

### enqueue_event_notifications(event_id uuid)

```sql
CREATE FUNCTION enqueue_event_notifications(p_event_id uuid) RETURNS void AS $$
DECLARE
  v_event events%ROWTYPE;
  v_time_until_start INTERVAL;
BEGIN
  SELECT * INTO v_event FROM events WHERE id = p_event_id;
  
  v_time_until_start := v_event.event_datetime - now();
  
  IF v_time_until_start >= interval '24 hours' THEN
    -- Queue 24-hour reminder
    INSERT INTO notification_queue (type, target_user_id, event_id, scheduled_for)
    SELECT 'event_reminder_24h', user_id, p_event_id, now() + interval '24 hours'
    FROM user_club_follows
    WHERE club_id = v_event.club_id;
  ELSE
    -- Queue immediate "starting soon" notification
    INSERT INTO notification_queue (type, target_user_id, event_id, scheduled_for)
    SELECT 'event_starting_soon', user_id, p_event_id, now()
    FROM user_club_follows
    WHERE club_id = v_event.club_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Purpose: Intelligent event notification queueing
-- Logic (24-hour guard):
--   - If event >= 24h away: Schedule reminder for tomorrow
--   - If event < 24h away: Queue immediate notification
-- Called: By trigger on events INSERT
```

---

## 🔐 RLS Policies

### Example: Post Creation (Executive-Only)

```sql
CREATE POLICY "Only executives and admins can create posts" 
ON feed_posts 
FOR INSERT 
WITH CHECK (
  author_id = auth.uid() AND 
  public.is_executive_or_admin(auth.uid())
);

-- Effect: INSERT fails if user is not executive/admin
-- Error: 42501 (RLS policy violation)
-- Test: Student tries to create post → Error
```

### Example: Club Management (Admin-Only)

```sql
CREATE POLICY "Only admins can update clubs" 
ON clubs 
FOR UPDATE 
USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

-- Effect: UPDATE fails if user is not admin
-- Used: For admin panel club CRUD
```

### Example: Profile Privacy

```sql
CREATE POLICY "Students can only read/update own profile"
ON profiles
FOR SELECT
USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Students can only update own profile"
ON profiles
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
  user_id = auth.uid() AND
  role = (SELECT role FROM profiles WHERE user_id = auth.uid())  -- No role change via update
);

-- Effect: 
--   - Students see only their profile
--   - Admins see all profiles
--   - Role changes only via admin panel (not direct update)
```

---

## 🚀 Deployment Order

**CRITICAL:** Run migrations in this order:

1. ✅ `20260420_fix_role_helper_dependencies.sql` (Defines is_admin, is_executive_or_admin)
2. ✅ `20260420_fix_executive_request_flow.sql` (Request/withdraw RPCs, trigger guard)
3. ✅ `20260420_fix_post_insert_policy.sql` (Post creation RLS policy)
4. ✅ `20260420_fix_events_rsvp_notification_logic.sql` (Events, RSVPs, notifications)
5. ✅ `20260420_fix_feed_mode_default_and_preference.sql` (Feed mode + RPC)
6. ✅ `20260420_fix_club_policy_naming_and_expandability.sql` (Club expandability)
7. ✅ `20260421_finalize_expandable_clubs_override.sql` (Idempotent override)

---

## 🧪 Testing Queries

### Check User Role

```sql
SELECT user_id, role, role_request, feed_preference 
FROM profiles 
WHERE email = 'student@example.com';
```

### Check Club Follow Status

```sql
SELECT COUNT(*) as followed_clubs 
FROM user_club_follows 
WHERE user_id = '<user_id>';
```

### Check Post Visibility

```sql
SELECT COUNT(*) 
FROM feed_posts 
WHERE club_id IN (
  SELECT club_id FROM user_club_follows 
  WHERE user_id = '<user_id>'
);
```

### Check Event RSVP

```sql
SELECT status 
FROM event_rsvps 
WHERE event_id = '<event_id>' AND user_id = '<user_id>';
```

### Check Notification Queue

```sql
SELECT COUNT(*) 
FROM notification_queue 
WHERE target_user_id = '<user_id>' AND sent_at IS NULL;
```

---

## 📈 Performance Indexes

```sql
-- Already created in migrations:
INDEX idx_feed_posts_club_created (club_id, created_at DESC)
INDEX idx_feed_posts_created (created_at DESC)
INDEX idx_reactions_post (post_id)
INDEX idx_comments_post (post_id)
INDEX idx_comments_created (created_at DESC)
INDEX idx_events_datetime (event_datetime)
INDEX idx_events_club (club_id)
INDEX idx_rsvps_user (user_id)
INDEX idx_rsvps_event (event_id)
INDEX idx_queue_scheduled (scheduled_for)
INDEX idx_queue_user_sent (target_user_id, sent_at)

-- To add more if needed:
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_feed_posts_author ON feed_posts(author_id);
CREATE INDEX idx_events_club_datetime ON events(club_id, event_datetime DESC);
```

---

## ✅ Schema Validation

### Verify Migration Order
```sql
SELECT filename, created_at 
FROM schema_migrations 
ORDER BY created_at;
-- Should show all 7 migration files in order
```

### Verify RLS Enabled
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename IN ('profiles', 'feed_posts', 'events', 'event_rsvps');
-- Should show row_security = true for all
```

### Verify Helper Functions
```sql
SELECT proname FROM pg_proc 
WHERE proname IN ('is_admin', 'is_executive_or_admin');
-- Should show 2 rows
```

---

**Schema Reference Created:** April 20, 2026  
**Database:** Supabase (PostgreSQL)  
**Status:** ✅ Production Ready
