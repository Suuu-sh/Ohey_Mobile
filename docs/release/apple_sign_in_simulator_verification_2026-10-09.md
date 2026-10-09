# Apple Sign-In Simulator Verification — 2026-10-09

## Environment

- Device: iPad Air 11-inch (M3) Simulator
- OS: iPadOS 26.5
- Mobile branch / commit: `development` / `1067a48`
- Mode: Flutter debug UI Preview, signed out (`OHEY_UI_PREVIEW=true`, `OHEY_UI_PREVIEW_SIGNED_OUT=true`)
- Apple Account: not signed in on this Simulator

UI Preview was used to reach the sign-in screen without presenting the debug AdMob consent flow. The Apple button still opened the native iOS Sign in with Apple flow; the preview does not provide an Apple Account or verify the Clerk/backend exchange.

## Steps and results

1. Started Ohey on the iPadOS 26.5 Simulator and skipped onboarding. The sign-in screen rendered.
2. Selected **Appleでログイン**. iOS displayed its native alert explaining that an Apple Account must be signed in through Settings.
3. Closed the alert. Ohey returned to the sign-in screen, cleared the loading indicator, and displayed its inline error (`Apple認証で不明なエラーが発生しました。`).
4. Retried Apple Sign-In and closed the same alert again. The screen returned to the same usable state; it did not remain blank or stuck loading.

## Conclusion and limits

- **Passed:** On this no-Apple-Account path, the native alert can be dismissed and the app recovers to an interactive sign-in screen. No white/blank screen was observed after dismissal.
- **Not verified:** Successful Apple Account authentication, Clerk token exchange, account creation, or the original reviewer’s authenticated path. The Simulator has no Apple Account, so this does **not** establish that the reported App Review issue is resolved.
- **Release status:** This is a Simulator UI check, not a TestFlight install or App Store approval. Do not treat it as authorization to submit v1.0.
