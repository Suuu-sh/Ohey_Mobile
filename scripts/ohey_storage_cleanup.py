#!/usr/bin/env python3
"""List/delete Supabase Storage objects through the Storage API.

Required env:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY

Default is dry-run. Pass --execute to delete. Deletion is chunked to Supabase's
1000-object Storage API limit.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass


@dataclass
class HTTPResult:
    status: int
    body: str


def env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"{name} is required")
    return value


def request(method: str, url: str, key: str, body: object | None = None) -> HTTPResult:
    headers = {"apikey": key, "Authorization": f"Bearer {key}", "Accept": "application/json"}
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return HTTPResult(resp.status, resp.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        return HTTPResult(e.code, e.read().decode("utf-8", "replace"))


def list_objects(base_url: str, key: str, bucket: str, prefix: str) -> list[str]:
    found: list[str] = []
    offset = 0
    while True:
        body = {"prefix": prefix, "limit": 1000, "offset": offset, "sortBy": {"column": "name", "order": "asc"}}
        result = request("POST", f"{base_url}/storage/v1/object/list/{bucket}", key, body)
        if result.status != 200:
            raise SystemExit(f"list failed for prefix={prefix!r}: HTTP {result.status}")
        rows = json.loads(result.body)
        if not rows:
            break
        for row in rows:
            name = (row.get("name") or "").strip()
            if not name:
                continue
            path = f"{prefix.rstrip('/')}/{name}" if prefix else name
            # Supabase returns pseudo-folders without id/metadata in many projects.
            if row.get("id") is None and row.get("metadata") is None:
                found.extend(list_objects(base_url, key, bucket, path))
            else:
                found.append(path)
        if len(rows) < 1000:
            break
        offset += len(rows)
    return found


def delete_objects(base_url: str, key: str, bucket: str, paths: list[str]) -> None:
    for index in range(0, len(paths), 1000):
        chunk = paths[index : index + 1000]
        result = request("DELETE", f"{base_url}/storage/v1/object/{bucket}", key, {"prefixes": chunk})
        if result.status not in {200, 204}:
            raise SystemExit(f"delete failed for chunk starting {index}: HTTP {result.status}")
        print(f"deleted chunk {index // 1000 + 1}: {len(chunk)} objects")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bucket", default="ohey-photos")
    parser.add_argument("--prefix", default="")
    parser.add_argument("--execute", action="store_true", help="actually delete; default is dry-run")
    args = parser.parse_args()

    base_url = env("SUPABASE_URL").rstrip("/")
    key = env("SUPABASE_SERVICE_ROLE_KEY")
    paths = sorted(set(list_objects(base_url, key, args.bucket, args.prefix.strip("/"))))
    print(f"bucket={args.bucket} prefix={args.prefix!r} objects={len(paths)}")
    for path in paths[:50]:
        print(path)
    if len(paths) > 50:
        print(f"... {len(paths) - 50} more")
    if not args.execute:
        print("dry-run only; pass --execute to delete")
        return 0
    if paths:
        delete_objects(base_url, key, args.bucket, paths)
    print("storage cleanup OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
