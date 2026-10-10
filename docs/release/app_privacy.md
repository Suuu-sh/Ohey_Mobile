# App Store Connect App Privacy answers

Last reviewed against the Ohey codebase and archived SDK manifests: 2026-10-10
App Store Connect App Privacy published: 2026-06-07 JST

This file records the App Store Connect **App Privacy** answers last documented
as published on 2026-06-07. It does not prove that the current App Store Connect
answers are unchanged.

## Validation hold — 2026-10-10

Do not reuse the table below for a new submission until it has been reconciled
with the Xcode Organizer privacy report and the live App Store Connect answers.
The report generated for build `1.0.0 (20261009143943)` exposed SDK-specific
data types, purposes, and linked-data differences from this checklist. The
current App Store Connect session is signed out, and no privacy answers were
changed. See the [release-readiness audit](testflight_readiness_2026-10-09.md)
for details. The 2026-10-10 review below is repository evidence only, not a
verification of the live App Store Connect answers.

An additional unsigned `xcodebuild archive` was produced from current Mobile
`development` HEAD `56a3d95` with Xcode 26.6 on 2026-10-10. It contains 29
privacy manifests, all of which pass `plutil -lint`. This confirms the
current-source manifest inventory only; no Xcode Organizer aggregated report
was generated from this unsigned, non-production-configured archive.

## Repository evidence review — 2026-10-10 (draft only)

- **Purchase History:** Ohey configures RevenueCat with the authenticated
  Clerk user ID (`OheyPlusService`), so this data is linked to an account.
  RevenueCat's current App Privacy guidance says Purchase History should
  include both App Functionality and Analytics. The table below reflects those
  purposes; the live App Store Connect answer remains unverified.
- **Google Sign-In 8.0.0:** Ohey requests only `email` and `profile` scopes.
  Google's disclosure page describes a user identifier and IP address, while
  the archived Google Sign-In privacy manifest also lists Phone Number and
  other data types. Do not infer that phone numbers are collected from the
  scope list alone or copy manifest entries mechanically; resolve the
  version-specific discrepancy before changing the live label.
- **Firebase Messaging 12.13.0:** the archived manifest lists Device ID,
  Other Data Types, and Other Diagnostic Data. Google's Firebase guidance
  describes APNs/FCM installation identifiers and device/app metadata; Ohey
  associates its push token with the signed-in account. Keep the `Other Data
  Types` answer open until this SDK behavior is mapped to Apple's categories.
- **Google Mobile Ads 13.2.0 / UMP:** the archive report includes SDK-specific
  purposes and linkage that differ from this checklist, including Developer's
  Advertising or Marketing. Google's public AdMob disclosure guide describes
  collection practices as of 7.68.0, not the locked 13.2.0 release. Verify the
  exact SDK declarations and actual app use before changing live answers.
- Apple's privacy report aggregates the app and linked SDK manifests and is an
  input to App Privacy disclosures; it does not itself prove all runtime
  collection or replace review of the live questionnaire.

## Previously documented v1 production state (pending live verification)

- Production AdMob IDs are configured through the production CI/TestFlight
  environment. Release builds can display AdMob native ads.
- `NSUserTrackingUsageDescription` is present. The app completes the UMP
  consent flow before requesting ATT and loading the Google Mobile Ads SDK.
- `ios/Runner/PrivacyInfo.xcprivacy` declares data collected directly by Ohey.
  Third-party SDK manifests remain responsible for their own collection and
  required-reason API declarations.
- App Store Connect `usesIdfa` is set to `true`.
- App Store Connect App Privacy declares Device ID as used for tracking,
  Third-Party Advertising, Analytics, and App Functionality.

## Data Collection

Answer: **Yes, we collect data from this app.**

## Archive-derived candidate data inventory (not final ASC answers)

Xcode Organizer's report aggregates 29 manifests from an unsigned archive of
source `280346d` (build `20261009143943`). `pubspec.yaml`, `pubspec.lock`, and
`ios/Podfile.lock` match source `469fcba`; the latter changed app code, not SDK
versions. The report is still not proof that every manifest-listed item is
collected in Ohey's runtime configuration. The matrix below records each
SDK's declared values and known app-level linkage; use it to reconcile the live
questionnaire, not as a ready-to-submit answer. Apple says to account for
third-party partners and use the report as an input to App Privacy.

