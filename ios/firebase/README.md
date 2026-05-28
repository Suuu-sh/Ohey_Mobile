# Firebase iOS config files

Place Firebase iOS config files here when using native Firebase files instead of `--dart-define-from-file`:

- `ios/firebase/dev/GoogleService-Info.plist` for dev (`app.ohey.ohey.dev`)
- `ios/firebase/prod/GoogleService-Info.plist` for prod/TestFlight (`app.ohey.ohey`)

The current app can also initialize Firebase from dart-defines, so these files are optional if `FIREBASE_*` values are supplied by `--dart-define-from-file`.
