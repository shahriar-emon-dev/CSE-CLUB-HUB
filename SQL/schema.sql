-- ============================================================
-- CSE CLUB HUB — Supabase PostgreSQL Schema + RLS Policies
-- Author: Emon Hossain (223071044)
-- ============================================================



-- ─────────────────────────────────────────────────────────────
-- TABLE: profiles
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name       TEXT NOT NULL,
  student_id      TEXT UNIQUE,
  batch           TEXT,
  email           TEXT UNIQUE NOT NULL,
  phone           TEXT,
  bio             TEXT,
  avatar_url      TEXT,
  github_url      TEXT,
  linkedin_url    TEXT,
  portfolio_url   TEXT,
  skills          TEXT[] DEFAULT '{}',
  role            TEXT NOT NULL DEFAULT 'pending'
                  CHECK (role IN ('super_admin', 'admin', 'member', 'pending', 'banned', 'alumni')),
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'inactive', 'banned')),
  is_approved     BOOLEAN DEFAULT FALSE,
  joined_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;


-- ─────────────────────────────────────────────────────────────
-- HELPER FUNCTIONS
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT get_my_role() IN ('admin', 'super_admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_member()
RETURNS BOOLEAN AS $$
  SELECT get_my_role() IN ('member', 'admin', 'super_admin')
    AND (SELECT is_approved FROM public.profiles WHERE id = auth.uid()) = TRUE;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (
  is_admin() OR id = auth.uid() OR (is_member() AND is_approved = TRUE)
);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT
  WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (
  id = auth.uid() OR is_admin()
) WITH CHECK (id = auth.uid() OR is_admin());
CREATE POLICY "profiles_delete" ON public.profiles FOR DELETE USING (
  get_my_role() = 'super_admin'
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- TABLE: events
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  description     TEXT,
  category        TEXT NOT NULL CHECK (category IN ('workshop','seminar','competition','cultural','general')),
  venue           TEXT,
  event_date      TIMESTAMPTZ NOT NULL,
  end_date        TIMESTAMPTZ,
  cover_image_url TEXT,
  capacity        INTEGER DEFAULT NULL,
  tags            TEXT[] DEFAULT '{}',
  is_published    BOOLEAN DEFAULT FALSE,
  is_cancelled    BOOLEAN DEFAULT FALSE,
  created_by      UUID REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "events_select" ON public.events FOR SELECT USING (
  is_published = TRUE OR is_admin()
);
CREATE POLICY "events_insert" ON public.events FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "events_update" ON public.events FOR UPDATE USING (is_admin());
CREATE POLICY "events_delete" ON public.events FOR DELETE USING (is_admin());

CREATE TRIGGER events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────
-- TABLE: event_rsvps
-- ─────────────────────────────────────────────────────────────
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

ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rsvps_select" ON public.event_rsvps FOR SELECT USING (
  user_id = auth.uid() OR is_admin()
);
CREATE POLICY "rsvps_insert" ON public.event_rsvps FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());
CREATE POLICY "rsvps_update" ON public.event_rsvps FOR UPDATE USING (is_admin());
CREATE POLICY "rsvps_delete" ON public.event_rsvps FOR DELETE USING (
  user_id = auth.uid() OR is_admin()
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: blogs
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.blogs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  excerpt         TEXT,
  content         TEXT NOT NULL,
  cover_image_url TEXT,
  category        TEXT NOT NULL CHECK (category IN ('technical','creative','event_recap','news','opinion')),
  tags            TEXT[] DEFAULT '{}',
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

ALTER TABLE public.blogs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blogs_select" ON public.blogs FOR SELECT USING (
  status = 'published' OR author_id = auth.uid() OR is_admin()
);
CREATE POLICY "blogs_insert" ON public.blogs FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());
CREATE POLICY "blogs_update" ON public.blogs FOR UPDATE USING (
  (author_id = auth.uid() AND status IN ('draft','rejected')) OR is_admin()
);
CREATE POLICY "blogs_delete" ON public.blogs FOR DELETE USING (
  author_id = auth.uid() OR is_admin()
);

CREATE TRIGGER blogs_updated_at
  BEFORE UPDATE ON public.blogs
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────
-- TABLE: blog_likes
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.blog_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blog_id    UUID NOT NULL REFERENCES public.blogs(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(blog_id, user_id)
);

