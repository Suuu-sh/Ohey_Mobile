# Ohey

Ohey（オーヘイ）is a Flutter prototype for a cozy, overseas-app-inspired social planning app.
It focuses on cute friend availability, invites, and lightweight photo sharing.

## Highlights

- Pastel, iOS-native-feeling UI with soft cards, rounded corners, and gentle shadows
- Original placeholder character assets: **Ohey Friends**
- Character mood changes from the current month memory count
  - 0: さみしい
  - 1–2: にこにこ
  - 3–5: たのしい
  - 6+: ハイテンション
- Home feed, friends, calendar, profile, invites, yurubo, and wish list screens
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
    yurubos/
    friends/
    calendar/
assets/
  characters/
```

## Backend

Auth stays in Flutter via Supabase Auth. Memories, invites, and friend reads go through the Go backend.

Dev / iOS Simulator builds must use the shared dev environment:

- Supabase: `dev-ohey`
- Backend: `https://dev-ohey-backend.onrender.com`
- Auth redirect scheme: `app.ohey.com.dev://login-callback/`

Use the shared script so local values do not drift:

```sh
./scripts/run_dev_render.sh
```

`./scripts/run_dev_local.sh` is intentionally deprecated and delegates to the dev Render backend. Do not point Simulator verification at `localhost:8080`.

For prod/TestFlight builds, set `OHEY_BACKEND_URL=https://ohey-backend.onrender.com`. Public non-secret environment defaults are centralized in `lib/core/config/ohey_environment.dart` and `scripts/ohey_env.sh`.

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

- dev iOS bundle ID: `app.ohey.com` with dev Firebase project and `app.ohey.com.dev` URL scheme
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
./scripts/run_dev_render.sh --dart-define-from-file=config/firebase/dev.json
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
