# TestFlight readiness follow-up

As of: 2026-10-09

Scope: internal TestFlight verification only. The repository is public by user
request; no public App Store submission or App Review submission was performed
or authorized.

## Update 2026-10-10 — development Apple sign-in

- Apple sign-in succeeded in the iPad Air 11-inch (M3) Simulator on iOS 26.5
  and reached the authenticated Friends screen. This supersedes the earlier
  note below that no account login was attempted.
- The development Clerk instance has Apple sign-in enabled, the iOS app
  registered (`83J5SB3ZPX` / `app.ohey.com`), and the `ohey-mobile` JWT
  template. This confirms the development Simulator path only; it does not
  verify production Clerk, a TestFlight-installed build, or the reported
  physical-device white-screen symptom.
- The internal TestFlight build `20261009143943` remains the latest recorded
  processed and assigned build. No new upload or public App Store submission
  was performed.

## Update 2026-10-10 — CI, production backend, and remaining access gates

- Safe Apple-auth diagnostics and this readiness update were committed to
  `development` as `0cdd700` and pushed. GitHub Actions run
  [38050634734](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/38050634734)
  passed both Flutter analyze and Flutter test. These diagnostics are
  debug-only; no TestFlight upload was triggered.
- Read-only Render CLI verification found production service `ohey-backend`
  configured to track `development` with auto-deploy enabled. Its latest live
  deploy is `c7838fd0ba14fb4bded3736ac9bc6ea1e0dc293e`, matching local and
  remote `development`. `origin/main` does not contain this commit; branch
  comparison shows 30 main-only and 6 development-only commits. The Render
  branch setting was not changed because changing it could alter production
  deploys; confirm the intended production source before promoting code.
- App Store Connect currently redirects to sign-in, so the June 9 rejection
  details and live App Privacy answers remain unverified. No credentials were
  entered and no App Store Connect changes were made.
- The paired iPhone 14 is currently locked. `devicectl` could not mount its
  developer disk image to inspect installed apps; this is not evidence that
  Ohey is or is not installed. Real-device TestFlight verification remains
  pending.

## Update 2026-10-10 — dev Simulator owner-identity regression

- A dev Render-backed iPad Air 11-inch (M3) Simulator QA run reproduced a
  release-blocking issue: Ohey compared Clerk's auth user ID with backend
  resource `owner_user_id` values, which are internal `profiles.id` UUIDs. The
  user's own newly created yurubo was consequently shown with mute / block /
  report actions instead of edit / delete.
- Mobile commit `469fcba` adds `OheyUser.profileId` from profile reads and
  profile creation, and uses it for ownership and related profile-ID
  comparisons. Clerk IDs remain in API-authentication headers. Focused Flutter
  tests, targeted analyze, and CI run
  [38052361568](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/38052361568)
  passed.
- On the dev Simulator, login survived hot restart; the own-post menu then
  showed edit / delete. Editing the test post's title and place saved and
  refreshed the home card; a second hot restart restored the edited values.
  The dev-only test post is still present because its delete action awaits
  action-time confirmation; no production data was touched.
- The latest recorded TestFlight build `20261009143943` predates Mobile fix
  `469fcba` (its app source was `280346d`). A fresh internal build is needed to
  verify the fix on a physical device. The TestFlight workflow uploads a
  production-configured binary and assigns it to the auto-notify internal
  group, so it was not dispatched without action-time confirmation.
- The account has zero friends, so visibility to other users, invite delivery,
  and acceptance / rejection remain unverified. The QA checklist has the
  create/edit evidence; the physical TestFlight and public App Store gates below
  remain open.
- Current branch comparison after fetching both repos: Mobile `origin/main`
  has 49 main-only commits and `origin/development` has 24 development-only
  commits; Backend has 30 main-only and 6 development-only commits. The Mobile
  `main` branch still has its existing automatic TestFlight-on-push workflow;
  do not promote or dispatch until the candidate and artifact-safe workflow
  are deliberately reconciled.

## Verified in this follow-up

