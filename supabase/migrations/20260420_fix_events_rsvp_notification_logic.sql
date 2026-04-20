-- ==========================================
-- FIX #6 + #7: EVENT REMINDERS + RSVP STATE MACHINE
-- ==========================================
-- Goals:
-- 1) 24h reminder guard for late-created events.
-- 2) Deterministic RSVP state model with duplicate prevention.
-- 3) Event cancellation and delete-safe behavior via FK cascades.

-- ==========================================
-- SECTION 1: EVENTS TABLE BASELINE
-- ==========================================

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete set null,
  title text not null,
  description text,
  event_datetime timestamptz not null,
  venue text,
  poster_url text,
  is_cancelled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.events
  add column if not exists club_id uuid references public.clubs(id) on delete cascade,
  add column if not exists created_by uuid references auth.users(id) on delete set null,
  add column if not exists title text,
  add column if not exists description text,
  add column if not exists event_datetime timestamptz,
  add column if not exists venue text,
  add column if not exists poster_url text,
  add column if not exists is_cancelled boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_events_datetime on public.events (event_datetime);
create index if not exists idx_events_club_id on public.events (club_id);
create index if not exists idx_events_cancelled on public.events (is_cancelled);

alter table public.events enable row level security;

drop policy if exists "Authenticated users can read events" on public.events;
drop policy if exists "Executives or admins can create events" on public.events;
drop policy if exists "Event owners or admins can update events" on public.events;
drop policy if exists "Event owners or admins can delete events" on public.events;

create policy "Authenticated users can read events"
on public.events
for select
to authenticated
using (true);

create policy "Executives or admins can create events"
on public.events
for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.is_executive_or_admin(auth.uid())
);

create policy "Event owners or admins can update events"
on public.events
for update
to authenticated
using (
  (created_by = auth.uid() and public.is_executive_or_admin(auth.uid()))
  or public.is_admin(auth.uid())
)
with check (
  (created_by = auth.uid() and public.is_executive_or_admin(auth.uid()))
  or public.is_admin(auth.uid())
);

create policy "Event owners or admins can delete events"
on public.events
for delete
to authenticated
using (
  (created_by = auth.uid() and public.is_executive_or_admin(auth.uid()))
  or public.is_admin(auth.uid())
);

-- ==========================================
-- SECTION 2: RSVP STATE MACHINE TABLE + RPCS
-- ==========================================

create table if not exists public.rsvps (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rsvps_status_check check (status in ('going', 'interested')),
  constraint rsvps_event_user_unique unique (event_id, user_id)
);

alter table public.rsvps enable row level security;

create index if not exists idx_rsvps_event_id on public.rsvps (event_id);
create index if not exists idx_rsvps_user_id on public.rsvps (user_id);

drop policy if exists "Users can read own rsvps" on public.rsvps;
drop policy if exists "Users can insert own rsvps" on public.rsvps;
drop policy if exists "Users can update own rsvps" on public.rsvps;
drop policy if exists "Users can delete own rsvps" on public.rsvps;

create policy "Users can read own rsvps"
on public.rsvps
for select
to authenticated
using (user_id = auth.uid() or public.is_admin(auth.uid()));

create policy "Users can insert own rsvps"
on public.rsvps
for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can update own rsvps"
on public.rsvps
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can delete own rsvps"
on public.rsvps
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin(auth.uid()));

create or replace function public.set_timestamp_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_rsvps_set_updated_at on public.rsvps;
create trigger trg_rsvps_set_updated_at
before update on public.rsvps
for each row
execute function public.set_timestamp_updated_at();

create or replace function public.upsert_event_rsvp(p_event_id uuid, p_status text)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status text := lower(trim(p_status));
  v_event public.events%rowtype;
begin
  if v_status not in ('going', 'interested') then
    raise exception 'Invalid RSVP status. Use going or interested.';
  end if;

  select * into v_event
  from public.events e
  where e.id = p_event_id;

  if not found then
    raise exception 'Event not found.';
  end if;

  if v_event.is_cancelled then
    raise exception 'Cannot RSVP to a cancelled event.';
  end if;

  insert into public.rsvps (event_id, user_id, status)
  values (p_event_id, auth.uid(), v_status)
  on conflict (event_id, user_id)
  do update set
    status = excluded.status,
    updated_at = now();
