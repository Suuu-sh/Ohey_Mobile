# Threat model

Scope: Mobile OAuth/login flow local patch.

Assets: Clerk session tokens, backend authorization headers, user profile identifiers, public display names, onboarding state, OAuth callback URLs.

Primary risks reviewed:
- Accepting forged or unrelated deep links as OAuth callbacks.
- Creating backend profiles without a valid authenticated Clerk session.
- Leaking email-derived personal data into public display names.
- Leaving a broken Apple OAuth entry point exposed to users.
- Introducing auth bypass by auto-creating profiles client-side.
