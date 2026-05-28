#!/usr/bin/env python3
"""Runtime Supabase REST/RLS/GRANT checks for Tomo.

Required env:
  SUPABASE_URL
  SUPABASE_PUBLISHABLE_KEY
Optional env:
  SUPABASE_SERVICE_ROLE_KEY
  TOMO_SMOKE_EMAIL / TOMO_SMOKE_PASSWORD

The script intentionally uses the HTTP APIs instead of direct SQL so it verifies
what Mobile/Backend clients observe through Supabase Data API grants and RLS.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass


REQUIRED_TABLES = [
    "profiles",
    "friendships",
    "friend_requests",
    "daily_statuses",
    "friend_groups",
    "friend_group_members",
    "user_blocks",
    "user_mutes",
    "user_reports",
    "memories",
    "memory_tagged_users",
    "memory_likes",
    "memory_reports",
    "memory_hides",
    "invites",
    "notifications",
    "push_tokens",
    "notification_outbox",
]

REMOVED_TABLES = [
    "drink_logs",
    "drink_invites",
    "drink_log_reports",
    "feed_hidden_drink_logs",
]


@dataclass
class HTTPResult:
    status: int
    body: str


def env(name: str, required: bool = True) -> str:
    value = os.environ.get(name, "").strip()
    if required and not value:
        raise SystemExit(f"{name} is required")
    return value


def request(method: str, url: str, *, api_key: str, bearer: str | None = None, body: object | None = None) -> HTTPResult:
    headers = {"apikey": api_key, "Accept": "application/json"}
    if bearer:
        headers["Authorization"] = f"Bearer {bearer}"
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    else:
        data = None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return HTTPResult(resp.status, resp.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        return HTTPResult(e.code, e.read().decode("utf-8", "replace"))


def sign_in(supabase_url: str, publishable_key: str, email: str, password: str) -> tuple[str, str]:
    result = request(
        "POST",
        f"{supabase_url}/auth/v1/token?grant_type=password",
        api_key=publishable_key,
        body={"email": email, "password": password},
    )
    if result.status != 200:
        raise SystemExit(f"sign-in failed for {email}: HTTP {result.status}")
    payload = json.loads(result.body)
    return payload["access_token"], payload["user"]["id"]


def rest_url(supabase_url: str, table: str, select: str = "*") -> str:
    query = urllib.parse.urlencode({"select": select, "limit": "1"})
    return f"{supabase_url}/rest/v1/{table}?{query}"


def main() -> int:
    supabase_url = env("SUPABASE_URL").rstrip("/")
    publishable_key = env("SUPABASE_PUBLISHABLE_KEY")
    service_role_key = env("SUPABASE_SERVICE_ROLE_KEY", required=False)
    email = env("TOMO_SMOKE_EMAIL", required=False) or env("TOMO_TEST_EMAIL", required=False)
    password = env("TOMO_SMOKE_PASSWORD", required=False) or env("TOMO_TEST_PASSWORD", required=False)

    checks: list[tuple[str, bool, str]] = []

    def record(name: str, passed: bool, detail: str) -> None:
        checks.append((name, passed, detail))
        print(("PASS" if passed else "FAIL") + f" {name}: {detail}")

    token = None
    if email and password:
        token, user_id = sign_in(supabase_url, publishable_key, email, password)
        record("auth.sign_in", True, f"user_id={user_id}")
    else:
        print("SKIP auth.sign_in: TOMO_SMOKE_EMAIL/PASSWORD not set")

    # Public/anon should not be able to read app data tables.
    anon_profiles = request("GET", rest_url(supabase_url, "profiles", "id"), api_key=publishable_key)
    record("anon.profiles.denied", anon_profiles.status in {401, 403, 404}, f"http={anon_profiles.status}")

    if token:
        for table in ["profiles", "memories", "invites", "friend_groups", "user_blocks", "memory_hides"]:
            result = request("GET", rest_url(supabase_url, table, "*"), api_key=publishable_key, bearer=token)
            record(f"authenticated.{table}.reachable", 200 <= result.status < 300, f"http={result.status}")
        outbox = request("GET", rest_url(supabase_url, "notification_outbox", "id"), api_key=publishable_key, bearer=token)
        record("authenticated.notification_outbox.denied", outbox.status in {401, 403, 404}, f"http={outbox.status}")

    if service_role_key:
        for table in REQUIRED_TABLES:
            result = request("GET", rest_url(supabase_url, table, "*"), api_key=service_role_key, bearer=service_role_key)
            record(f"service_role.{table}.reachable", 200 <= result.status < 300, f"http={result.status}")
        for table in REMOVED_TABLES:
            result = request("GET", rest_url(supabase_url, table, "*"), api_key=service_role_key, bearer=service_role_key)
            record(f"service_role.{table}.removed", result.status in {400, 404}, f"http={result.status}")
    else:
        print("SKIP service_role table checks: SUPABASE_SERVICE_ROLE_KEY not set")

    failed = [name for name, passed, _ in checks if not passed]
    if failed:
        print("\nRuntime Supabase contract FAILED:")
        for name in failed:
            print(f"- {name}")
        return 1
    print("\nRuntime Supabase contract OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
