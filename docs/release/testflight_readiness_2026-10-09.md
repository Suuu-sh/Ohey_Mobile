# TestFlight readiness follow-up

As of: 2026-10-09

Scope: internal TestFlight verification only. No public App Store submission or
App Review submission was performed or authorized.

## Verified in this follow-up

- The Mobile app-code baseline was `c08e1a5` on `development`; workflow and
  readiness-document updates from this follow-up have been pushed to
  `origin/development`. Backend is on `development` at `c7838fd`
  (`origin/development`). Both repositories were fetched before work; neither
  had incoming commits.
- `flutter analyze` passed and `flutter test` passed (50 tests).
- Backend `go test ./...` passed on `c7838fd`. Read-only `/health` requests to
  both the dev and production Render backends returned HTTP 200; these are
  liveness checks, not authenticated end-to-end verification.
- `plutil -lint ios/Runner/PrivacyInfo.xcprivacy` passed.
- The dev launch script built and launched Ohey in iPhone 17 Simulator
  (iOS 26.3), using the configured dev Render backend. The app reached its
  re-login UI. No account was selected and no authentication was attempted.
- The Render Production dashboard reports `ohey-backend` as Live at commit
  `c7838fd0ba14fb4bded3736ac9bc6ea1e0dc293e` (deployed about two days before
  this check). A read-only GET to
  `https://ohey-backend.onrender.com/health` returned HTTP 200 (`status: ok`).
  The dashboard shows the production service connected to the `development`
  branch; confirm this is intentional before future production promotions.
- Earlier TestFlight run
  [37570161335](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/37570161335)
  completed its archive, upload, and internal tester-assignment steps for
  `c388411`. That commit includes the Apple authentication timeout fix, but it
  is older than current `development` (`c08e1a5` at the time of that run).
  The workflow success does not prove the reported iPad symptom is fixed or
  that a tester installed the build.
- The current TestFlight workflow now validates that the archived app contains
  a valid `PrivacyInfo.xcprivacy`, and briefly retains the archive as a
  one-day GitHub Actions artifact so Xcode Organizer can generate the
  aggregated privacy report.

## Current blockers

- Dispatch [37883462509](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/37883462509)
  for workflow commit `573023c` (with app source at `c08e1a5`) was blocked before
  a runner or workflow step started. GitHub reports an account payment failure
  or spending limit. No archive, upload, or new TestFlight build was produced.
  After GitHub Actions billing is restored, rerun this workflow to build the
  current application source; subsequent pushes only changed readiness docs.
- The Apple Sign In timeout change from `a8ea58b` is present and its timeout
  regression tests pass. The actual native white-screen report has not been
  reproduced or cleared on iPad Air 11-inch (M3); a simulator/unit test is not
  equivalent to testing that device and iPadOS version.
- `app_privacy.md` was last verified against source on 2026-07-14. Its App
  Store Connect answer says Device ID is used for tracking, while the
  first-party manifest declares Device ID as not used for tracking and
  `NSPrivacyTracking = false`. Third-party SDK manifests may explain part of
  this difference, so do not change the declaration based on the first-party
  manifest alone. Reconcile the actual archived Xcode privacy report with the
  App Store Connect answers before public submission.
- App Store Connect app `6774577603` has a recorded v1.0 rejection on June 9,
  but the rejection reason / guideline is not in the repository. App Store
  Connect currently requires an authenticated session to read the resolution
  details.
- The approved iPhone 14 has not been verified with the candidate build. The
  affected iPad Apple Sign In flow, user consent/ATT paths, and end-to-end
  account scenarios remain device/account-dependent.
- `QA.md` contains 169 checklist items; 18 are checked. The multi-user,
  failure/retry, invitation, delete, advertising-consent, and purchase flows
  still need their stated dev/test-account verification.

## Next actions

1. Restore GitHub Actions billing / spending capacity, then rerun TestFlight
   run `37883462509` (or dispatch the workflow on the current `development`).
2. Download the short-retention archive artifact, generate its Xcode Organizer
   privacy report, and reconcile first-party + SDK declarations with
   `app_privacy.md` and App Store Connect.
3. Sign in to App Store Connect in the browser and record the v1.0 rejection
   guideline and resolution details. Do not submit a new public review yet.
4. Install the resulting internal build on the approved iPhone 14 and test
   Apple sign-in, cancellation/retry, consent/ATT, and the priority QA flows.
   Also retest the reported iPad Air 11-inch (M3) configuration if available.
5. Confirm the Render Production service's use of the `development` branch is
   intentional; the current deployed SHA is recorded above. Do not paste
   Render tokens into chat.

Public App Store release remains a separate, not-yet-authorized action.
