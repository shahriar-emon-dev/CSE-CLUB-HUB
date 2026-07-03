# CSE Club Hub — Full Implementation Plan

> **Student:** Emon Hossain | **ID:** 223071044  
> **Platform:** Flutter (Mobile/Web) + Supabase (Backend)  
> **Tech Stack:** Flutter, Dart, Supabase (PostgreSQL + Auth + Storage + Realtime)

---

## Project Overview

**CSE Club Hub** is a centralized digital platform for the Computer Science & Engineering department's student club. It serves as a hub for:
- Managing club membership and member profiles
- Announcing and managing events/workshops
- Publishing blog posts and news articles
- Photo/video gallery management
- Notice board and announcements
- Admin panel for club executives
- Discussion/forum features

---

## User Roles & Actors

| Role | Description |
|------|-------------|
| **Super Admin** | Full system control (club president or faculty advisor) |
| **Admin / Executive** | Manage events, posts, members, notices |
| **Member** | Registered club member — can RSVP, comment, post blogs |
| **Visitor / Guest** | Unauthenticated user — read-only public content |

---

## All Functional Requirements

### FR-01: Authentication & Authorization
- FR-01.1 — User registration with university email (e.g., `@csedu.edu`)
- FR-01.2 — Email verification on signup
- FR-01.3 — Login with email + password
- FR-01.4 — Google OAuth login (optional)
- FR-01.5 — Password reset via email link
- FR-01.6 — JWT-based session management (Supabase Auth)
- FR-01.7 — Role-based access control (Super Admin / Admin / Member / Guest)
- FR-01.8 — Logout and session invalidation

### FR-02: Member Management
- FR-02.1 — Member profile creation (name, student ID, batch, department, contact)
- FR-02.2 — Profile photo upload
- FR-02.3 — Admin approval of new member registrations
- FR-02.4 — Admin can assign/revoke member roles
- FR-02.5 — Member directory listing (searchable, filterable by batch/role)
- FR-02.6 — Member can edit their own profile
- FR-02.7 — Admin can deactivate/ban a member
- FR-02.8 — Member status tracking (active, inactive, alumni)
- FR-02.9 — Display member skills, social links (GitHub, LinkedIn)

### FR-03: Events Management
- FR-03.1 — Admin can create events (title, description, date/time, venue, cover image)
- FR-03.2 — Event categories (workshop, seminar, competition, cultural, general)
- FR-03.3 — Members can RSVP / register for events
- FR-03.4 — Admin can set event capacity/seats
- FR-03.5 — Waitlist if event is at capacity
- FR-03.6 — Event reminder notifications (push + in-app)
- FR-03.7 — Admin can mark attendance for events
- FR-03.8 — Past events archive with photos
- FR-03.9 — Event tags and search
- FR-03.10 — Admin can cancel/reschedule events with notification

### FR-04: Blog / News / Articles
- FR-04.1 — Members can write and submit blog posts
- FR-04.2 — Rich text editor for blog content (with images)
- FR-04.3 — Admin must approve/publish blog posts (moderation)
- FR-04.4 — Blog categories (technical, creative, events recap, news)
- FR-04.5 — Blog listing with thumbnail, author, date, read time
- FR-04.6 — Individual blog post page with full content
- FR-04.7 — Comments section on blog posts
- FR-04.8 — Like/reaction on blog posts
- FR-04.9 — Share blog post (link copy)
- FR-04.10 — Search blogs by title, tag, author
- FR-04.11 — Author profile linked from blog

### FR-05: Notice Board / Announcements
- FR-05.1 — Admin can post notices (title, body, priority level)
- FR-05.2 — Notices categorized (urgent, general, event-related)
- FR-05.3 — Pinned notices displayed at top
- FR-05.4 — Notice expiry date support
- FR-05.5 — Members receive push notification on new notice
- FR-05.6 — Notice archive (all past notices)

