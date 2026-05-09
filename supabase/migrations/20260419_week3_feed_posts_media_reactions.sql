-- ==========================================
-- WEEK 3 FEED BACKEND UPGRADE (SAFE / NON-BREAKING)
-- ==========================================
-- Purpose:
-- 1) Add/extend schema for club-based posts, media, reactions, and comments.
-- 2) Configure storage buckets and policies for post media and club logos.
-- 3) Provide efficient feed query primitives (view + function) for Flutter.
--
-- Compatibility:
-- - Uses create table if not exists / add column if not exists.
-- - Does not alter existing column types.
-- - Existing tables and queries continue to work.

-- ==========================================
-- SECTION 1: POSTS TABLE (CREATE OR EXTEND)
-- ==========================================

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  content text,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  is_deleted boolean not null default false
);

alter table public.posts
  add column if not exists club_id uuid references public.clubs(id) on delete set null,
  add column if not exists author_id uuid references auth.users(id) on delete set null,
  add column if not exists content text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz,
  add column if not exists is_deleted boolean not null default false;

create index if not exists idx_posts_created_at on public.posts (created_at desc);
create index if not exists idx_posts_club_id on public.posts (club_id);
create index if not exists idx_posts_author_id on public.posts (author_id);
create index if not exists idx_posts_is_deleted on public.posts (is_deleted);

-- ==========================================
-- SECTION 2: POST MEDIA TABLE (NEW)
-- ==========================================

create table if not exists public.post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  media_url text not null,
  media_type text not null default 'image',
  created_at timestamptz not null default now(),
  constraint post_media_type_check check (media_type in ('image', 'video'))
);

create index if not exists idx_post_media_post_id on public.post_media (post_id);
create index if not exists idx_post_media_created_at on public.post_media (created_at desc);

-- ==========================================
-- SECTION 3: CLUBS TABLE EXTENSION (SAFE)
-- ==========================================

alter table public.clubs
  add column if not exists logo_url text,
  add column if not exists cover_url text,
  add column if not exists description text;

-- ==========================================
-- SECTION 4: REACTIONS TABLE (NEW)
-- ==========================================

create table if not exists public.reactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  type text not null default 'like',
  created_at timestamptz not null default now(),
  constraint reactions_type_check check (type in ('like', 'fire', 'clap')),
  constraint reactions_user_post_unique unique (user_id, post_id)
);

create index if not exists idx_reactions_post_id on public.reactions (post_id);
create index if not exists idx_reactions_user_id on public.reactions (user_id);

-- ==========================================
-- SECTION 5: COMMENTS TABLE (NEW, FUTURE-READY)
-- ==========================================

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_comments_post_id on public.comments (post_id);
create index if not exists idx_comments_user_id on public.comments (user_id);
create index if not exists idx_comments_created_at on public.comments (created_at desc);

-- ==========================================
-- SECTION 6: STORAGE BUCKETS
-- ==========================================

insert into storage.buckets (id, name, public)
values ('post-media', 'post-media', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('club-logos', 'club-logos', true)
on conflict (id) do nothing;

-- ==========================================
-- SECTION 7: ROW LEVEL SECURITY
-- ==========================================

alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.reactions enable row level security;
alter table public.comments enable row level security;

-- POSTS POLICIES
-- Public can read non-deleted feed rows.
drop policy if exists "Posts are publicly readable" on public.posts;
drop policy if exists "Authors or admins can insert posts" on public.posts;
drop policy if exists "Authors or admins can update posts" on public.posts;
drop policy if exists "Authors or admins can delete posts" on public.posts;

create policy "Posts are publicly readable"
on public.posts
for select
to public
using (is_deleted = false);

create policy "Authors or admins can insert posts"
on public.posts
for insert
to authenticated
with check (
  (author_id = auth.uid())
  or public.is_admin(auth.uid())
);

create policy "Authors or admins can update posts"
on public.posts
for update
to authenticated
using (
  (author_id = auth.uid())
  or public.is_admin(auth.uid())
)
with check (
  (author_id = auth.uid())
  or public.is_admin(auth.uid())
);

create policy "Authors or admins can delete posts"
on public.posts
for delete
to authenticated
using (
  (author_id = auth.uid())
  or public.is_admin(auth.uid())
);

-- POST MEDIA POLICIES
-- Public read, authenticated insert; owner/admin update-delete.
drop policy if exists "Post media is publicly readable" on public.post_media;
drop policy if exists "Authenticated users can insert post media" on public.post_media;
drop policy if exists "Owners or admins can update post media" on public.post_media;
drop policy if exists "Owners or admins can delete post media" on public.post_media;

create policy "Post media is publicly readable"
on public.post_media
for select
to public
using (true);

create policy "Authenticated users can insert post media"
on public.post_media
for insert
to authenticated
with check (
  exists (
    select 1
    from public.posts p
    where p.id = post_id
      and ((p.author_id = auth.uid()) or public.is_admin(auth.uid()))
  )
);

create policy "Owners or admins can update post media"
on public.post_media
for update
to authenticated
using (
  exists (
    select 1
    from public.posts p
    where p.id = post_id
      and ((p.author_id = auth.uid()) or public.is_admin(auth.uid()))
  )
)
with check (
  exists (
    select 1
    from public.posts p
    where p.id = post_id
      and ((p.author_id = auth.uid()) or public.is_admin(auth.uid()))
  )
);

create policy "Owners or admins can delete post media"
on public.post_media
for delete
to authenticated
using (
  exists (
    select 1
    from public.posts p
    where p.id = post_id
      and ((p.author_id = auth.uid()) or public.is_admin(auth.uid()))
  )
);

-- REACTIONS POLICIES
-- Public read; users can manage only their own reactions.
drop policy if exists "Reactions are publicly readable" on public.reactions;
drop policy if exists "Users can insert own reactions" on public.reactions;
drop policy if exists "Users can update own reactions" on public.reactions;
drop policy if exists "Users can delete own reactions" on public.reactions;

create policy "Reactions are publicly readable"
on public.reactions
for select
to public
using (true);

create policy "Users can insert own reactions"
on public.reactions
for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can update own reactions"
on public.reactions
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can delete own reactions"
on public.reactions
for delete
to authenticated
using (user_id = auth.uid());

-- COMMENTS POLICIES
-- Public read; users can write/manage own comments.
drop policy if exists "Comments are publicly readable" on public.comments;
drop policy if exists "Users can insert own comments" on public.comments;
drop policy if exists "Users can update own comments" on public.comments;
drop policy if exists "Users can delete own comments" on public.comments;

create policy "Comments are publicly readable"
on public.comments
for select
to public
using (true);

create policy "Users can insert own comments"
on public.comments
for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can update own comments"
on public.comments
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can delete own comments"
on public.comments
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin(auth.uid()));

