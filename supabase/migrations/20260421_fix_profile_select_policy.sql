alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Authenticated users can view all profiles" on public.profiles;

create policy "Users can view own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

do $$
declare
  has_user_id boolean;
begin
  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'user_id'
  ) into has_user_id;

  if has_user_id then
    execute 'drop policy if exists "Users can view own profile" on public.profiles';
    execute '
      create policy "Users can view own profile"
      on public.profiles
      for select
      to authenticated
      using (auth.uid() = id or auth.uid() = user_id)
    ';
  end if;
end
$$;

create policy "Authenticated users can view all profiles"
on public.profiles
for select
to authenticated
using (auth.role() = 'authenticated');
