# TestFlight readiness follow-up

As of: 2026-10-09

Scope: internal TestFlight verification only. The repository is public by user
request; no public App Store submission or App Review submission was performed
or authorized.

## Verified in this follow-up

- `Suuu-sh/Ohey_Mobile` is public. Its TestFlight workflow uses the standard
  `macos-15` GitHub-hosted runner. [GitHub's billing documentation](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
  says standard-runner use is free for public repositories; storage remains
  subject to quotas. Current Actions caches use 6,110,673,569 bytes (about
  5.7 GiB, below the published 10 GB per-repository cache allowance), and this
  run retained no artifacts.
- TestFlight run `37889445468` used the `development` workflow at `7227958` and
  app source `280346d`; `7227958` changes workflow artifact handling only.
  Backend remains on `development` at `c7838fd`. Existing uncommitted release
  notes and preview assets were not included in the workflow change.
- On app source `280346d`, full `flutter analyze` passed and all 51 tests in
  `flutter test` passed. The Apple OAuth recovery widget test also passed; it
  confirms retry UI behavior, not native Apple Sign-In or the reported iPad
  white-screen fix.
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
- A source-only QA sweep found no Backend Go routes for retired
  `/v1/memories`, `/v1/home/feed`, or `/v1/memory-hides` endpoints. It found an
  unused Mobile `/v1/home/feed` path constant, which was removed; no Mobile
  callers or retired-feature UI labels remain. This does not count as runtime,
  admin-console, or multi-user QA.
- The current `development` app was launched in iPad Air 11-inch (M3) Simulator
  on iOS 26.3 with the dev Render backend. UMP and ATT prompts appeared, then
  the app reached its startup splash. No account login or Apple Sign-In was
  attempted. The physical iPhone 14 is still `unavailable` to `devicectl`.
- A read-only GET to
  `https://ohey-backend.onrender.com/health` returned HTTP 200 (`status: ok`),
  but the endpoint does not report a deployed SHA. An earlier Render dashboard
  snapshot recorded `c7838fd0ba14fb4bded3736ac9bc6ea1e0dc293e`; the current
  production SHA and the service's `development` branch setting still need
  confirmation.

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
- App Store Connect app `6774577603` has a recorded v1.0 rejection on June 9,
  but its guideline and resolution details are absent from the repository. An
  authenticated App Store Connect session is required to retrieve them.
- `QA.md` has 169 checklist items; 18 are checked. Multi-user, failure/retry,
  invitation, delete, consent/ATT, advertising, and purchase flows still need
  their stated dev/test-account verification.
- The current production Render SHA and whether the service's `development`
  branch setting is intentional remain unconfirmed.

## Next actions

1. Install build `20261009143943` from TestFlight on the approved iPhone 14 and
   verify Apple sign-in, cancellation/retry, consent/ATT, and the priority QA
   flows. Retest the reported iPad Air 11-inch (M3) configuration if available.
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