### FR-06: Gallery
- FR-06.1 — Admin can create photo albums (per event or standalone)
- FR-06.2 — Upload multiple photos to an album
- FR-06.3 — Photo viewer with swipe/zoom
- FR-06.4 — Album cover selection
- FR-06.5 — Members can react to photos (like)
- FR-06.6 — Admin can delete/edit photos and albums
- FR-06.7 — Video support in gallery (YouTube link embed or uploaded video)

### FR-07: Discussion / Forum
- FR-07.1 — Members can create discussion threads
- FR-07.2 — Threaded replies (nested comments)
- FR-07.3 — Like/upvote on posts and replies
- FR-07.4 — Forum categories (tech help, project ideas, general chat, announcements)
- FR-07.5 — Search within forum
- FR-07.6 — Admin can pin, lock, or delete threads
- FR-07.7 — Report a post for moderation

### FR-08: Notifications
- FR-08.1 — In-app notification center (bell icon)
- FR-08.2 — Push notifications via FCM (Firebase Cloud Messaging)
- FR-08.3 — Notification types: new event, blog approved, notice, comment, RSVP confirmation
- FR-08.4 — Mark notifications as read
- FR-08.5 — Notification preferences (user can enable/disable types)

### FR-09: Admin Dashboard
- FR-09.1 — Dashboard overview with stats (total members, events, posts)
- FR-09.2 — Pending approvals (member registrations, blog posts)
- FR-09.3 — Member management (CRUD)
- FR-09.4 — Event management (CRUD)
- FR-09.5 — Blog/content management
- FR-09.6 — Notice management
- FR-09.7 — Gallery management
- FR-09.8 — Role management (assign admin/member roles)
- FR-09.9 — Export member list (CSV)
- FR-09.10 — Activity logs/audit trail

### FR-10: Search & Discovery
- FR-10.1 — Global search (members, events, blogs, notices)
- FR-10.2 — Filter events by date, category
- FR-10.3 — Filter members by batch, role, status

### FR-11: Home Feed
- FR-11.1 — Aggregated feed of recent events, blogs, notices
- FR-11.2 — Pinned/featured content at top
- FR-11.3 — Quick action buttons (RSVP, read blog, view notice)

---

## All UI Screens

### Public / Unauthenticated Screens
| # | Screen | Description |
|---|--------|-------------|
| S-01 | **Splash Screen** | App logo animation, auto-redirect to login/home |
| S-02 | **Onboarding** | 3-slide intro to app features |
| S-03 | **Login** | Email/password + Google OAuth button |
| S-04 | **Register** | Name, student ID, batch, email, password |
| S-05 | **Email Verification** | Instructions + resend email button |
| S-06 | **Forgot Password** | Email input → send reset link |
| S-07 | **Public Home** | Hero banner, latest events, recent blogs (read-only) |

### Authenticated Member Screens
| # | Screen | Description |
|---|--------|-------------|
| S-08 | **Home Feed** | Cards for latest events, blogs, notices, quick stats |
| S-09 | **Events List** | Grid/list of upcoming + past events with filters |
| S-10 | **Event Detail** | Full event info, RSVP button, attendee count, map |
| S-11 | **My RSVPs** | Events the user has registered for |
| S-12 | **Blog List** | Blog feed with categories, search |
| S-13 | **Blog Detail** | Full blog post, author card, comments, likes |
| S-14 | **Write Blog** | Rich text editor, image upload, tag selection, submit for review |
| S-15 | **My Blogs** | User's own draft/published/pending blogs |
| S-16 | **Notice Board** | List of all notices, pinned at top, filter by category |
| S-17 | **Notice Detail** | Full notice content |
| S-18 | **Gallery** | Albums grid view |
| S-19 | **Album Detail** | Photo grid in an album, full-screen viewer |
| S-20 | **Members Directory** | Searchable member list (name, batch, role, photo) |
| S-21 | **Member Profile** | Individual member profile (bio, skills, socials, events) |
| S-22 | **My Profile** | Own profile view + edit button |
| S-23 | **Edit Profile** | Edit name, bio, skills, photo, social links |
| S-24 | **Forum / Discussion** | Category tabs, thread list |
| S-25 | **Forum Thread Detail** | Full thread with nested replies |
| S-26 | **Create Thread** | Title, body, category, tags |
| S-27 | **Notifications** | Bell icon page — list of all notifications |
| S-28 | **Notification Settings** | Toggle notification types on/off |
| S-29 | **Search** | Global search results across entities |
| S-30 | **Settings** | App theme, language, account settings, logout |

