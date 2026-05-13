# Nomo

Nomo is a Flutter prototype for a cozy, overseas-app-inspired drinking log SNS.
It focuses on cute memories with friends: “who did I drink with this month, and how many times?”

## Highlights

- Pastel, iOS-native-feeling UI with soft cards, rounded corners, and gentle shadows
- Original placeholder character assets: **Nomo Friends**
- Character mood changes from the current month drink count
  - 0: さみしい
  - 1–2: にこにこ
  - 3–5: たのしい
  - 6+: ハイテンション
- Home, add log, friends, and calendar screens
- Riverpod state management
- Repository Pattern with Flutter → Go Backend → Supabase for app data
- Feature First Architecture under `lib/features/*`

## Structure

```text
lib/
  core/
    models/
    theme/
    widgets/
  features/
    home/
    logs/
    friends/
    calendar/
assets/
  characters/
```

## Backend

Auth stays in Flutter via Supabase Auth. Drink logs and friend reads now go through the Go backend.

Local backend:

```sh
cd /Users/yota/Projects/Products/Nomo/Backend
set -a; source /Users/yota/Projects/Secrets/Nomo/backend_dev.env; set +a
go run ./cmd/api
```

Run Flutter against it:

```sh
flutter run --dart-define=NOMO_BACKEND_URL=http://localhost:8080
```

For Render/prod builds, set `NOMO_BACKEND_URL=https://nomo-backend-nezf.onrender.com`.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
dart format lib test
flutter analyze
flutter test
```
## Supabase

The app initializes `supabase_flutter` on startup. Local debug runs default to the `dev-nomo` Supabase project through `/Users/yota/Projects/Products/Nomo/Mobile/lib/core/config/supabase_config.dart`.

Override environment values with `--dart-define` for production/release builds. See `/Users/yota/Projects/Products/Nomo/Mobile/docs/supabase_nomo.md`.
