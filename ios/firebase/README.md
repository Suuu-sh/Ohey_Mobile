# Firebase iOS config files

Place Firebase iOS config files here when using native Firebase files instead of `--dart-define-from-file`:

- `ios/firebase/dev/GoogleService-Info.plist` for dev (`app.ohey.com`, using the dev Firebase project and `app.ohey.com.dev` URL scheme)
- `ios/firebase/prod/GoogleService-Info.plist` for prod/TestFlight (`app.ohey.com`)

The current app can also initialize Firebase from dart-defines, so these files are optional if `FIREBASE_*` values are supplied by `--dart-define-from-file`.
