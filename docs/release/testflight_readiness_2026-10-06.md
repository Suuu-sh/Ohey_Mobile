# TestFlight readiness record

As of: 2026-10-06  
Scope: internal TestFlight preparation only. No public release or App Review
submission was authorized or performed.

## Passed / observed

- Mobile source reviewed at `ed519e7`; CI run
  [37479016565](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/37479016565)
  completed successfully.
- Backend source CI run `37466958811` for `c7838fd` completed successfully.
- Production proxy checks using the native Dart user agent returned health
  `200`, protected API `401` (expected without credentials), and legal `200`.
- Production configuration key-name presence and TestFlight workflow guards
  were reviewed. Secret values were not inspected or recorded.
- The existing TestFlight build `20260607023929` had a reported Apple sign-in
  white screen on iPad Air 11-inch (M3), iPadOS 26.5.
- A production Python-default-user-agent probe returned `403` / BIC 1010. This
  is a proxy/WAF user-agent difference, not evidence of an app defect.

## Pending / unresolved

- Mobile TestFlight workflow run
  [37480877707](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/37480877707)
  for `ed519e7` was cancelled before archive creation so a narrow Apple
  sign-in timeout fix can be incorporated. It did not produce a new build.
- Apple availability and Clerk ID-token requests now have bounded waits.
  Targeted analyze and both timeout regression tests passed; this does not
  establish that the rejected native white-screen symptom is resolved.
- Latest previously uploaded TestFlight build `20260630053711` is expired.
- Privacy declarations have not been reconciled against an actual archived
  build's aggregated Xcode privacy report. This remains required before any
  App Store submission.
- App Store Connect app `6774577603` currently has v1.0 rejected (June 9).
  No new build review or public submission has occurred.
- An approved iPhone 14 is available, but Ohey is not installed in TestFlight
  on it. Two email addresses are authorized for production QA account setup,
  but registration and user-operated consent remain pending. Bluetooth is off,
  preventing screen mirroring. Device and authenticated-flow verification
  remain pending.
- The Render access token expired, so the deployed production SHA could not be
  verified.

## Next verification boundary

Re-run the guarded internal TestFlight workflow after the Apple sign-in timeout
fix is incorporated, confirm archive privacy metadata, then perform authorized
device and account checks. Keep public submission/App Review separate and do
not initiate it without explicit authorization.
