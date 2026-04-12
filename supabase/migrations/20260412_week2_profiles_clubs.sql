-- Week 2: Profiles and Clubs schema additions for CSE Club Hub
-- Safe to run in Supabase SQL editor or migration pipeline.

-- ==========================================
-- SECTION 1: PROFILES ENHANCEMENT
-- ==========================================

alter table public.profiles
  add column if not exists avatar_url text,
  add column if not exists department text;

update public.profiles
set department = 'CSE'
where department is null;

alter table public.profiles
  alter column department set default 'CSE',
  alter column department set not null;

create index if not exists idx_profiles_department on public.profiles (department);

-- ==========================================
-- SECTION 2: AVATAR STORAGE BASELINE
-- ==========================================

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "Avatar images are publicly readable" on storage.objects;
drop policy if exists "Users can upload own avatar" on storage.objects;
drop policy if exists "Users can update own avatar" on storage.objects;

create policy "Avatar images are publicly readable"
on storage.objects
for select
to public
using (bucket_id = 'avatars');

create policy "Users can upload own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and owner = auth.uid()
);

create policy "Users can update own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and owner = auth.uid()
)
with check (
  bucket_id = 'avatars'
  and owner = auth.uid()
);

-- ==========================================
-- SECTION 3: CLUBS CATALOG
-- ==========================================

create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null unique,
  description text not null,
  bio text,
  logo_url text,
  cover_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_clubs_is_active on public.clubs (is_active);

alter table public.clubs enable row level security;

drop policy if exists "Anyone can read active clubs" on public.clubs;

create policy "Anyone can read active clubs"
on public.clubs
for select
to authenticated
using (is_active = true);

insert into public.clubs (slug, name, description, bio)
values
  ('machine-learning-club', 'Machine Learning Club', 'AI and data science community', 'Focuses on AI, deep learning, and data projects.'),
  ('competitive-programming-club', 'Competitive Programming Club', 'Algorithms and contest preparation', 'Practice sessions for ICPC-style problem solving.'),
  ('iot-robotics-club', 'IoT & Robotics Club', 'Hardware and automation', 'Builds smart systems, robots, and embedded solutions.'),
  ('web-development-club', 'Web Development Club', 'Frontend and backend engineering', 'Works on full-stack web products and deployment.'),
  ('software-development-club', 'Software Development Club', 'App and system engineering', 'Builds maintainable software products end to end.'),
  ('cyber-security-club', 'Cyber Security Club', 'Security and ethical hacking', 'Covers network security, cryptography, and secure coding.')
on conflict (slug) do update
set
  name = excluded.name,
  description = excluded.description,
  bio = excluded.bio;

-- ==========================================
-- SECTION 4: FOLLOW / UNFOLLOW RELATION
-- ==========================================

create table if not exists public.user_club_follows (
  user_id uuid not null references auth.users(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, club_id)
);

create index if not exists idx_user_club_follows_user on public.user_club_follows (user_id);
create index if not exists idx_user_club_follows_club on public.user_club_follows (club_id);

alter table public.user_club_follows enable row level security;

drop policy if exists "Users can read own follows" on public.user_club_follows;
drop policy if exists "Users can follow clubs" on public.user_club_follows;
drop policy if exists "Users can unfollow clubs" on public.user_club_follows;

create policy "Users can read own follows"
on public.user_club_follows
for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can follow clubs"
on public.user_club_follows
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can unfollow clubs"
on public.user_club_follows
for delete
to authenticated
using (auth.uid() = user_id);

-- ==========================================
-- SECTION 5: HELPER VIEWS FOR WEEK 2 DASHBOARD UI
-- ==========================================

create or replace view public.club_with_followers as
select
  c.id,
  c.slug,
  c.name,
  c.description,
  c.bio,
  c.logo_url,
  c.cover_url,
  c.is_active,
  c.created_at,
  count(f.user_id)::int as follower_count
from public.clubs c
left join public.user_club_follows f on f.club_id = c.id
group by c.id;