end;
$$;

create or replace function public.cancel_event_rsvp(p_event_id uuid)
returns void
language sql
security invoker
set search_path = public
as $$
  delete from public.rsvps
  where event_id = p_event_id
    and user_id = auth.uid();
$$;

grant execute on function public.upsert_event_rsvp(uuid, text) to authenticated;
grant execute on function public.cancel_event_rsvp(uuid) to authenticated;

create or replace view public.event_rsvp_counts as
select
  e.id as event_id,
  count(r.id) filter (where r.status = 'going')::int as going_count,
  count(r.id) filter (where r.status = 'interested')::int as interested_count
from public.events e
left join public.rsvps r on r.event_id = e.id
group by e.id;

grant select on public.event_rsvp_counts to authenticated;

-- ==========================================
-- SECTION 3: NOTIFICATION QUEUE + REMINDER GUARD
-- ==========================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  club_id uuid references public.clubs(id) on delete set null,
  event_id uuid references public.events(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  scheduled_for timestamptz,
  sent_at timestamptz,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on public.notifications (user_id, created_at desc);
create index if not exists idx_notifications_event on public.notifications (event_id);
create index if not exists idx_notifications_scheduled on public.notifications (scheduled_for) where sent_at is null;

alter table public.notifications enable row level security;

drop policy if exists "Users can read own notifications" on public.notifications;
drop policy if exists "Users can mark own notifications read" on public.notifications;
drop policy if exists "System and admins can insert notifications" on public.notifications;

create policy "Users can read own notifications"
on public.notifications
for select
to authenticated
using (user_id = auth.uid() or public.is_admin(auth.uid()));

create policy "Users can mark own notifications read"
on public.notifications
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "System and admins can insert notifications"
on public.notifications
for insert
to authenticated
with check (public.is_admin(auth.uid()));

create or replace function public.enqueue_event_notifications(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event public.events%rowtype;
  v_schedule_at timestamptz;
begin
  select * into v_event
  from public.events e
  where e.id = p_event_id;

  if not found then
    return;
  end if;

  -- Clear unsent reminder queue for this event before regenerating.
  delete from public.notifications n
  where n.event_id = p_event_id
    and n.notification_type in ('event_reminder_24h', 'event_upcoming_soon')
    and n.sent_at is null;

  if v_event.is_cancelled then
    -- Optional: notification for cancellation to current RSVP users.
    insert into public.notifications (user_id, club_id, event_id, notification_type, title, body, scheduled_for)
    select
      r.user_id,
      v_event.club_id,
      v_event.id,
      'event_cancelled',
      'Event cancelled',
      'An event you followed was cancelled: ' || v_event.title,
      now()
    from public.rsvps r
    where r.event_id = v_event.id
    on conflict do nothing;

    return;
  end if;

  if v_event.event_datetime >= now() + interval '24 hours' then
    v_schedule_at := v_event.event_datetime - interval '24 hours';

    insert into public.notifications (user_id, club_id, event_id, notification_type, title, body, scheduled_for)
    select
      f.user_id,
      v_event.club_id,
      v_event.id,
      'event_reminder_24h',
      '24-hour event reminder',
      'Upcoming event tomorrow: ' || v_event.title,
      v_schedule_at
    from public.user_club_follows f
    where f.club_id = v_event.club_id
    on conflict do nothing;
  else
    -- Guard path: event starts in under 24h.
    insert into public.notifications (user_id, club_id, event_id, notification_type, title, body, scheduled_for)
    select
      f.user_id,
      v_event.club_id,
      v_event.id,
      'event_upcoming_soon',
      'Upcoming event soon',
      'Event starts soon: ' || v_event.title,
      now()
    from public.user_club_follows f
    where f.club_id = v_event.club_id
    on conflict do nothing;
  end if;
end;
$$;

create or replace function public.trg_enqueue_event_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.enqueue_event_notifications(new.id);
  return new;
end;
$$;

drop trigger if exists trg_events_enqueue_notifications on public.events;
create trigger trg_events_enqueue_notifications
after insert or update of event_datetime, is_cancelled, title, club_id
on public.events
for each row
execute function public.trg_enqueue_event_notifications();