-- STORAGE OBJECT POLICIES
-- Note: We keep policies bucket-scoped and backward-compatible.
drop policy if exists "Public can read post-media bucket" on storage.objects;
drop policy if exists "Authenticated can upload post-media" on storage.objects;
drop policy if exists "Owners or admins can update post-media" on storage.objects;
drop policy if exists "Owners or admins can delete post-media" on storage.objects;

drop policy if exists "Public can read club-logos bucket" on storage.objects;
drop policy if exists "Authenticated can upload club-logos" on storage.objects;
drop policy if exists "Owners or admins can update club-logos" on storage.objects;
drop policy if exists "Owners or admins can delete club-logos" on storage.objects;

create policy "Public can read post-media bucket"
on storage.objects
for select
to public
using (bucket_id = 'post-media');

create policy "Authenticated can upload post-media"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'post-media');

create policy "Owners or admins can update post-media"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'post-media'
  and ((owner = auth.uid()) or public.is_admin(auth.uid()))
)
with check (
  bucket_id = 'post-media'
  and ((owner = auth.uid()) or public.is_admin(auth.uid()))
);

create policy "Owners or admins can delete post-media"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'post-media'
  and ((owner = auth.uid()) or public.is_admin(auth.uid()))
);

create policy "Public can read club-logos bucket"
on storage.objects
for select
to public
using (bucket_id = 'club-logos');

create policy "Authenticated can upload club-logos"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'club-logos');

create policy "Owners or admins can update club-logos"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'club-logos'
  and ((owner = auth.uid()) or public.is_admin(auth.uid()))
)
with check (
  bucket_id = 'club-logos'
  and ((owner = auth.uid()) or public.is_admin(auth.uid()))
);

create policy "Owners or admins can delete club-logos"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'club-logos'
  and ((owner = auth.uid()) or public.is_admin(auth.uid()))
);

-- ==========================================
-- SECTION 8: FEED QUERY VIEW + RPC FUNCTION
-- ==========================================

create or replace view public.feed_posts_v1 as
select
  p.id as post_id,
  p.content,
  p.created_at,
  p.updated_at,
  p.club_id,
  c.name as club_name,
  c.logo_url as club_logo_url,
  p.author_id,
  coalesce(pr.full_name, pr.email, 'Unknown') as author_name,
  coalesce(pr.role, 'student') as author_role,
  pr.avatar_url as author_avatar_url,
  coalesce(
    (
      select json_agg(pm.media_url order by pm.created_at)
      from public.post_media pm
      where pm.post_id = p.id
    ),
    '[]'::json
  ) as media_urls,
  coalesce(
    (
      select count(*)::int
      from public.reactions r
      where r.post_id = p.id and r.type = 'like'
    ),
    0
  ) as like_count,
  coalesce(
    (
      select count(*)::int
      from public.reactions r
      where r.post_id = p.id and r.type = 'fire'
    ),
    0
  ) as fire_count,
  coalesce(
    (
      select count(*)::int
      from public.reactions r
      where r.post_id = p.id and r.type = 'clap'
    ),
    0
  ) as clap_count,
  coalesce(
    (
      select count(*)::int
      from public.comments cm
      where cm.post_id = p.id
    ),
    0
  ) as comment_count
from public.posts p
left join public.clubs c on c.id = p.club_id
left join public.profiles pr on pr.id = p.author_id
where p.is_deleted = false;

create or replace function public.get_home_feed(
  p_limit int default 20,
  p_offset int default 0
)
returns table (
  post_id uuid,
  content text,
  created_at timestamptz,
  updated_at timestamptz,
  club_id uuid,
  club_name text,
  club_logo_url text,
  author_id uuid,
  author_name text,
  author_role text,
  author_avatar_url text,
  media_urls json,
  like_count int,
  fire_count int,
  clap_count int,
  comment_count int
)
language sql
stable
security invoker
as $$
  select
    f.post_id,
    f.content,
    f.created_at,
    f.updated_at,
    f.club_id,
    f.club_name,
    f.club_logo_url,
    f.author_id,
    f.author_name,
    f.author_role,
    f.author_avatar_url,
    f.media_urls,
    f.like_count,
    f.fire_count,
    f.clap_count,
    f.comment_count
  from public.feed_posts_v1 f
  order by f.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

grant select on public.feed_posts_v1 to authenticated, anon;
grant execute on function public.get_home_feed(int, int) to authenticated, anon;
