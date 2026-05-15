# Supabase migration deployment

NomoのDBスキーマ変更は必ず `supabase/migrations/*.sql` に追加します。

- PR時: migrationファイル名を検証します。
- mainマージ時: GitHub Actionsがproduction Supabaseへ未適用migrationを順番に適用します。
- 適用済みmigrationはproduction DBの `public.app_schema_migrations` で管理します。

## Required GitHub secret

Mobile repository or `production` environmentに以下を設定してください。

- `SUPABASE_PRODUCTION_DATABASE_URL`
  - Supabase production project `nomo` のPostgreSQL connection string
  - 例: `postgresql://postgres.<project-ref>:<password>@aws-...pooler.supabase.com:6543/postgres?sslmode=require`

破壊的なmigration（DROP、型変更、巨大テーブルへのNOT NULL/UNIQUE追加、RLS大幅変更）は、PRで明示レビューしてからmainへマージしてください。
