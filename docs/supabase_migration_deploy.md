# Supabase migration deployment

NomoのDBスキーマ変更は必ず `supabase/migrations/*.sql` に追加します。

- PR時: migrationファイル名を検証します。
- mainマージ時: GitHub Actionsがproduction Supabaseへ未適用migrationを順番に適用します。
- 適用済みmigrationはproduction DBの `public.app_schema_migrations` で管理します。

## Required GitHub secret

Mobile repositoryのActions secretに以下を設定してください。

- `SUPABASE_PRODUCTION_DATABASE_URL`
  - Supabase production project `nomo` のPostgreSQL connection string
  - 例: `postgresql://postgres.<project-ref>:<password>@aws-...pooler.supabase.com:6543/postgres?sslmode=require`

破壊的なmigration（DROP、型変更、巨大テーブルへのNOT NULL/UNIQUE追加、RLS大幅変更）は、PRで明示レビューしてからmainへマージしてください。

## Local verification before applying production

本番適用前に、少なくとも static contract check を通す。

```bash
python3 scripts/verify_supabase_rls_contract.py
```

この check は migration を DB に適用しない。以下の RLS / grant contract を壊していないかを確認する。

- `friend_groups`
- `friend_group_members`
- `drink_log_reports`
- `notification_outbox`
- `user_blocks`
- `user_mutes`
- `feed_hidden_drink_logs`
- `push_tokens`

特に確認すること:

- exposed schema の user-facing table は RLS enabled
- owner / participant scope の policy がある
- `notification_outbox` は `anon` / `authenticated` に開けず、`service_role` only
- moderation columns は `reason` / `status` constraint を持つ

Supabase CLI が使える環境では GitHub Actions と同じ workflow で dev DB に先に適用し、production は main merge / manual workflow で適用する。
