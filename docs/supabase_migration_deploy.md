# Supabase migration deployment

Last updated: 2026-05-28

Ohey の Supabase schema は pre-release 中に破壊的に整理済み。現時点の正本は `supabase/migrations/20260528230000_ohey_clean_baseline.sql` の **single clean baseline** です。

## 方針

- `drink_*` 時代の累積 migration は残さない。
- dev / production ともテストデータ扱いなので、baseline は app-owned tables を drop/recreate する。
- `public.app_schema_migrations` は Suuu-sh/Shared の GitHub Actions migration runner が使う独自履歴。baseline の最後で既存履歴を削除し、workflow が baseline 1件だけを記録する。
- Storage object は SQL で削除しない。Supabase Storage API / dashboard / `scripts/ohey_storage_cleanup.py` を使う。

メリット:

- 将来の AI agent / 開発者が古い `drink_logs` / `drink_invites` の設計に引っ張られない。
- migration history が 1ファイルになり、RLS / GRANT / Storage policy の最終形をレビューしやすい。
- dev/prod が同じ schema baseline から始まるので、TestFlight だけ壊れる事故を減らせる。

デメリット / 注意:

- 既存 app data は消える。公開後はこの運用に戻さない。
- baseline の適用に失敗すると途中 schema が壊れる可能性があるため、local dry-run / dev workflow / runtime check を通してから production に入れる。
- Storage object は DB reset では消えないため、別途 cleanup が必要。

## GitHub Actions 適用ルール

- `development` push: dev Supabase migration workflow が dev-ohey に適用する。
- `main` push: production Supabase migration workflow が ohey に適用する。
- runner は `public.app_schema_migrations(version, name, applied_at)` を見て未適用 SQL を順番に実行する。

## Required GitHub secrets

Mobile repository の Actions secret:

- `SUPABASE_DEV_DATABASE_URL`
- `SUPABASE_PRODUCTION_DATABASE_URL`

値は `/Users/yota/Projects/Secrets/Nomo` に保存している。secret 値は repo / docs に書かない。

## Local static verification

```bash
cd /Users/yota/Projects/Products/Nomo/Mobile
python3 scripts/verify_supabase_rls_contract.py
```

確認すること:

- migration file は baseline 1件のみ。
- user-facing table は RLS enabled。
- owner / participant scope の policy がある。
- `notification_outbox` は `anon` / `authenticated` に開けず、`service_role` only。
- `drink_*` table/policy/grant を再作成していない。
- `private.*` trigger/helper function を使い、RLS helper を exposed `public` function に戻していない。

## Runtime RLS / GRANT verification

Supabase は 2026-04-28 以降、新規 project / 設定によって `public` tables が Data API / GraphQL API に自動公開されない挙動を opt-in できる。そのため RLS だけでなく **GRANT / Data API 到達性** も runtime で確認する。

```bash
cd /Users/yota/Projects/Products/Nomo/Mobile
SUPABASE_URL=... \
SUPABASE_PUBLISHABLE_KEY=... \
SUPABASE_SERVICE_ROLE_KEY=... \
OHEY_SMOKE_EMAIL=dev-yuta@ohey.app \
OHEY_SMOKE_PASSWORD=... \
python3 scripts/ohey_supabase_runtime_check.py
```

期待値:

- `anon` は `profiles` を読めない。
- authenticated user は `profiles` / `memories` / `invites` / safety tables を Data API 経由で読める。
- authenticated user は `notification_outbox` を読めない。
- service role は required tables に到達できる。
- removed legacy tables (`drink_logs`, `drink_invites`, `drink_log_reports`, `feed_hidden_drink_logs`) は Data API で missing になる。

## Backend smoke scripts

Dev Render backend:

```bash
cd /Users/yota/Projects/Products/Nomo/Mobile
OHEY_BACKEND_URL=https://dev-ohey-backend.onrender.com \
SUPABASE_URL=... \
SUPABASE_PUBLISHABLE_KEY=... \
OHEY_SMOKE_EMAIL=dev-yuta@ohey.app \
OHEY_SMOKE_PASSWORD=... \
python3 scripts/ohey_backend_smoke.py --mutating
```

Invite flow まで見る場合:

```bash
OHEY_SMOKE_OTHER_EMAIL=dev-ken@ohey.app \
OHEY_SMOKE_OTHER_PASSWORD=... \
python3 scripts/ohey_backend_smoke.py --mutating --invite
```

Production backend も同じ script を使う。ただし TestFlight / production user への影響を避けるため、production では専用 smoke account を用意してから `--mutating` を使う。

## Storage object cleanup

Supabase 公式 docs は Storage object の削除を SQL ではなく Storage API 経由にするよう明記している。DB reset 後に object を消す場合:

```bash
cd /Users/yota/Projects/Products/Nomo/Mobile
SUPABASE_URL=... \
SUPABASE_SERVICE_ROLE_KEY=... \
python3 scripts/ohey_storage_cleanup.py --bucket ohey-photos --prefix users

# 確認後に実削除
python3 scripts/ohey_storage_cleanup.py --bucket ohey-photos --prefix users --execute
```

`--execute` を付けない限り dry-run。
