# Codex Security diff scan final report

Target: `/Users/yota/Projects/Products/Ohey/Mobile` local patch

## Result

No reportable security findings found in the diff.

## Notes

- OAuth callback validation remains restricted to `app.ohey.com://login-callback/` and `app.ohey.com.dev://login-callback/`.
- Auto profile creation still requires a valid Clerk-authenticated backend API client; no unauthenticated profile creation endpoint was added in Mobile.
- The initial OAuth display name is now a generic `Ohey user`, avoiding accidental exposure of email local parts in public profile fields.
- Apple OAuth is hidden unless `OHEY_ENABLE_APPLE_OAUTH=true` is explicitly supplied, preventing a known failing provider from being presented while Clerk/Apple provider settings are incomplete.
