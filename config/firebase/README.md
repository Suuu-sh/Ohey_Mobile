# Firebase dev/prod dart-define files

Copy the examples and fill values from Firebase Console:

```sh
cp config/firebase/dev.json.example config/firebase/dev.json
cp config/firebase/prod.json.example config/firebase/prod.json
```

Run dev:

```sh
flutter run --dart-define-from-file=config/firebase/dev.json
```

Build prod/TestFlight-style values:

```sh
flutter build ios --release --dart-define-from-file=config/firebase/prod.json
flutter build appbundle --flavor prod --dart-define-from-file=config/firebase/prod.json
```

Do not commit filled `*.json` files; commit only `*.json.example`.
