# Nomo dev Supabase seeds

These files are for the `dev-nomo` Supabase project only. Do not apply them to production.

- `seed_dev_auth_users.sql`: creates confirmed test auth users, profiles, and real `friendships` rows in the database.
- `seed_dev_rich_data.sql`: creates a broader dev dataset with 10 confirmed users, varied friendship/request states, all daily status patterns, current/previous-month memories, memory tagged users, likes, and one report sample.
- The Flutter app should not use JSON/hardcoded fallback friends. If a dev account has no friends, seed the dev database with `seed_dev_auth_users.sql` instead of adding app-side dummy data.

Before running either seed SQL file, set a local-only seed password in the SQL session:

```sql
select set_config('app.seed_password', '<local-dev-password>', false);
\i supabase/dev/seed_dev_auth_users.sql
```

Do not commit real dev or production passwords. Use `seed_dev_rich_data.sql` when you want UI test data for feed/friends/calendar edge cases.

Current dev DB check: `dev-yuta@nomo.app` has 4 friendship rows, so no existing DB data was deleted or replaced.
