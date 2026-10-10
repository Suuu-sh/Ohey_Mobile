#!/usr/bin/env python3
"""Fail TestFlight preparation if production Clerk native auth is unavailable."""

from __future__ import annotations

import base64
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path


EXPECTED_HOST = "clerk.oheyapp.com"
ENVIRONMENT_URL_SUFFIX = "/v1/environment?_is_native=true&_clerk_js_version=4.70.0"
GOOGLE_CLIENT_ID_SUFFIX = ".apps.googleusercontent.com"
GOOGLE_REVERSED_CLIENT_ID_PREFIX = "com.googleusercontent.apps."


def read_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[key.strip()] = value
    return values


def clerk_host(publishable_key: str) -> str | None:
    if not publishable_key.startswith("pk_live_"):
        return None
    encoded_domain = publishable_key.split("_", 2)[-1]
    encoded_domain += "=" * (-len(encoded_domain) % 4)
    try:
        decoded = base64.urlsafe_b64decode(encoded_domain).decode("utf-8")
    except (ValueError, UnicodeDecodeError):
        return None
    host = decoded.split("$", 1)[0].strip()
    return host or None


def fetch_environment(publishable_key: str, host: str) -> dict[str, object]:
    request = urllib.request.Request(
        f"https://{host}{ENVIRONMENT_URL_SUFFIX}",
        headers={"Authorization": publishable_key, "Accept": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)
    if not isinstance(payload, dict):
        raise ValueError("Clerk environment response was not an object")
    return payload


def verify_environment(environment: dict[str, object]) -> list[str]:
    failures: list[str] = []
    user_settings = environment.get("user_settings")
    social = user_settings.get("social") if isinstance(user_settings, dict) else None
    if not isinstance(social, dict):
        social = {}

    for provider in ("oauth_apple", "oauth_google"):
        config = social.get(provider)
        if (
            not isinstance(config, dict)
            or not config.get("enabled")
            or not config.get("authenticatable")
        ):
            failures.append(f"{provider.removeprefix('oauth_')} sign-in is not enabled")

    auth_config = environment.get("auth_config")
    native = auth_config.get("native_settings") if isinstance(auth_config, dict) else None
    if not isinstance(native, dict) or not native.get("api_enabled"):
        failures.append("Clerk Native API is not enabled")

    strategies = (
        auth_config.get("identification_strategies")
        if isinstance(auth_config, dict)
        else None
    )
    if not isinstance(strategies, list):
        strategies = []
    for provider in ("oauth_apple", "oauth_google"):
        if provider not in strategies:
            failures.append(
                f"{provider.removeprefix('oauth_')} is not an enabled sign-in strategy"
            )

    return failures


def verify_google_client_ids(values: dict[str, str]) -> list[str]:
    failures: list[str] = []
    web_client_id = values.get("GOOGLE_WEB_CLIENT_ID", "")
    ios_client_id = values.get("GOOGLE_IOS_CLIENT_ID", "")
    reversed_client_id = values.get("GOOGLE_IOS_REVERSED_CLIENT_ID", "")

    if not any((web_client_id, ios_client_id, reversed_client_id)):
        return failures

    if not web_client_id.endswith(GOOGLE_CLIENT_ID_SUFFIX):
        failures.append(
            "GOOGLE_WEB_CLIENT_ID is missing or is not a Google OAuth client ID"
        )
    if not ios_client_id.endswith(GOOGLE_CLIENT_ID_SUFFIX):
        failures.append(
            "GOOGLE_IOS_CLIENT_ID is missing or is not a Google OAuth client ID"
        )
    if ios_client_id.endswith(GOOGLE_CLIENT_ID_SUFFIX):
        expected_reversed = (
            GOOGLE_REVERSED_CLIENT_ID_PREFIX
            + ios_client_id.removesuffix(GOOGLE_CLIENT_ID_SUFFIX)
        )
        if reversed_client_id != expected_reversed:
            failures.append(
                "GOOGLE_IOS_REVERSED_CLIENT_ID does not match GOOGLE_IOS_CLIENT_ID"
            )
    elif not reversed_client_id.startswith(GOOGLE_REVERSED_CLIENT_ID_PREFIX):
        failures.append(
            "GOOGLE_IOS_REVERSED_CLIENT_ID is missing or is not a Google callback scheme"
        )

    return failures


def main() -> int:
    env_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".env.production")
    try:
        values = read_env(env_path)
        publishable_key = values.get("CLERK_PUBLISHABLE_KEY") or values.get(
            "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY", ""
        )
    except OSError:
        print(
            "::error::Could not read the generated production environment file.",
            file=sys.stderr,
        )
        return 1
    if not publishable_key:
        print(
            "::error::CLERK_PUBLISHABLE_KEY is missing from the production build environment.",
            file=sys.stderr,
        )
        return 1

    google_failures = verify_google_client_ids(values)
    if google_failures:
        print(
            "::error::Production Google Sign-In config preflight failed: "
            + "; ".join(google_failures)
            + ".",
            file=sys.stderr,
        )
        return 1

    host = clerk_host(publishable_key)
    if host != EXPECTED_HOST:
        print(
            "::error::The production Clerk key does not target the expected Clerk domain.",
            file=sys.stderr,
        )
        return 1

    try:
        environment = fetch_environment(publishable_key, host)
    except urllib.error.HTTPError as error:
        print(
            f"::error::Could not read production Clerk auth settings (HTTP {error.code}).",
            file=sys.stderr,
        )
        return 1
    except (OSError, ValueError, json.JSONDecodeError):
        print("::error::Could not read production Clerk auth settings.", file=sys.stderr)
        return 1

    failures = verify_environment(environment)
    if failures:
        print(
            "::error::Production Clerk auth preflight failed: "
            + "; ".join(failures)
            + ".",
            file=sys.stderr,
        )
        return 1

    print("Production Clerk preflight passed: Apple, Google, and Native API are enabled.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
