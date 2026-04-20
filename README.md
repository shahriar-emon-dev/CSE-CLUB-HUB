# CSE Club Hub

Production-ready Flutter authentication starter using Supabase, Riverpod, and GoRouter.

## Stack

- Flutter (stable)
- Riverpod (`flutter_riverpod`)
- GoRouter (`go_router`)
- Supabase Auth (`supabase_flutter`)

## Architecture

Feature-first, clean architecture layout:

```text
lib/
  app.dart
  main.dart
  core/
    config/
      env_config.dart
    constants/
      app_colors.dart
      app_routes.dart
    errors/
      app_exception.dart
    router/
      app_router.dart
    validation/
      input_validators.dart
  features/
    auth/
      data/
        repositories/
          auth_repository_impl.dart
        services/
          supabase_auth_service.dart
      domain/
        entities/
          user_profile.dart
        repositories/
          auth_repository.dart
      presentation/
        controllers/
          auth_notifier.dart
        providers/
          auth_providers.dart
        screens/
          login_screen.dart
          profile_setup_screen.dart
          signup_screen.dart
          splash_screen.dart
        state/
          auth_state.dart
    home/
      presentation/
        screens/
          home_screen.dart
  shared/
    widgets/
      auth_text_field.dart
      primary_button.dart
```

## Supabase Setup

1. Create a Supabase project.
2. Apply the migration in `supabase/migrations/20260411_week1_auth.sql`.

This migration includes:

- `profiles` schema
- auto profile creation trigger from `auth.users`
- production RLS policies (self-access + admin controls)
- indexes for `email` and `role`

If needed, the main table shape is:

```sql
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text,
  student_id text,
  batch text,
  section text,
  department text not null default 'CSE',
  avatar_url text,
  role text not null default 'student',
  role_request boolean not null default false,
  created_at timestamptz not null default now()
);
```

1. Authentication settings:

- Enable Email provider.
- Optionally disable email confirmation for faster local testing.

1. Get project credentials from Supabase dashboard:

- Project URL
- Anon key

## Run Locally

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

### Windows PowerShell

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

### Recommended: use a local define file

```bash
flutter run -d chrome --dart-define-from-file=.env/dev.json
```

Create `.env/dev.json` from `.env/example.json` and set your real values before running.

## Included Auth Features

- Signup with email + password
- Controlled signup account type:
  - `Student` (default)
  - `Request Executive Access` (approval required)
- Login with email + password
- Logout
- Persistent session handling through Supabase auth session recovery
- University email validation (`@smuct.edu` or `@smuct.ac.bd`)
- Profile completion flow for `full_name`, `student_id`, `batch`, `section`
- Role fetch from `profiles` and role-aware home behavior
- Auth-aware route guards (Splash/Login/Signup/Profile Setup/Home)

## Role Security Model

- Client can only request executive access via `role_request = true`.
- Client cannot assign `executive` or `admin` role directly.
- `role` defaults to `student` on signup and trigger path.
- Admin approves or rejects requests by updating `role` and clearing `role_request`.

## Notes For Production

- Keep Supabase keys in CI/CD secrets and inject via `--dart-define`.
- Add crash reporting/logging (Sentry/OpenTelemetry) for runtime observability.
- Consider email verification + password reset screens for full auth lifecycle.