### Admin Screens
| # | Screen | Description |
|---|--------|-------------|
| S-31 | **Admin Dashboard** | Stats overview, pending items, quick links |
| S-32 | **Member Management** | List of all members, approve/reject/ban, role assignment |
| S-33 | **Member Detail (Admin)** | Full member info with admin actions |
| S-34 | **Create/Edit Event** | Form: title, desc, date, venue, capacity, cover image, category |
| S-35 | **Event Attendance** | Manage event attendees, mark attendance |
| S-36 | **Blog Moderation** | Pending blogs queue, approve/reject with note |
| S-37 | **Create/Edit Notice** | Form: title, body, priority, expiry, pin toggle |
| S-38 | **Gallery Management** | Create/edit/delete albums, upload photos |
| S-39 | **Forum Moderation** | Pin, lock, delete threads/posts |
| S-40 | **Audit Log** | Activity history (who did what, when) |
| S-41 | **Role Management** | Assign Super Admin / Admin / Member roles |

---

## Supabase SQL Tables (Full Schema)

### 1. `profiles` — Extended user data (linked to `auth.users`)
```sql
CREATE TABLE public.profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name       TEXT NOT NULL,
  student_id      TEXT UNIQUE,
  batch           TEXT,                        -- e.g., "2021", "2022"
  email           TEXT UNIQUE NOT NULL,
  phone           TEXT,
  bio             TEXT,
  avatar_url      TEXT,                        -- Supabase Storage URL
  github_url      TEXT,
  linkedin_url    TEXT,
  portfolio_url   TEXT,
  skills          TEXT[],                      -- Array of skill strings
  role            TEXT NOT NULL DEFAULT 'pending'
                  CHECK (role IN ('super_admin', 'admin', 'member', 'pending', 'banned', 'alumni')),
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'inactive', 'banned')),
  is_approved     BOOLEAN DEFAULT FALSE,
  joined_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. `events`
```sql
CREATE TABLE public.events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  description     TEXT,
  category        TEXT NOT NULL CHECK (category IN ('workshop','seminar','competition','cultural','general')),
  venue           TEXT,
  event_date      TIMESTAMPTZ NOT NULL,
  end_date        TIMESTAMPTZ,
  cover_image_url TEXT,
  capacity        INTEGER DEFAULT NULL,        -- NULL = unlimited
  tags            TEXT[],
  is_published    BOOLEAN DEFAULT FALSE,
  is_cancelled    BOOLEAN DEFAULT FALSE,
  created_by      UUID REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### 3. `event_rsvps` — Who registered for which event
```sql
CREATE TABLE public.event_rsvps (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id        UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'confirmed'
                  CHECK (status IN ('confirmed', 'waitlisted', 'cancelled')),
  attended        BOOLEAN DEFAULT FALSE,
  registered_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);
```

### 4. `blogs`
```sql
CREATE TABLE public.blogs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,        -- URL-friendly title
  excerpt         TEXT,                        -- Short preview text
  content         TEXT NOT NULL,              -- Rich text / HTML content
  cover_image_url TEXT,
  category        TEXT NOT NULL CHECK (category IN ('technical','creative','event_recap','news','opinion')),
  tags            TEXT[],
  author_id       UUID NOT NULL REFERENCES public.profiles(id),
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft','pending','published','rejected')),
  rejection_note  TEXT,
  read_time_mins  INTEGER,
  view_count      INTEGER DEFAULT 0,
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### 5. `blog_likes`
```sql
CREATE TABLE public.blog_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blog_id    UUID NOT NULL REFERENCES public.blogs(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(blog_id, user_id)
);
```

### 6. `comments`
```sql
CREATE TABLE public.comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('blog','forum_post','event')),
  entity_id   UUID NOT NULL,
  parent_id   UUID REFERENCES public.comments(id) ON DELETE CASCADE,  -- for nested replies
  author_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 7. `notices`