ALTER TABLE public.blog_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blog_likes_select" ON public.blog_likes FOR SELECT USING (TRUE);
CREATE POLICY "blog_likes_insert" ON public.blog_likes FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());
CREATE POLICY "blog_likes_delete" ON public.blog_likes FOR DELETE USING (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- TABLE: comments
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('blog','forum_post','event')),
  entity_id   UUID NOT NULL,
  parent_id   UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  author_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comments_select" ON public.comments FOR SELECT USING (is_deleted = FALSE);
CREATE POLICY "comments_insert" ON public.comments FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());
CREATE POLICY "comments_update" ON public.comments FOR UPDATE USING (
  author_id = auth.uid() OR is_admin()
);

CREATE TRIGGER comments_updated_at
  BEFORE UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────
-- TABLE: notices
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.notices (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  category    TEXT NOT NULL DEFAULT 'general'
              CHECK (category IN ('urgent','general','event','academic','other')),
  priority    INTEGER DEFAULT 0,
  is_pinned   BOOLEAN DEFAULT FALSE,
  expires_at  TIMESTAMPTZ,
  created_by  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notices_select" ON public.notices FOR SELECT USING (
  auth.uid() IS NOT NULL AND (expires_at IS NULL OR expires_at > NOW()) OR is_admin()
);
CREATE POLICY "notices_insert" ON public.notices FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "notices_update" ON public.notices FOR UPDATE USING (is_admin());
CREATE POLICY "notices_delete" ON public.notices FOR DELETE USING (is_admin());

CREATE TRIGGER notices_updated_at
  BEFORE UPDATE ON public.notices
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────
-- TABLE: gallery_albums
-- ─────────────────────────────────────────────────────────────
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

ALTER TABLE public.gallery_albums ENABLE ROW LEVEL SECURITY;

CREATE POLICY "albums_select" ON public.gallery_albums FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "albums_insert" ON public.gallery_albums FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "albums_update" ON public.gallery_albums FOR UPDATE USING (is_admin());
CREATE POLICY "albums_delete" ON public.gallery_albums FOR DELETE USING (is_admin());

CREATE TRIGGER albums_updated_at
  BEFORE UPDATE ON public.gallery_albums
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────
-- TABLE: gallery_photos
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.gallery_photos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  album_id    UUID NOT NULL REFERENCES public.gallery_albums(id) ON DELETE CASCADE,
  url         TEXT NOT NULL,
  caption     TEXT,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.gallery_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "photos_select" ON public.gallery_photos FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "photos_insert" ON public.gallery_photos FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "photos_delete" ON public.gallery_photos FOR DELETE USING (is_admin());

-- ─────────────────────────────────────────────────────────────
-- TABLE: photo_likes
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.photo_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id   UUID NOT NULL REFERENCES public.gallery_photos(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(photo_id, user_id)
);

