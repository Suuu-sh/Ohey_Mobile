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


## Firebase/FCM dev and prod setup

Nomo supports separate Firebase values for dev and prod. Keep filled config files out of git.

Recommended Firebase apps:

- dev iOS bundle ID: `app.nomo.nomo.dev`
- prod iOS bundle ID: `app.nomo.nomo`
- dev Android application ID: `app.nomo.nomo.dev`
- prod Android application ID: `app.nomo.nomo`

Prepare local dart-define files:

```sh
cp config/firebase/dev.json.example config/firebase/dev.json
cp config/firebase/prod.json.example config/firebase/prod.json
# Fill FIREBASE_* / SUPABASE_* values from Firebase and Supabase.
```

Run dev builds with:

```sh
flutter run --dart-define-from-file=config/firebase/dev.json
```

Run prod/TestFlight values with:

```sh
flutter build ios --release --dart-define-from-file=config/firebase/prod.json
flutter build appbundle --flavor prod --dart-define-from-file=config/firebase/prod.json
```

If you prefer native Firebase config files instead of dart-defines, place them at:

- `ios/firebase/dev/GoogleService-Info.plist`
- `ios/firebase/prod/GoogleService-Info.plist`
- `android/app/src/dev/google-services.json`
- `android/app/src/prod/google-services.json`

The backend also needs matching environment-specific `FCM_SERVICE_ACCOUNT_JSON` values. Store operational copies under `/Users/yota/Projects/Secrets/Nomo` and set them in the dev/prod backend environments.