```sql
CREATE TABLE public.notices (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  category    TEXT NOT NULL DEFAULT 'general'
              CHECK (category IN ('urgent','general','event','academic','other')),
  priority    INTEGER DEFAULT 0,              -- Higher = more important
  is_pinned   BOOLEAN DEFAULT FALSE,
  expires_at  TIMESTAMPTZ,
  created_by  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 8. `gallery_albums`
```sql
CREATE TABLE public.gallery_albums (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  description  TEXT,
  cover_url    TEXT,
  event_id     UUID REFERENCES public.events(id) ON DELETE SET NULL,
  created_by   UUID REFERENCES public.profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);
```

### 9. `gallery_photos`
```sql
CREATE TABLE public.gallery_photos (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  album_id   UUID NOT NULL REFERENCES public.gallery_albums(id) ON DELETE CASCADE,
  url        TEXT NOT NULL,                  -- Supabase Storage URL
  caption    TEXT,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 10. `photo_likes`
```sql
CREATE TABLE public.photo_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id   UUID NOT NULL REFERENCES public.gallery_photos(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(photo_id, user_id)
);
```

### 11. `forum_categories`
```sql
CREATE TABLE public.forum_categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  icon        TEXT,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 12. `forum_threads`
```sql
CREATE TABLE public.forum_threads (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   UUID NOT NULL REFERENCES public.forum_categories(id),
  title         TEXT NOT NULL,
  author_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_pinned     BOOLEAN DEFAULT FALSE,
  is_locked     BOOLEAN DEFAULT FALSE,
  is_deleted    BOOLEAN DEFAULT FALSE,
  view_count    INTEGER DEFAULT 0,
  reply_count   INTEGER DEFAULT 0,
  last_reply_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);
```

### 13. `forum_posts`
```sql
CREATE TABLE public.forum_posts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id   UUID NOT NULL REFERENCES public.forum_threads(id) ON DELETE CASCADE,
  parent_id   UUID REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  author_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  upvotes     INTEGER DEFAULT 0,
  is_deleted  BOOLEAN DEFAULT FALSE,
  is_reported BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 14. `post_upvotes`
```sql
CREATE TABLE public.post_upvotes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);
```

### 15. `notifications`
```sql
CREATE TABLE public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN (
                'new_event','event_reminder','rsvp_confirmed','rsvp_waitlisted',
                'blog_approved','blog_rejected','new_notice','new_comment',
                'new_reply','role_changed','member_approved','forum_reply'
              )),
  title       TEXT NOT NULL,
  body        TEXT,
  entity_type TEXT,                          -- 'event','blog','notice','forum_thread' etc
  entity_id   UUID,
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 16. `notification_preferences`
```sql
CREATE TABLE public.notification_preferences (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  new_events      BOOLEAN DEFAULT TRUE,
  new_notices     BOOLEAN DEFAULT TRUE,
  blog_updates    BOOLEAN DEFAULT TRUE,
  forum_replies   BOOLEAN DEFAULT TRUE,
  event_reminders BOOLEAN DEFAULT TRUE,
  comments        BOOLEAN DEFAULT TRUE,
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### 17. `audit_logs`
```sql
CREATE TABLE public.audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    UUID REFERENCES public.profiles(id),
  action      TEXT NOT NULL,                 -- e.g., 'approved_member', 'deleted_blog'
  entity_type TEXT,
  entity_id   UUID,
  metadata    JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 18. `reports`
```sql
CREATE TABLE public.reports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.profiles(id),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('blog','forum_post','comment','profile')),
  entity_id   UUID NOT NULL,
  reason      TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending','reviewed','dismissed','actioned')),
  resolved_by UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);
