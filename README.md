# Ohey

Ohey（オーヘイ）is a Flutter prototype for a cozy, overseas-app-inspired social memory app.
It focuses on cute memories, friend availability, invites, and lightweight photo sharing.

## Highlights

- Pastel, iOS-native-feeling UI with soft cards, rounded corners, and gentle shadows
- Original placeholder character assets: **Ohey Friends**
- Character mood changes from the current month memory count
  - 0: さみしい
  - 1–2: にこにこ
  - 3–5: たのしい
  - 6+: ハイテンション
- Home, add memory, friends, and calendar screens
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
    memories/
    friends/
    calendar/
assets/
  characters/
```

## Backend

Auth stays in Flutter via Supabase Auth. Memories, invites, and friend reads go through the Go backend.

Local backend:

```sh
cd /Users/yota/Projects/Products/Ohey/Backend
set -a; source /Users/yota/Projects/Secrets/Ohey/backend_dev.env; set +a
go run ./cmd/api
```

Run Flutter against it:

```sh
flutter run --dart-define=OHEY_BACKEND_URL=https://dev-ohey-backend.onrender.com
```

For prod builds, set `OHEY_BACKEND_URL=https://ohey-backend.onrender.com`. For dev/Simulator use `https://dev-ohey-backend.onrender.com`. Render service display names are `ohey-backend` / `dev-ohey-backend`; the generated hostnames are Ohey slugs.

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

The app initializes `supabase_flutter` on startup. Local debug runs default to the `dev-ohey` Supabase project through `/Users/yota/Projects/Products/Ohey/Mobile/lib/core/config/supabase_config.dart`.

Override environment values with `--dart-define` for production/release builds. See `/Users/yota/Projects/Products/Ohey/Mobile/docs/supabase_ohey.md`.


## Firebase/FCM dev and prod setup

Ohey supports separate Firebase values for dev and prod. Keep filled config files out of git.

Recommended Firebase apps:

- dev iOS bundle ID: `app.ohey.com.dev`
- prod iOS bundle ID: `app.ohey.com`
- dev Android application ID: `app.ohey.com.dev`
- prod Android application ID: `app.ohey.com`

Prepare local dart-define files:

```sh
cp config/firebase/dev.json.example config/firebase/dev.json
cp config/firebase/prod.json.example config/firebase/prod.json
# Fill FIREBASE_* / SUPABASE_* / OHEY_* values from Firebase, Supabase, and secrets.
dart scripts/check_dart_define_keys.dart config/firebase/dev.json config/firebase/prod.json
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

The backend also needs matching environment-specific `FCM_SERVICE_ACCOUNT_JSON` values. Store operational copies under `/Users/yota/Projects/Secrets/Ohey` and set them in the dev/prod backend environments.