ALTER TABLE public.photo_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "photo_likes_select" ON public.photo_likes FOR SELECT USING (TRUE);
CREATE POLICY "photo_likes_insert" ON public.photo_likes FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());
CREATE POLICY "photo_likes_delete" ON public.photo_likes FOR DELETE USING (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- TABLE: forum_categories
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.forum_categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  icon        TEXT,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.forum_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "forum_cats_select" ON public.forum_categories FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "forum_cats_insert" ON public.forum_categories FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "forum_cats_update" ON public.forum_categories FOR UPDATE USING (is_admin());
CREATE POLICY "forum_cats_delete" ON public.forum_categories FOR DELETE USING (is_admin());

-- Seed default categories
INSERT INTO public.forum_categories (name, description, icon, sort_order) VALUES
  ('Tech Help', 'Ask technical questions and get help', 'help_outline', 1),
  ('Project Ideas', 'Share and discuss project ideas', 'lightbulb_outline', 2),
  ('General Chat', 'Off-topic discussions', 'chat_bubble_outline', 3),
  ('Resources', 'Share learning resources and links', 'menu_book', 4),
  ('Announcements', 'Official club announcements', 'campaign', 5);

-- ─────────────────────────────────────────────────────────────
-- TABLE: forum_threads
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.forum_threads (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   UUID NOT NULL REFERENCES public.forum_categories(id),
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
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

ALTER TABLE public.forum_threads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "threads_select" ON public.forum_threads FOR SELECT USING (
  is_deleted = FALSE AND auth.uid() IS NOT NULL
);
CREATE POLICY "threads_insert" ON public.forum_threads FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());
CREATE POLICY "threads_update" ON public.forum_threads FOR UPDATE USING (
  author_id = auth.uid() OR is_admin()
);
CREATE POLICY "threads_delete" ON public.forum_threads FOR DELETE USING (is_admin());

CREATE TRIGGER threads_updated_at
  BEFORE UPDATE ON public.forum_threads
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────
-- TABLE: forum_posts
-- ─────────────────────────────────────────────────────────────
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

ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "posts_select" ON public.forum_posts FOR SELECT USING (
  is_deleted = FALSE AND auth.uid() IS NOT NULL
);
CREATE POLICY "posts_insert" ON public.forum_posts FOR INSERT
  WITH CHECK (author_id = auth.uid() AND is_member());
CREATE POLICY "posts_update" ON public.forum_posts FOR UPDATE USING (
  author_id = auth.uid() OR is_admin()
);
CREATE POLICY "posts_delete" ON public.forum_posts FOR DELETE USING (is_admin());

CREATE TRIGGER posts_updated_at
  BEFORE UPDATE ON public.forum_posts
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-update thread reply_count and last_reply_at
CREATE OR REPLACE FUNCTION public.handle_new_forum_post()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.forum_threads
  SET reply_count = reply_count + 1,
      last_reply_at = NOW()
  WHERE id = NEW.thread_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_forum_post_created
  AFTER INSERT ON public.forum_posts
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_forum_post();

-- ─────────────────────────────────────────────────────────────
-- TABLE: post_upvotes
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.post_upvotes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

ALTER TABLE public.post_upvotes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "upvotes_select" ON public.post_upvotes FOR SELECT USING (TRUE);
CREATE POLICY "upvotes_insert" ON public.post_upvotes FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_member());
CREATE POLICY "upvotes_delete" ON public.post_upvotes FOR DELETE USING (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- TABLE: notifications
-- ─────────────────────────────────────────────────────────────
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
  entity_type TEXT,
  entity_id   UUID,
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (
  user_id = auth.uid()
);
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT
  WITH CHECK (is_admin() OR user_id = auth.uid());
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (
  user_id = auth.uid()
);
CREATE POLICY "notifications_delete" ON public.notifications FOR DELETE USING (
  user_id = auth.uid()
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: notification_preferences
-- ─────────────────────────────────────────────────────────────
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

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notif_prefs_select" ON public.notification_preferences FOR SELECT USING (
  user_id = auth.uid()
);
CREATE POLICY "notif_prefs_insert" ON public.notification_preferences FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "notif_prefs_update" ON public.notification_preferences FOR UPDATE USING (
  user_id = auth.uid()
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: audit_logs
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    UUID REFERENCES public.profiles(id),
  action      TEXT NOT NULL,
  entity_type TEXT,
  entity_id   UUID,
  metadata    JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_select" ON public.audit_logs FOR SELECT USING (is_admin());
CREATE POLICY "audit_insert" ON public.audit_logs FOR INSERT WITH CHECK (is_admin());

-- ─────────────────────────────────────────────────────────────
-- TABLE: reports
-- ─────────────────────────────────────────────────────────────
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

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reports_select" ON public.reports FOR SELECT USING (
  reporter_id = auth.uid() OR is_admin()
);
CREATE POLICY "reports_insert" ON public.reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid() AND is_member());
CREATE POLICY "reports_update" ON public.reports FOR UPDATE USING (is_admin());