```

### 19. `member_event_attendance` (view helper or FK)
*(Covered by `event_rsvps.attended` column — no separate table needed)*

---

## Supabase Storage Buckets

| Bucket Name | Access | Purpose |
|-------------|--------|---------|
| `avatars` | Private (signed URL) | Member profile photos |
| `event-covers` | Public | Event cover images |
| `blog-images` | Public | Blog inline images & covers |
| `gallery` | Public | Gallery album photos |
| `notices` | Private | Notice attachments (if any) |

---

## Row Level Security (RLS) Policies

> Enable RLS on ALL tables: `ALTER TABLE public.<table> ENABLE ROW LEVEL SECURITY;`

### Helper Functions
```sql
-- Get current user's role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if current user is admin or super_admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT get_my_role() IN ('admin', 'super_admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if current user is approved member
CREATE OR REPLACE FUNCTION public.is_member()
RETURNS BOOLEAN AS $$
  SELECT get_my_role() IN ('member', 'admin', 'super_admin') 
    AND (SELECT is_approved FROM public.profiles WHERE id = auth.uid()) = TRUE;
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

---

### `profiles` RLS
```sql
-- SELECT: Admins see all; members see approved profiles; owner sees own
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (
  is_admin() OR id = auth.uid() OR (is_member() AND is_approved = TRUE)
);

-- INSERT: Anyone can create their own profile on signup
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- UPDATE: Owner can update own non-role fields; admin can update anyone
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (
  id = auth.uid() OR is_admin()
) WITH CHECK (
  id = auth.uid() OR is_admin()
);

-- DELETE: Super admin only
CREATE POLICY "profiles_delete" ON public.profiles FOR DELETE USING (
  get_my_role() = 'super_admin'
);
```

---

### `events` RLS
```sql
-- SELECT: Published events visible to all; unpublished only to admins
CREATE POLICY "events_select" ON public.events FOR SELECT USING (
  is_published = TRUE OR is_admin()
);

-- INSERT: Admins only
CREATE POLICY "events_insert" ON public.events FOR INSERT
  WITH CHECK (is_admin());

-- UPDATE: Admins only
CREATE POLICY "events_update" ON public.events FOR UPDATE USING (is_admin());

-- DELETE: Admins only
CREATE POLICY "events_delete" ON public.events FOR DELETE USING (is_admin());
```

---

### `event_rsvps` RLS
```sql
-- SELECT: Members see own RSVPs; admins see all
CREATE POLICY "rsvps_select" ON public.event_rsvps FOR SELECT USING (
  user_id = auth.uid() OR is_admin()
);

-- INSERT: Approved members only, for themselves
CREATE POLICY "rsvps_insert" ON public.event_rsvps FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());

-- UPDATE: Admin only (for attendance marking)
CREATE POLICY "rsvps_update" ON public.event_rsvps FOR UPDATE USING (is_admin());

-- DELETE: Owner can cancel own RSVP; admin can remove any
CREATE POLICY "rsvps_delete" ON public.event_rsvps FOR DELETE USING (
  user_id = auth.uid() OR is_admin()
);
```

---

### `blogs` RLS
```sql
-- SELECT: Published blogs visible to all; own drafts/pending visible to author; admins see all
CREATE POLICY "blogs_select" ON public.blogs FOR SELECT USING (
  status = 'published' OR author_id = auth.uid() OR is_admin()
);

-- INSERT: Approved members only
CREATE POLICY "blogs_insert" ON public.blogs FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());

-- UPDATE: Author updates own draft/pending; admin can update any
CREATE POLICY "blogs_update" ON public.blogs FOR UPDATE USING (
  (author_id = auth.uid() AND status IN ('draft','rejected')) OR is_admin()
);

-- DELETE: Author deletes own; admin deletes any
CREATE POLICY "blogs_delete" ON public.blogs FOR DELETE USING (
  author_id = auth.uid() OR is_admin()
);
```

---

