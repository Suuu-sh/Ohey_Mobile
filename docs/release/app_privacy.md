# App Store Connect App Privacy answers

Last verified against the Ohey codebase: 2026-06-07
App Store Connect App Privacy published: 2026-06-07 JST

This file is the source-of-truth checklist for App Store Connect's **App
Privacy** screen for the current v1 production build.

## Current v1 production state

- Production AdMob IDs are configured through the production CI/TestFlight
  environment. Release builds can display AdMob native ads.
- `NSUserTrackingUsageDescription` is present and the app requests ATT before
  loading the Google Mobile Ads SDK on iOS.
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
| Location | Precise Location | Yes | No | App Functionality |
| Location | Coarse Location | Yes | No | App Functionality |
| Contacts | Contacts | Yes | No | App Functionality |
| User Content | Other User Content | Yes | No | App Functionality |
| Identifiers | User ID | Yes | No | App Functionality |
| Identifiers | Device ID | Yes | Yes | Third-Party Advertising, Analytics, App Functionality |

## Why these are selected

- **Name / Email Address**: Supabase Auth, OAuth login, profile display, and
  support/account operations.
- **Precise / Coarse Location**: place search and user-selected place
  coordinates/text on memories and availability posts.
- **Contacts**: the app stores in-app friendships, friend requests, groups,
  blocks, and mutes. It does not read the device address book.
- **Other User Content**: profile text, status, invitations, yurubo posts,
  wish items, memories, comments/memos, reports, and moderation signals.
- **User ID**: Supabase auth UUID, Ohey ID, and related account identifiers.
- **Device ID**: APNs/FCM push token associated with the account for
  notifications.

## Do not select for the current AdMob-enabled v1 build

- Financial Info / Purchases
- Health & Fitness
- Sensitive Info
- Photos or Videos
- Audio Data
- Browsing History
- Search History
- Usage Data
- Diagnostics
- Other Data Types

## AdMob / ATT release checklist

- Keep the UMP consent flow enabled via `OheyAdsConsentService`.
- Keep `NSUserTrackingUsageDescription` in `ios/Runner/Info.plist`.
- Keep App Store Connect `usesIdfa` set to `true` while requesting IDFA/ATT.
- Keep App Privacy **Data Used to Track You** enabled for Identifiers / Device
  ID while AdMob can use IDFA for tracking.
- Do not use `OHEY_ADMOB_FORCE_TEST_ADS=true` for App Review or production
  release builds.
