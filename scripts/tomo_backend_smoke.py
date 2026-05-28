#!/usr/bin/env python3
"""Backend smoke test for Tomo dev/prod environments.

Required env:
  TOMO_BACKEND_URL
  SUPABASE_URL
  SUPABASE_PUBLISHABLE_KEY
  TOMO_SMOKE_EMAIL
  TOMO_SMOKE_PASSWORD
Optional env for invite flow:
  TOMO_SMOKE_OTHER_EMAIL
  TOMO_SMOKE_OTHER_PASSWORD
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any


@dataclass
class HTTPResult:
    status: int
    body: str


def env(name: str, required: bool = True) -> str:
    value = os.environ.get(name, "").strip()
    if required and not value:
        raise SystemExit(f"{name} is required")
    return value


def request(method: str, url: str, *, headers: dict[str, str] | None = None, body: object | None = None) -> HTTPResult:
    req_headers = {"Accept": "application/json", **(headers or {})}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        req_headers["Content-Type"] = "application/json"
    else:
        data = None
    req = urllib.request.Request(url, data=data, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            return HTTPResult(resp.status, resp.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        return HTTPResult(e.code, e.read().decode("utf-8", "replace"))


def supabase_request(method: str, supabase_url: str, key: str, path: str, body: object | None = None) -> HTTPResult:
    return request(method, f"{supabase_url}{path}", headers={"apikey": key}, body=body)


def sign_in(supabase_url: str, publishable_key: str, email: str, password: str) -> tuple[str, str]:
    result = supabase_request(
        "POST",
        supabase_url,
        publishable_key,
        "/auth/v1/token?grant_type=password",
        {"email": email, "password": password},
    )
    if result.status != 200:
        raise SystemExit(f"sign-in failed for {email}: HTTP {result.status}")
    payload = json.loads(result.body)
    return payload["access_token"], payload["user"]["id"]


def expect(checks: list[tuple[str, bool, str]], name: str, result: HTTPResult, statuses: set[int]) -> Any:
    ok = result.status in statuses
    checks.append((name, ok, f"http={result.status}"))
    print(("PASS" if ok else "FAIL") + f" {name}: http={result.status}")
    if ok and result.body:
        try:
            return json.loads(result.body)
        except json.JSONDecodeError:
            return None
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mutating", action="store_true", help="create/update/delete temporary smoke data")
    parser.add_argument("--invite", action="store_true", help="also create/accept an invite using TOMO_SMOKE_OTHER_* credentials")
    args = parser.parse_args()

    backend_url = env("TOMO_BACKEND_URL").rstrip("/")
    supabase_url = env("SUPABASE_URL").rstrip("/")
    publishable_key = env("SUPABASE_PUBLISHABLE_KEY")
    email = env("TOMO_SMOKE_EMAIL")
    password = env("TOMO_SMOKE_PASSWORD")

    token, user_id = sign_in(supabase_url, publishable_key, email, password)
    auth_headers = {"Authorization": f"Bearer {token}", "X-Tomo-User-ID": user_id}
    checks: list[tuple[str, bool, str]] = []

    health = request("GET", f"{backend_url}/healthz")
    expect(checks, "healthz", health, {200})

    today = dt.date.today().isoformat()
    month = today[:7]
    readonly_paths = [
        "/v1/me/profile",
        f"/v1/daily-status?date={today}",
        f"/v1/daily-statuses/month?month={month}",
        "/v1/friends",
        "/v1/friend-groups",
        "/v1/home/feed?limit=10",
        "/v1/memories",
        "/v1/notifications",
        f"/v1/invites/today-reservations?date={today}",
        f"/v1/invites/incoming-pending?date={today}",
        f"/v1/invites/outgoing-active?date={today}",
    ]
    for path in readonly_paths:
        expect(checks, f"GET {path}", request("GET", f"{backend_url}{path}", headers=auth_headers), {200})

    created_memory_id = ""
    if args.mutating:
        expect(
            checks,
            "PUT /v1/daily-status",
            request("PUT", f"{backend_url}/v1/daily-status", headers=auth_headers, body={"status_date": today, "status": "available"}),
            {200, 201},
        )
        expect(
            checks,
            "POST /v1/media/upload-url",
            request(
                "POST",
                f"{backend_url}/v1/media/upload-url",
                headers=auth_headers,
                body={"kind": "memory_photo", "content_type": "image/jpeg", "file_extension": ".jpg"},
            ),
            {201},
        )
        memory = expect(
            checks,
            "POST /v1/memories",
            request(
                "POST",
                f"{backend_url}/v1/memories",
                headers=auth_headers,
                body={"happened_at": dt.datetime.now(dt.timezone.utc).isoformat(), "memo": "Tomo smoke test"},
            ),
            {201, 409},
        )
        if isinstance(memory, dict):
            created_memory_id = str(memory.get("id") or "")
        if not created_memory_id:
            print("SKIP memory like/hide/report/delete: create returned no id, likely daily-limit conflict")
        if created_memory_id:
            expect(checks, "PUT /v1/memories/{id}/like", request("PUT", f"{backend_url}/v1/memories/{created_memory_id}/like", headers=auth_headers), {200})
            expect(checks, "DELETE /v1/memories/{id}/like", request("DELETE", f"{backend_url}/v1/memories/{created_memory_id}/like", headers=auth_headers), {200})
            expect(checks, "POST /v1/memory-hides", request("POST", f"{backend_url}/v1/memory-hides", headers=auth_headers, body={"memory_id": created_memory_id}), {200, 201})
            expect(checks, "DELETE /v1/memory-hides/{id}", request("DELETE", f"{backend_url}/v1/memory-hides/{created_memory_id}", headers=auth_headers), {200, 204})
            expect(checks, "POST /v1/memories/{id}/report", request("POST", f"{backend_url}/v1/memories/{created_memory_id}/report", headers=auth_headers, body={"reason": "other"}), {200, 201})
            expect(checks, "DELETE /v1/memories/{id}", request("DELETE", f"{backend_url}/v1/memories/{created_memory_id}", headers=auth_headers), {200})

    if args.invite:
        other_email = env("TOMO_SMOKE_OTHER_EMAIL")
        other_password = env("TOMO_SMOKE_OTHER_PASSWORD")
        other_token, other_user_id = sign_in(supabase_url, publishable_key, other_email, other_password)
        invite_date = (dt.date.today() + dt.timedelta(days=7)).isoformat()
        invite = expect(
            checks,
            "POST /v1/invites",
            request("POST", f"{backend_url}/v1/invites", headers=auth_headers, body={"invitee_user_id": other_user_id, "scheduled_date": invite_date}),
            {201, 409},
        )
        if isinstance(invite, dict) and invite.get("id"):
            other_headers = {"Authorization": f"Bearer {other_token}", "X-Tomo-User-ID": other_user_id}
            expect(
                checks,
                "PATCH /v1/invites/{id}",
                request("PATCH", f"{backend_url}/v1/invites/{invite['id']}", headers=other_headers, body={"status": "accepted"}),
                {200},
            )

    failed = [name for name, ok, _ in checks if not ok]
    if failed:
        print("\nBackend smoke FAILED:")
        for name in failed:
            print(f"- {name}")
        return 1
    print("\nBackend smoke OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