### `blog_likes` RLS
```sql
CREATE POLICY "blog_likes_select" ON public.blog_likes FOR SELECT USING (TRUE);
CREATE POLICY "blog_likes_insert" ON public.blog_likes FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());
CREATE POLICY "blog_likes_delete" ON public.blog_likes FOR DELETE USING (
  user_id = auth.uid()
);
```

---

### `comments` RLS
```sql
-- SELECT: All can see non-deleted comments on published entities
CREATE POLICY "comments_select" ON public.comments FOR SELECT USING (
  is_deleted = FALSE
);

-- INSERT: Members only
CREATE POLICY "comments_insert" ON public.comments FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());

-- UPDATE: Author updates own within time limit; admin updates any
CREATE POLICY "comments_update" ON public.comments FOR UPDATE USING (
  author_id = auth.uid() OR is_admin()
);

-- DELETE (soft): Admin or owner marks as deleted
CREATE POLICY "comments_delete" ON public.comments FOR UPDATE USING (
  author_id = auth.uid() OR is_admin()
);
```

---

### `notices` RLS
```sql
-- SELECT: All authenticated users can see active notices
CREATE POLICY "notices_select" ON public.notices FOR SELECT USING (
  auth.uid() IS NOT NULL AND (expires_at IS NULL OR expires_at > NOW())
  OR is_admin()
);

-- INSERT/UPDATE/DELETE: Admins only
CREATE POLICY "notices_insert" ON public.notices FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "notices_update" ON public.notices FOR UPDATE USING (is_admin());
CREATE POLICY "notices_delete" ON public.notices FOR DELETE USING (is_admin());
```

---

### `gallery_albums` RLS
```sql
CREATE POLICY "albums_select" ON public.gallery_albums FOR SELECT USING (TRUE);
CREATE POLICY "albums_insert" ON public.gallery_albums FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "albums_update" ON public.gallery_albums FOR UPDATE USING (is_admin());
CREATE POLICY "albums_delete" ON public.gallery_albums FOR DELETE USING (is_admin());
```

---

### `gallery_photos` RLS
```sql
CREATE POLICY "photos_select" ON public.gallery_photos FOR SELECT USING (TRUE);
CREATE POLICY "photos_insert" ON public.gallery_photos FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "photos_delete" ON public.gallery_photos FOR DELETE USING (is_admin());
```

---

### `photo_likes` RLS
```sql
CREATE POLICY "photo_likes_select" ON public.photo_likes FOR SELECT USING (TRUE);
CREATE POLICY "photo_likes_insert" ON public.photo_likes FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());
CREATE POLICY "photo_likes_delete" ON public.photo_likes FOR DELETE USING (user_id = auth.uid());
```

---

### `forum_threads` RLS
```sql
CREATE POLICY "threads_select" ON public.forum_threads FOR SELECT USING (is_deleted = FALSE);
CREATE POLICY "threads_insert" ON public.forum_threads FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());
CREATE POLICY "threads_update" ON public.forum_threads FOR UPDATE USING (
  author_id = auth.uid() OR is_admin()
);
CREATE POLICY "threads_delete" ON public.forum_threads FOR DELETE USING (is_admin());
```

---

### `forum_posts` RLS
```sql
CREATE POLICY "posts_select" ON public.forum_posts FOR SELECT USING (is_deleted = FALSE);
CREATE POLICY "posts_insert" ON public.forum_posts FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());
CREATE POLICY "posts_update" ON public.forum_posts FOR UPDATE USING (
  author_id = auth.uid() OR is_admin()
);
CREATE POLICY "posts_delete" ON public.forum_posts FOR DELETE USING (is_admin());
```

---

### `post_upvotes` RLS
```sql
CREATE POLICY "upvotes_select" ON public.post_upvotes FOR SELECT USING (TRUE);
CREATE POLICY "upvotes_insert" ON public.post_upvotes FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());
CREATE POLICY "upvotes_delete" ON public.post_upvotes FOR DELETE USING (user_id = auth.uid());
```

---

### `notifications` RLS
```sql
-- Users only see their own notifications
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (
  user_id = auth.uid()
);
-- Only server/admin can insert (via service role)
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT
  WITH CHECK (is_admin());
-- Users mark own as read
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (
  user_id = auth.uid()
);
```

