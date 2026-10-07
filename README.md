# Ohey

Ohey（オーヘイ）is a Flutter social-planning app for sharing availability,
invites, yurubo posts, and wish lists with friends.

## Highlights

- Pastel, iOS-native-feeling UI with soft cards, rounded corners, and gentle shadows
- Original placeholder character assets: **Ohey Friends**
- Friend availability, invites, yurubo, and wish list flows
- Home, friends, calendar, profile, invites, yurubo, and wish list screens
- Riverpod state management
- Repository Pattern with Flutter → Go Backend → Clerk + Neon-backed APIs
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

Auth uses Clerk in Flutter. App data goes through the Go backend backed by Neon/Postgres.

Dev / iOS Simulator builds must use the shared dev environment:

- Backend: `https://dev-ohey-backend.onrender.com`
- Auth redirect scheme: `app.ohey.com.dev://login-callback/`

Use the shared script so local values do not drift:

```sh
./scripts/run_dev_render.sh
```

`./scripts/run_dev_local.sh` is intentionally deprecated and delegates to the dev Render backend. Do not point Simulator verification at `localhost:8080`.

For prod/TestFlight builds, set `OHEY_BACKEND_URL=https://api.oheyapp.com`; this hostname is served through the shared Cloudflare `shared-api-proxy` route and forwards to the production Render backend. Public non-secret environment defaults are centralized in `lib/core/config/ohey_environment.dart` and `scripts/ohey_env.sh`.

## Run on iOS Simulator

```sh
./scripts/run_dev_render.sh -d <simulator-id>
```

### UI preview mode (no login)

To review screens without signing in, run the debug-only preview mode. The app
starts signed in as a fixture user and answers every backend call from memory
(`lib/core/preview/`), so no Clerk account, backend, or network is used:

```sh
./scripts/run_ui_preview.sh -d <simulator-id>
```

Prefix it with `OHEY_UI_PREVIEW_SIGNED_OUT=true` to start signed out and review
the login/onboarding flow. The flags are ignored in release builds. Use the dev Render
script above for anything that must hit the real API.

Simulator builds must use Clerk dev, Neon dev, and the dev Render backend. Never
point a Simulator build at localhost or production.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
plutil -lint ios/Runner/Info.plist ios/Runner/PrivacyInfo.xcprivacy
```
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
# Fill FIREBASE_* / CLERK_* / OHEY_* values from Firebase, Clerk, backend, and secrets.
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

Before distribution, reconcile Xcode's archived privacy report with
[`docs/release/app_privacy.md`](docs/release/app_privacy.md), run the Backend
production release runbook, and review [`SECURITY.md`](SECURITY.md). Signed
TestFlight builds must come from the protected GitHub environment rather than a
developer-local archive.
