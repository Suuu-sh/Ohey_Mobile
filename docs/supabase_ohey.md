# Ohey Supabase Setup

## Production-like project

- name: `ohey`
- ref: `pwifgddolctqghygwxwj`
- URL: `https://pwifgddolctqghygwxwj.supabase.co`
- region: `ap-northeast-1`

## Local development project

Local Flutter runs default to this project.

- name: `dev-nomo`
- ref: `wwyaftonswgxnjcceyfb`
- URL: `https://wwyaftonswgxnjcceyfb.supabase.co`
- region: `ap-northeast-1`

Local config is in:

- `/Users/yota/Projects/Products/Nomo/Mobile/lib/core/config/supabase_config.dart`
- `/Users/yota/Projects/Products/Nomo/Mobile/.env.local` (gitignored)
- secrets backup: `/Users/yota/Projects/Secrets/Nomo/supabase_dev-nomo.md`

Run locally with the default dev-nomo values:

```sh
flutter run
```

Or pass values explicitly:

```sh
flutter run \
  --dart-define=OHEY_ENV=local \
  --dart-define=SUPABASE_URL=https://wwyaftonswgxnjcceyfb.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<dev-nomo publishable key> \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=app.ohey.ohey://login-callback/
```

Production/release builds should override `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` with the `ohey` project values.

## Configured database/Auth/storage

Both `ohey` and `dev-nomo` are kept on the same app schema:

- Supabase Auth profile trigger
- `profiles`
- `friend_requests`
- `friendships`
- `daily_statuses`
- `memories`
- `memory_tagged_users`
- `memory_likes`
- `memory_reports`
- `memory_hides`
- `invites`
- RLS policies for authenticated users
- private Storage bucket: `ohey-photos`

Auth callback URL:

```text
app.ohey.ohey://login-callback/
```

## Important: dev and production must stay separate

`ohey` Supabase and `ohey-backend` are production resources. Do not use them for local/dev checks.
Dev/Simulator must use `dev-nomo` Supabase and the `dev-nomo-backend` Render backend.

If Flutter and the backend point to different Supabase projects, PostgREST returns:

```text
PGRST301: No suitable key was found or wrong key type
```

Use these scripts to avoid mismatched JWTs:

```sh
# Dev simulator run: dev-nomo Supabase + dev Render backend
./scripts/run_dev_render.sh -d <simulator-id>

# Historical local-backend scripts may exist, but Ohey dev/Simulator checks should use dev Render backend.
```