| Data type | Archive / app evidence (linked; tracking; purposes) | Status |
| --- | --- | --- |
| Name | Runner + Google Sign-In: Yes; No; App Functionality | Keep in draft; profile/auth use |
| Email Address | Runner + Google Sign-In: Yes; No; App Functionality | Keep in draft; auth/profile use |
| Phone Number | Google Sign-In: Yes; No; App Functionality | Open: app requests only `email` and `profile`; vendor manifest conflicts with its public disclosure |
| Coarse Location | Google Mobile Ads / Google Sign-In: Yes; No; third-party advertising, analytics, developer advertising, app functionality. UMP: No; No; app functionality | Open: verify actual SDK collection and purposes |
| Contacts | Runner: Yes; No; App Functionality | Keep in draft for the in-app social graph; no address-book permission |
| Other User Content | Runner: Yes; No; App Functionality | Keep in draft for profile text, posts, invitations, wish items, and reports |
| User ID | Runner + Google Sign-In: Yes; No; App Functionality, Analytics | Keep in draft; auth and account IDs are used |
| Device ID | Runner / Google Sign-In / Google Mobile Ads: Yes; Firebase Messaging / ATT SDK: No. Google Mobile Ads: Tracking Yes; other declarations: No. Purposes include app functionality, third-party advertising, developer advertising, analytics | Open for final purpose/linkage review; Ohey also sends the FCM token to its authenticated backend |
| Purchase History | RevenueCat manifest: No; No; App Functionality. Ohey code: authenticated Clerk ID is RevenueCat App User ID; RevenueCat guidance: Yes; No; App Functionality + Analytics | Source-level resolution: use Yes for linked in draft; live ASC remains unverified |
| Product Interaction | Google Mobile Ads: Yes; No; analytics, developer advertising, third-party advertising. UMP: No; No; App Functionality | Open: verify actual collection/configuration |
| Advertising Data | Google Mobile Ads: Yes; No; third-party advertising, developer advertising, analytics | Open: verify exact SDK behavior |
| Other Usage Data | Google Sign-In: Yes; No; Analytics | Open: manifest-only item; confirm runtime collection |
| Crash Data | Google Mobile Ads: No; No; Analytics | Candidate from SDK manifest; verify current SDK behavior |
| Performance Data | Google Mobile Ads: No; No; third-party advertising, developer advertising, analytics. UMP: No; No; App Functionality | Candidate from SDK manifests; do not use the old linked=Yes answer |
| Other Diagnostic Data | Firebase Messaging / Firebase Installations / Google Data Transport / Google Mobile Ads: No; No; purposes include App Functionality, Analytics, third-party advertising, developer advertising | Candidate from SDK manifests; verify current SDK behavior |
| Other Data Types | Google Sign-In: Yes; No; App Functionality + Analytics. Firebase Messaging: No; No; Analytics | Open: conflicting linkage and unclear mapping to actual collected fields |

### App behavior used in the matrix

- `GoogleAuthService` requests only the `email` and `profile` OAuth scopes.
  Google's disclosure describes user identifier and IP address; the exact
  Google Sign-In 8.0.0 manifest additionally declares Phone Number, Other Data
  Types, and Other Usage Data. Do not treat the unused phone scope as proof of
  collection, but do not silently ignore the SDK declaration either.
- `OheyPushNotificationService` obtains an FCM token and
  `PushTokenRepository` registers it through an authenticated API call. This
  makes the push identifier account-linked in Ohey even though Firebase's
  manifest labels its Device ID unlinked. Firebase documents APNs/FCM
  installation identifiers and device/app metadata; Ohey does not use topic
  subscription APIs or Firebase Analytics.
- `OheyPlusService` configures RevenueCat with the authenticated Clerk user ID
  and uses `Purchases.logIn` when an existing SDK configuration is active.
  RevenueCat says Purchase History is linked when the custom App User ID can be
  tied to a user through the app or backend; this resolves the manifest-versus-
  app linkage question for the draft.
- The first-party manifest's `NSPrivacyTracking=false` does not override the
  Google Mobile Ads manifest's Device ID `NSPrivacyCollectedDataTypeTracking=true`.
  The archived report declares Device ID as tracking data for the SDK, while
  it does not set top-level `NSPrivacyTracking=true` for any of the 29
  manifests. Reconcile both the SDK's behavior and the live ATT/ASC answers.

## No current app-code evidence found

- Precise Location: the app accepts user-entered place text and does not
  request device location or send latitude/longitude.
- Health & Fitness, Sensitive Info, Photos or Videos, Audio Data, Browsing
  History, and Search History.
- Contacts means the in-app social graph under Apple's definition; Ohey does
  not request access to the device address book.

## Do not select for the current AdMob-enabled v1 build

- Health & Fitness
- Sensitive Info
- Photos or Videos
- Audio Data
- Browsing History
- Search History

## Unresolved SDK data types

- Phone Number, Other Usage Data, Other Data Types, Coarse Location, and the
  SDK-specific linkage / purpose values need version-specific validation
  against runtime behavior and the live App Store Connect questionnaire.
- Do not exclude a data type solely because it is absent from Ohey's
  first-party `PrivacyInfo.xcprivacy`; linked third-party SDKs have their own
  manifests and disclosures.

## AdMob / ATT release checklist

- Keep the UMP consent flow enabled via `OheyAdsConsentService`.
- Keep `NSUserTrackingUsageDescription` in `ios/Runner/Info.plist`.
- Keep App Store Connect `usesIdfa` set to `true` while requesting IDFA/ATT.
- Keep App Privacy **Data Used to Track You** enabled for Identifiers / Device
  ID while AdMob can use IDFA for tracking.
- Do not use `OHEY_ADMOB_FORCE_TEST_ADS=true` for App Review or production
  release builds.
- Generate and inspect Xcode's privacy report for the archived build before
  every App Store submission; reconcile it with this checklist and App Store
  Connect.

## Primary references

- [Apple: App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple: Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Google: Mobile Ads SDK App Store data disclosure](https://developers.google.com/admob/ios/privacy/data-disclosure)
- [Google: Sign-In for iOS App Store data disclosure](https://developers.google.com/identity/sign-in/ios/app-privacy)
- [Google: Firebase Apple-platform App Store data disclosure](https://firebase.google.com/docs/ios/app-store-data-collection)
- [RevenueCat: Apple App Privacy](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-app-privacy)
