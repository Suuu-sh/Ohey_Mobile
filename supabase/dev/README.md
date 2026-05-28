# Tomo dev Supabase seeds

These files are for the `dev-nomo` Supabase project only. Do not apply them to production.

## Files

- `seed_dev_auth_users.sql`: creates 5 confirmed auth users, profiles, and baseline friendship rows.
- `seed_dev_rich_data.sql`: creates 10 confirmed users plus richer memories/invites/friends/calendar/safety data for UI checks.

Both seed files assume the clean baseline schema is already applied. They must not create tables, policies, grants, or compatibility schema.

## Password handling

Before running either seed SQL file, set a local-only seed password in the SQL session:

```sql
select set_config('app.seed_password', '<local-dev-password>', false);
\i supabase/dev/seed_dev_auth_users.sql
```

Do not commit real dev or production passwords. Reusable seed credentials are documented only under `/Users/yota/Projects/Secrets/Nomo`.

## Fixed dev users

Primary smoke users:

- `dev-yuta@tomo.app`
- `dev-ken@tomo.app`
- `dev-ryo@tomo.app`
- `dev-haru@tomo.app`
- `dev-takumi@tomo.app`

Rich seed additionally creates `dev-mika`, `dev-ren`, `dev-saki`, `dev-ana`, and `dev-kai` accounts.

## Admin account policy

Admin access is not seeded through special DB roles. Backend admin endpoints authenticate a normal Supabase Auth user and authorize by `TOMO_ADMIN_EMAILS` configured in Render. Keep admin email configuration in Render/secrets, not in seed SQL.

## No app-side fallback data

The Flutter app should not use JSON/hardcoded fallback friends. If a dev account has no friends, seed the dev database instead of adding app-side dummy data.