- `Suuu-sh/Ohey_Mobile` is public. Its TestFlight workflow uses the standard
  `macos-15` GitHub-hosted runner. [GitHub's billing documentation](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
  says standard-runner use is free for public repositories; storage remains
  subject to quotas. Four stale cache entries were pruned; the four remaining
  Actions caches use 3,948,405,008 bytes (about 3.7 GiB, below the published
  10 GB per-repository cache allowance). This run retained no artifacts.
- TestFlight run `37889445468` used the `development` workflow at `7227958` and
  app source `280346d`; `7227958` changes workflow artifact handling only.
  Backend remains on `development` at `c7838fd`. Existing uncommitted release
  notes and preview assets were not included in the workflow change.
- On app source `280346d`, full `flutter analyze` passed and all 51 tests in
  `flutter test` passed. The Apple OAuth recovery widget test also passed; it
  confirms retry UI behavior, not native Apple Sign-In or the reported iPad
  white-screen fix. Public CI run
  [37891134176](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/37891134176)
  also passed both `Flutter test` and `Flutter analyze` on `b9902d8` (docs-only
  changes after the TestFlight app source).
- TestFlight run
  [37889445468](https://github.com/Suuu-sh/Ohey_Mobile/actions/runs/37889445468)
  succeeded for build `20261009143943`: archive, archived-manifest validation,
  upload, and internal-group assignment steps passed. App Store Connect reported
  `processing_state: VALID`. One internal tester was in the `Ohey Internal
  Testers` group, which has access to all builds. Installation of this specific
  build on a device has not been verified.
- The group already has automatic TestFlight notifications enabled. The explicit
  notification request returned `409 Auto-notify already enabled`; this was not
  an upload or assignment failure.
- The TestFlight workflow no longer uploads `.xcarchive` or exported app files
  as GitHub artifacts. In a public repository those artifacts are readable by
  repository readers; the workflow now emits a per-manifest inventory in the
  public run summary instead. This inventory is not Apple's generated privacy
  report. The successful run retained zero artifacts.
- The archived app contained 29 `PrivacyInfo.xcprivacy` files. No manifest set
  `NSPrivacyTracking` to `true` or listed tracking domains. The first-party
  `Runner.app/PrivacyInfo.xcprivacy` declares its listed data types as not used
  for tracking. The embedded `GoogleMobileAdsResources` manifest declares
  Device ID as linked and used for tracking, plus advertising/analytics data;
  it also declares required-reason API categories. [Apple's privacy-manifest
  guidance](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests)
  says the first-party manifest does not need to repeat third-party SDK
  collection, so the first-party/SDK distinction alone is not an error. The
  exact Xcode Organizer privacy report and current App Store Connect answers
  still need to be compared before public App Store submission.
- Xcode 26.6 Organizer generated a one-page privacy report from an unsigned
  local `1.0.0 (20261009143943)` archive. The app source and lockfiles for
  `lib/`, `ios/`, `pubspec.yaml`, and `pubspec.lock` match the candidate source
  commit `280346d`; this was not the original signed CI archive, which was not
  retained. The local archive also contained 29 manifests. The report was kept
  outside the repository at `/tmp/OheyPrivacyReport` and was neither committed
  nor uploaded.
- Reconciliation found material differences from
  [`app_privacy.md`](app_privacy.md): the report additionally lists Phone
  Number (Google Sign-In), Other Usage Data, Other Diagnostic Data, and Other
  Data Types (Google Sign-In / Firebase Messaging), while the checklist omits
  these and explicitly says not to select Other Data Types. The report lists
  Coarse Location, Product Interaction, and Advertising Data with SDK-specific
  linkage and purposes, including Developer's Advertising or Marketing, that
  do not exactly match the checklist. It reports RevenueCat Purchase History as
  not linked, while the checklist says linked. Crash and Performance Data also
  have SDK-specific linkage/purpose entries that differ from the summarized
  checklist. These are questions to validate against the exact SDK versions,
  actual app behavior, and App Store Connect answers—not automatic corrections
  to make based on the report alone. Apple's guidance requires accounting for
  third-party partners and using the report to inform App Privacy; Google's
  Mobile Ads disclosure guide likewise says developers are responsible for
  checking the SDK manifest and keeping disclosures current.
- No App Store Connect privacy answers were changed: its browser session is
  signed out, and the SDK-specific differences need validation before changing
  a public privacy label. See [Apple's App Privacy details](https://developer.apple.com/app-store/app-privacy-details/),
  [Apple's Xcode privacy-report guidance](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests),
  and [Google's iOS Mobile Ads data disclosure](https://developers.google.com/admob/ios/privacy/data-disclosure?hl=en).
- A source-only QA sweep found no Backend Go routes for retired
  `/v1/memories`, `/v1/home/feed`, or `/v1/memory-hides` endpoints. It found an
  unused Mobile `/v1/home/feed` path constant, which was removed; no Mobile
  callers or retired-feature UI labels remain. This does not count as runtime,
  admin-console, or multi-user QA.
- Backend `go test ./...` passed on the fetched `development` branch. This was
  a local source-test result (cached by Go), not proof of the production
  Render deployment SHA.
- The current `development` app was launched in iPad Air 11-inch (M3) Simulator
  on iOS 26.3 with the dev Render backend. UMP and ATT prompts appeared, then
  the app reached its startup splash. No account login or Apple Sign-In was
  attempted. The physical iPhone 14 is still `unavailable` to `devicectl`.
- A read-only GET to
  `https://ohey-backend.onrender.com/health` returned HTTP 200 (`status: ok`),
  but the endpoint does not report a deployed SHA. A read-only Render CLI
  recheck on 2026-10-10 confirmed the live production deploy is
  `c7838fd0ba14fb4bded3736ac9bc6ea1e0dc293e`, matching
  `origin/development`. The service still tracks `development` with
  auto-deploy enabled; whether that branch target is intentional remains
  unconfirmed, and no Render settings were changed.

## Remaining blockers

- The Apple Sign-In timeout fix from `a8ea58b` is present, but the native
  white-screen report has not been reproduced or cleared on the affected iPad
  Air 11-inch (M3). A Simulator or unit test is not equivalent to that device
  and iPadOS configuration.
- Build `20261009143943` is processed and assigned to the internal group, but
  installation and sign-in on the approved iPhone 14 have not been verified.
- The archived manifest inventory does not replace Xcode Organizer's generated
  privacy report. Reconcile that report with `app_privacy.md` and the current
  App Store Connect privacy answers; do not change tracking declarations based
  only on the first-party manifest.
- The artifact-safe workflow change is on `development` only. The default
  `main` branch has not been promoted; its current workflow still uploads the
  archive/export on failure and a push to `main` starts TestFlight distribution.
  Do not promote or trigger it until the internal candidate is cleared and that
  workflow version is made artifact-safe.
- App Store Connect app `6774577603` has a recorded v1.0 rejection on June 9,
  but its guideline and resolution details are absent from the repository. An
  authenticated App Store Connect session is required to retrieve them.
- `QA.md` now includes the 2026-10-10 dev Simulator create/edit evidence.
  Deletion of the temporary test post and multi-user, failure/retry, invite,
  consent/ATT, advertising, and purchase flows still need verification.
- The production Render SHA is confirmed as `c7838fd0ba14fb4bded3736ac9bc6ea1e0dc293e`;
  whether the service should auto-deploy from `development` remains unconfirmed.

## Next actions

1. Build a new internal TestFlight candidate from `development` including
   `469fcba`, then install it on the approved iPhone 14 to verify Apple sign-in,
   cancellation/retry, consent/ATT, and the priority QA flows. Retest the
   reported iPad Air 11-inch (M3) configuration if available. The existing
   `20261009143943` build is older than this fix.
2. Generate Apple's Xcode Organizer privacy report from an archive of the exact
   candidate/dependency set in a trusted local environment (do not upload the
   signed archive to the public repository), then reconcile it with
   `app_privacy.md` and App Store Connect.
3. Read and record the June 9 App Store rejection guideline and resolution
   details in App Store Connect. Do not submit a new public review yet.
4. Complete and record the priority `QA.md` scenarios using approved dev/test
   accounts.
5. Confirm the current Render Production commit and whether its `development`
   branch target is intentional. Do not paste Render tokens into chat.

Public App Store release remains separate and not authorized.
