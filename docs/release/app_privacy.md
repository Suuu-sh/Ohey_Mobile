# App Store Connect App Privacy answers

Last verified against the Ohey codebase: 2026-06-06

This file is the source-of-truth checklist for App Store Connect's **App
Privacy** screen for the current v1 production build.

## Current v1 production state

- Production AdMob IDs in `config/firebase/prod.json` are blank, so
  `OheyAdsConfig.isEnabled` is `false` for release builds.
- `NSUserTrackingUsageDescription` is not present.
- App Store Connect `usesIdfa` is set to `false`.
- If production AdMob IDs are added later, update the "AdMob enabled" section
  below before submitting the build.

## Data Collection

Answer: **Yes, we collect data from this app.**

## Data Types to select for the current no-ads v1 build

| Category | Data type | Linked to user | Tracking | Purposes |
| --- | --- | --- | --- | --- |
| Contact Info | Name | Yes | No | App Functionality |
| Contact Info | Email Address | Yes | No | App Functionality |
| Location | Precise Location | Yes | No | App Functionality |
| Location | Coarse Location | Yes | No | App Functionality |
| Contacts | Contacts | Yes | No | App Functionality |
| User Content | Other User Content | Yes | No | App Functionality |
| Identifiers | User ID | Yes | No | App Functionality |
| Identifiers | Device ID | Yes | No | App Functionality |

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

## Do not select for the current no-ads v1 build

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
- Data Used to Track You

## If production AdMob is enabled later

Before submitting a build that displays AdMob ads:

1. Set real production values for:
   - `OHEY_ADMOB_IOS_APP_ID`
   - `OHEY_ADMOB_IOS_NATIVE_AD_UNIT_ID`
   - Android equivalents if shipping Android
2. Keep the UMP consent flow enabled via `OheyAdsConsentService`.
3. Configure the required AdMob **Privacy & messaging** messages in the AdMob
   dashboard.
4. Update App Store Connect App Privacy to include AdMob-related data:
   - Identifiers: Device ID
   - Usage Data: Advertising Data, Product Interaction
   - Diagnostics: Crash Data, Performance Data
   - Purposes: Third-Party Advertising, Analytics, and App Functionality as
     applicable
5. If ads are personalized or IDFA/tracking is used, set **Data Used to Track
   You** appropriately and add an ATT prompt with
   `NSUserTrackingUsageDescription` before release.