---

### `notification_preferences` RLS
```sql
CREATE POLICY "notif_prefs_select" ON public.notification_preferences FOR SELECT USING (
  user_id = auth.uid()
);
CREATE POLICY "notif_prefs_insert" ON public.notification_preferences FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "notif_prefs_update" ON public.notification_preferences FOR UPDATE USING (
  user_id = auth.uid()
);
```

---

### `audit_logs` RLS
```sql
-- Only admins can read audit logs; insert via service role only
CREATE POLICY "audit_select" ON public.audit_logs FOR SELECT USING (is_admin());
CREATE POLICY "audit_insert" ON public.audit_logs FOR INSERT WITH CHECK (is_admin());
```

---

### `reports` RLS
```sql
CREATE POLICY "reports_select" ON public.reports FOR SELECT USING (
  reporter_id = auth.uid() OR is_admin()
);
CREATE POLICY "reports_insert" ON public.reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid() AND is_member());
CREATE POLICY "reports_update" ON public.reports FOR UPDATE USING (is_admin());
```

---

## Supabase Realtime Subscriptions

| Channel | Table | Purpose |
|---------|-------|---------|
| `notifications:user_id=eq.{uid}` | `notifications` | Live notification bell updates |
| `forum_posts:thread_id=eq.{id}` | `forum_posts` | Live forum replies |
| `event_rsvps:event_id=eq.{id}` | `event_rsvps` | Live attendee count on event page |
| `notices` | `notices` | Live notice board updates |

---

## Supabase Edge Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `on-member-approved` | Row insert to `profiles` where `is_approved=TRUE` | Send welcome notification |
| `on-event-created` | Row insert to `events` | Notify all members |
| `on-blog-approved` | `blogs.status` changes to `published` | Notify author + all members |
| `on-rsvp-created` | Row insert to `event_rsvps` | Confirm RSVP notification |
| `event-reminder` | Cron — 24h before event | Push reminder to RSVP'd members |
| `on-new-comment` | Row insert to `comments` | Notify post/blog author |
| `on-new-reply` | Row insert to `forum_posts` | Notify thread author |

---

## Tech Stack Summary

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (iOS + Android + Web) |
| **State Management** | Riverpod / BLoC |
| **Backend** | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Rich Text Editor** | `flutter_quill` package |
| **Image Handling** | Supabase Storage + `image_picker` |
| **Routing** | `go_router` |
| **HTTP/API** | `supabase_flutter` SDK |

---

## Open Questions

> [!IMPORTANT]
> Please confirm the following before development begins:

1. **Platform priority** — Mobile-first (Flutter) or Web-first? Or both simultaneously?
2. **University email domain** — What email domain to restrict registration to? (e.g., `@cse.uiu.ac.bd`)
3. **Blog editor** — Simple markdown or full rich text (images inline)?
4. **Forum** — Required in v1 or a later phase?
5. **Push notifications** — Firebase FCM required or just in-app notifications for v1?
6. **Attendance** — QR code scan for event attendance, or manual admin marking?
7. **Alumni** — Is alumni as a separate role needed from day one?
8. **Payment** — Any paid events / membership fees module needed?

---

## Implementation Phases

### Phase 1 — Foundation (Weeks 1-2)
- Supabase project setup, all tables + RLS
- Auth flow (register, login, email verify, forgot password)
- Profile creation and admin approval workflow

### Phase 2 — Core Features (Weeks 3-5)
- Events CRUD + RSVP system
- Blog system (write, submit, approve, publish)
- Notice board

### Phase 3 — Community (Weeks 6-7)
- Gallery albums + photos
- Forum / Discussion threads
- Comments and likes across entities

### Phase 4 — Admin & Notifications (Week 8)
- Admin dashboard with full management
- In-app notifications
- Audit logs

### Phase 5 — Polish (Week 9-10)
- Push notifications (FCM)
- Search & filters
- Performance optimization
- Testing & deployment
