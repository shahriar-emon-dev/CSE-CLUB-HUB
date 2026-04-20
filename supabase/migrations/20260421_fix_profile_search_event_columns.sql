-- ==========================================
-- SUPPORTING SCHEMA FOR PROFILE, SEARCH, AND RSVP COUNTS
-- ==========================================

alter table public.profiles
  add column if not exists bio text;

alter table public.posts
  add column if not exists title text;

alter table public.events
  add column if not exists going_count integer not null default 0,
  add column if not exists interested_count integer not null default 0;

create or replace function public.recalculate_event_rsvp_counts(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_going int;
  v_interested int;
begin
  select
    count(*) filter (where status = 'going')::int,
    count(*) filter (where status = 'interested')::int
  into v_going, v_interested
  from public.rsvps
  where event_id = p_event_id;

  update public.events
  set
    going_count = coalesce(v_going, 0),
    interested_count = coalesce(v_interested, 0)
  where id = p_event_id;
end;
$$;

grant execute on function public.recalculate_event_rsvp_counts(uuid) to authenticated;

create or replace function public.trg_sync_event_counts_from_rsvp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.recalculate_event_rsvp_counts(old.event_id);
    return old;
  end if;

  perform public.recalculate_event_rsvp_counts(new.event_id);
  if tg_op = 'UPDATE' and old.event_id is distinct from new.event_id then
    perform public.recalculate_event_rsvp_counts(old.event_id);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_event_counts_from_rsvp on public.rsvps;

create trigger trg_sync_event_counts_from_rsvp
after insert or update or delete on public.rsvps
for each row
execute function public.trg_sync_event_counts_from_rsvp();
