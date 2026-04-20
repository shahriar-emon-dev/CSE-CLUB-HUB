-- ==========================================
-- FIX #4: EXECUTIVE REQUEST FLOW
-- ==========================================
-- Goal:
-- 1) Student can self-request executive access (role_request: false -> true).
-- 2) Student cannot directly set role.
-- 3) Student cannot directly set role_request back to false; must use RPC.
-- 4) Admin can still manage role and role_request.

-- ==========================================
-- SECTION 1: SAFE ROLE_REQUEST BASELINE
-- ==========================================

alter table public.profiles
  alter column role_request set default false,
  alter column role_request set not null;

update public.profiles
set role_request = false
where role_request is null;

-- ==========================================
-- SECTION 2: REPLACE GUARD TRIGGER LOGIC
-- ==========================================

create or replace function public.guard_profile_privileged_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Self updates are allowed, with strict safeguards.
  if auth.uid() = old.id then
    -- Users can never self-change role.
    if new.role is distinct from old.role then
      raise exception 'Only admins can update role fields.' using errcode = '42501';
    end if;

    -- Users can request executive access once (false -> true).
    if new.role_request is distinct from old.role_request then
      if old.role_request = false and new.role_request = true then
        return new;
      end if;

      -- Controlled withdrawal is allowed only through RPC context flag.
      if old.role_request = true
         and new.role_request = false
         and current_setting('request_context.allow_role_request_withdraw', true) = 'true' then
        return new;
      end if;

      raise exception 'Invalid role request mutation. Use the dedicated request/withdraw flow.' using errcode = '42501';
    end if;

    return new;
  end if;

  -- Non-self updates require admin privileges.
  if not public.is_admin(auth.uid()) then
    raise exception 'Only admins can update other user profiles.' using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_profile_privileged_fields on public.profiles;

create trigger trg_guard_profile_privileged_fields
before update on public.profiles
for each row
execute function public.guard_profile_privileged_fields();

-- ==========================================
-- SECTION 3: REQUEST / WITHDRAW RPCS
-- ==========================================

create or replace function public.request_executive_access()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  update public.profiles
  set role_request = true
  where id = auth.uid()
    and role = 'student'
    and role_request = false;

  if not found then
    raise exception 'Request not allowed. You may already have a pending request or elevated role.';
  end if;
end;
$$;

create or replace function public.withdraw_executive_request()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  perform set_config('request_context.allow_role_request_withdraw', 'true', true);

  update public.profiles
  set role_request = false
  where id = auth.uid()
    and role = 'student'
    and role_request = true;

  if not found then
    raise exception 'No pending executive request to withdraw.';
  end if;
end;
$$;

revoke all on function public.request_executive_access() from public;
revoke all on function public.withdraw_executive_request() from public;

grant execute on function public.request_executive_access() to authenticated;
grant execute on function public.withdraw_executive_request() to authenticated;
