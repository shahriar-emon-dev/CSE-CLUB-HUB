-- ==========================================
-- FIX #8: PERSONALIZED VS GLOBAL FEED DEFAULT
-- ==========================================
-- Rules:
-- 1) New users default to global feed until they follow >= 1 club.
-- 2) If follows exist, users can persist feed preference.

-- ==========================================
-- SECTION 1: PROFILE FEED PREFERENCE
-- ==========================================

alter table public.profiles
  add column if not exists feed_preference text;

update public.profiles
set feed_preference = 'global'
where feed_preference is null;

alter table public.profiles
  alter column feed_preference set default 'global';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_feed_preference_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_feed_preference_check
      check (feed_preference in ('global', 'personalized'));
  end if;
end $$;

-- ==========================================
-- SECTION 2: FEED PREFERENCE RPCS
-- ==========================================

create or replace function public.set_feed_preference(p_mode text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mode text := lower(trim(p_mode));
  v_follow_count int;
begin
  if v_mode not in ('global', 'personalized') then
    raise exception 'Invalid feed mode. Use global or personalized.';
  end if;

  select count(*)::int into v_follow_count
  from public.user_club_follows f
  where f.user_id = auth.uid();

  if v_follow_count = 0 then
    v_mode := 'global';
  end if;

  update public.profiles
  set feed_preference = v_mode
  where id = auth.uid();

  return v_mode;
end;
$$;

create or replace function public.get_effective_feed_mode()
returns text
language sql
security definer
set search_path = public
stable
as $$
  select
    case
      when not exists (
        select 1 from public.user_club_follows f where f.user_id = auth.uid()
      ) then 'global'
      else coalesce(
        (select p.feed_preference from public.profiles p where p.id = auth.uid()),
        'global'
      )
    end;
$$;

grant execute on function public.set_feed_preference(text) to authenticated;
grant execute on function public.get_effective_feed_mode() to authenticated;

-- ==========================================
-- SECTION 3: MODE-AWARE FEED RPC
-- ==========================================

create or replace function public.get_home_feed_v2(
  p_limit int default 20,
  p_offset int default 0,
  p_mode text default null
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
  with follows as (
    select f.club_id
    from public.user_club_follows f
    where f.user_id = auth.uid()
  ),
  mode as (
    select
      case
        when coalesce(lower(trim(p_mode)), '') = '' then public.get_effective_feed_mode()
        when lower(trim(p_mode)) = 'personalized' and exists (select 1 from follows) then 'personalized'
        else 'global'
      end as value
  )
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
  cross join mode m
  where
    m.value = 'global'
    or (
      m.value = 'personalized'
      and f.club_id in (select club_id from follows)
    )
  order by f.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

grant execute on function public.get_home_feed_v2(int, int, text) to authenticated, anon;
