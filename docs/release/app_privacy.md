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

## Data Types to select for the current AdMob-enabled v1 build

| Category | Data type | Linked to user | Tracking | Purposes |
| --- | --- | --- | --- | --- |
| Contact Info | Name | Yes | No | App Functionality |
| Contact Info | Email Address | Yes | No | App Functionality |
| Location | Coarse Location | Yes | No | Third-Party Advertising, Analytics |
| Contacts | Contacts | Yes | No | App Functionality |
| User Content | Other User Content | Yes | No | App Functionality |
| Identifiers | User ID | Yes | No | App Functionality |
| Identifiers | Device ID | Yes | Yes | Third-Party Advertising, Analytics, App Functionality |
| Purchases | Purchase History | Yes | No | App Functionality, Analytics |
| Usage Data | Product Interaction | Yes | No | Third-Party Advertising, Analytics |
| Usage Data | Advertising Data | Yes | No | Third-Party Advertising, Analytics |
| Diagnostics | Crash Data | No | No | Third-Party Advertising, Analytics |
| Diagnostics | Performance Data | Yes | No | Third-Party Advertising, Analytics |

## Why these are selected

- **Name / Email Address**: Clerk Auth, OAuth login, profile display, and
  support/account operations.
- **Do not select Precise Location**: the current app accepts user-entered place
  text but does not request device location or send latitude/longitude.
- **Coarse Location**: Google documents that the Mobile Ads SDK may derive or
  process coarse location, for example from IP address, for ads and analytics.
- **Contacts**: Apple's data-type definition includes an in-app social graph.
  Ohey collects friend requests, friendships, groups, blocks, and mutes even
  though it never reads the device address book.
- **Other User Content**: profile text, status, invitations, yurubo posts,
  wish items, comments/memos, reports, and moderation signals.
- **User ID**: Clerk/Neon auth UUID, Ohey ID, and related account identifiers.
- **Device ID**: APNs/FCM push token associated with the account for
  notifications, plus identifiers the AdMob SDK may process for advertising.
- **Purchase History**: RevenueCat associates subscription entitlement and
  purchase state with the authenticated Ohey user ID. RevenueCat's guidance
  says App Functionality and Analytics are the minimum purposes to disclose.
- **Product Interaction / Advertising Data / Diagnostics**: Google documents
  that the Mobile Ads SDK may process ad interactions, advertising data, crash
  logs, and performance data. App Store disclosures must include third-party
  partner practices, not only Ohey's first-party backend.

## Do not select for the current AdMob-enabled v1 build

- Health & Fitness
- Sensitive Info
- Photos or Videos
- Audio Data
- Browsing History
- Search History

## Unresolved SDK data types

- **Other Data Types:** intentionally not marked included or excluded in this
  draft until the SDK-manifest discrepancy in the validation hold above has
  been resolved.

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
