# App Store Connect App Privacy answers

Last verified against the Ohey codebase: 2026-07-14
App Store Connect App Privacy published: 2026-06-07 JST

This file records the App Store Connect **App Privacy** answers last documented
as published on 2026-06-07. It does not prove that the current App Store Connect
answers are unchanged.

## Validation hold — 2026-10-09

Do not reuse the table below for a new submission until it has been reconciled
with the Xcode Organizer privacy report and the live App Store Connect answers.
The report generated for build `1.0.0 (20261009143943)` exposed SDK-specific
data types, purposes, and linked-data differences from this checklist. The
current App Store Connect session was signed out during the audit, and no
privacy answers were changed. See the [release-readiness audit](testflight_readiness_2026-10-09.md)
for details.

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
| Purchases | Purchase History | Yes | No | App Functionality |
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
  purchase state with the authenticated Ohey user ID.
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
- Other Data Types

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