-- ─────────────────────────────────────────────────────────────
-- STORAGE BUCKETS (run in Supabase Dashboard → Storage)
-- ─────────────────────────────────────────────────────────────
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('event-covers', 'event-covers', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('blog-images', 'blog-images', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('gallery', 'gallery', true);

-- ─────────────────────────────────────────────────────────────
-- USEFUL VIEWS
-- ─────────────────────────────────────────────────────────────

-- Blog list with author name and like count
CREATE VIEW public.blog_list_view AS
SELECT 
  b.*,
  p.full_name AS author_name,
  p.avatar_url AS author_avatar,
  COUNT(bl.id) AS like_count
FROM public.blogs b
LEFT JOIN public.profiles p ON b.author_id = p.id
LEFT JOIN public.blog_likes bl ON b.id = bl.blog_id
GROUP BY b.id, p.full_name, p.avatar_url;

-- Event list with RSVP count
CREATE VIEW public.event_list_view AS
SELECT 
  e.*,
  p.full_name AS organizer_name,
  COUNT(r.id) AS rsvp_count
FROM public.events e
LEFT JOIN public.profiles p ON e.created_by = p.id
LEFT JOIN public.event_rsvps r ON e.id = r.event_id AND r.status = 'confirmed'
GROUP BY e.id, p.full_name;

-- ─────────────────────────────────────────────────────────────
-- TABLE: content_reports (Moderation Queue)
-- ─────────────────────────────────────────────────────────────
CREATE TYPE public.report_status AS ENUM ('pending', 'under_review', 'resolved', 'dismissed');
CREATE TYPE public.report_severity AS ENUM ('low', 'medium', 'high');
CREATE TYPE public.content_type AS ENUM ('post', 'event', 'comment', 'blog');

CREATE TABLE public.content_reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content_type    public.content_type NOT NULL,
  post_id         UUID REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  event_id        UUID REFERENCES public.events(id) ON DELETE CASCADE,
  comment_id      UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  blog_id         UUID REFERENCES public.blogs(id) ON DELETE CASCADE,
  reason          TEXT NOT NULL,
  status          public.report_status NOT NULL DEFAULT 'pending',
  severity        public.report_severity NOT NULL DEFAULT 'low',
  resolved_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT check_content_target CHECK (
    (content_type = 'post' AND post_id IS NOT NULL AND event_id IS NULL AND comment_id IS NULL AND blog_id IS NULL) OR
    (content_type = 'event' AND event_id IS NOT NULL AND post_id IS NULL AND comment_id IS NULL AND blog_id IS NULL) OR
    (content_type = 'comment' AND comment_id IS NOT NULL AND post_id IS NULL AND event_id IS NULL AND blog_id IS NULL) OR
    (content_type = 'blog' AND blog_id IS NOT NULL AND post_id IS NULL AND event_id IS NULL AND comment_id IS NULL)
  )
);

ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- Regular users can insert reports
CREATE POLICY "reports_insert" ON public.content_reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid() AND is_member());

-- Only admins/super_admins can read, update, delete reports
CREATE POLICY "reports_select" ON public.content_reports FOR SELECT USING (is_admin());
CREATE POLICY "reports_update" ON public.content_reports FOR UPDATE USING (is_admin());
CREATE POLICY "reports_delete" ON public.content_reports FOR DELETE USING (get_my_role() = 'super_admin');

CREATE TRIGGER reports_updated_at
  BEFORE UPDATE ON public.content_reports
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────
-- TABLE: moderation_logs
-- ─────────────────────────────────────────────────────────────
CREATE TYPE public.moderation_action AS ENUM ('approved', 'deleted', 'warned', 'banned');

CREATE TABLE public.moderation_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moderator_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  report_id       UUID REFERENCES public.content_reports(id) ON DELETE SET NULL,
  action          public.moderation_action NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.moderation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "modlogs_select" ON public.moderation_logs FOR SELECT USING (is_admin());
CREATE POLICY "modlogs_insert" ON public.moderation_logs FOR INSERT WITH CHECK (is_admin());
-- No updates or deletes allowed on logs

-- ─────────────────────────────────────────────────────────────
-- INDEXES for performance
-- ─────────────────────────────────────────────────────────────
CREATE INDEX idx_blogs_status ON public.blogs(status);
CREATE INDEX idx_blogs_author ON public.blogs(author_id);
CREATE INDEX idx_events_date ON public.events(event_date);
CREATE INDEX idx_events_published ON public.events(is_published);
CREATE INDEX idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX idx_forum_threads_category ON public.forum_threads(category_id);
CREATE INDEX idx_forum_posts_thread ON public.forum_posts(thread_id);
CREATE INDEX idx_comments_entity ON public.comments(entity_type, entity_id);
CREATE INDEX idx_rsvps_event ON public.event_rsvps(event_id);
CREATE INDEX idx_rsvps_user ON public.event_rsvps(user_id);
CREATE INDEX idx_content_reports_status ON public.content_reports(status);
CREATE INDEX idx_content_reports_severity ON public.content_reports(severity);
CREATE INDEX idx_moderation_logs_report ON public.moderation_logs(report_id);
