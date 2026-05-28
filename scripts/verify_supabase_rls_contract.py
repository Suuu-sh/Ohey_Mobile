#!/usr/bin/env python3
"""Static contract checks for Tomo Supabase migrations.

This does not apply migrations. It verifies that the migration files contain the
RLS/grant/index contract for tables that are easy to accidentally expose while
moving backend-owned features out of Mobile.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

CHECKS = {
    "friend_groups": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.friend_groups",
            r"alter\s+table\s+public\.friend_groups\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+friend_groups_select_owner",
            r"create\s+policy\s+friend_groups_insert_owner",
            r"create\s+policy\s+friend_groups_update_owner",
            r"create\s+policy\s+friend_groups_delete_owner",
            r"grant\s+select\s*,\s*insert\s*,\s*update\s*,\s*delete\s+on\s+public\.friend_groups\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.friend_groups\s+to\s+anon"],
    },
    "friend_group_members": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.friend_group_members",
            r"alter\s+table\s+public\.friend_group_members\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+friend_group_members_select_owner",
            r"create\s+policy\s+friend_group_members_insert_owner_friend",
            r"create\s+policy\s+friend_group_members_delete_owner",
            r"grant\s+select\s*,\s*insert\s*,\s*delete\s+on\s+public\.friend_group_members\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.friend_group_members\s+to\s+anon"],
    },
    "memories": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.memories",
            r"alter\s+table\s+public\.memories\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+memories_select_feed_visible",
            r"create\s+policy\s+memories_insert_own",
            r"create\s+policy\s+memories_delete_own",
            r"grant\s+select\s*,\s*insert\s*,\s*update\s*,\s*delete\s+on\s+public\.memories\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.memories\s+to\s+anon"],
    },
    "memory_tagged_users": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.memory_tagged_users",
            r"alter\s+table\s+public\.memory_tagged_users\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+memory_tagged_users_select_visible",
            r"create\s+policy\s+memory_tagged_users_insert_owner_friend",
            r"create\s+policy\s+memory_tagged_users_delete_owner",
            r"grant\s+select\s*,\s*insert\s*,\s*delete\s+on\s+public\.memory_tagged_users\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.memory_tagged_users\s+to\s+anon"],
    },
    "memory_reports": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.memory_reports",
            r"alter\s+table\s+public\.memory_reports\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+memory_reports_insert_own",
            r"create\s+policy\s+memory_reports_select_own",
            r"memory_reports_reason_check",
            r"memory_reports_status_check",
            r"memory_reports_status_created_at_idx",
            r"memory_reports_reporter_hidden_idx",
            r"status\s+in\s*\(\s*'pending'\s*,\s*'reviewing'\s*,\s*'resolved'\s*,\s*'dismissed'\s*\)",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.memory_reports\s+to\s+anon"],
    },
    "notification_outbox": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.notification_outbox",
            r"alter\s+table\s+public\.notification_outbox\s+enable\s+row\s+level\s+security",
            r"revoke\s+all\s+on(?:\s+table)?\s+public\.notification_outbox\s+from\s+anon\s*,\s*authenticated",
            r"grant\s+all\s+on(?:\s+table)?\s+public\.notification_outbox\s+to\s+service_role",
            r"notification_outbox_status_next_attempt_idx",
        ],
        "forbidden": [
            r"grant\s+.*\s+on\s+public\.notification_outbox\s+to\s+anon",
            r"grant\s+.*\s+on\s+public\.notification_outbox\s+to\s+authenticated",
        ],
    },
    "user_blocks": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.user_blocks",
            r"alter\s+table\s+public\.user_blocks\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+user_blocks_select_participant",
            r"create\s+policy\s+user_blocks_insert_owner",
            r"create\s+policy\s+user_blocks_delete_owner",
            r"grant\s+select\s*,\s*insert\s*,\s*delete\s+on\s+public\.user_blocks\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.user_blocks\s+to\s+anon"],
    },
    "user_mutes": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.user_mutes",
            r"alter\s+table\s+public\.user_mutes\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+user_mutes_select_owner",
            r"create\s+policy\s+user_mutes_insert_owner",
            r"create\s+policy\s+user_mutes_delete_owner",
            r"grant\s+select\s*,\s*insert\s*,\s*delete\s+on\s+public\.user_mutes\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.user_mutes\s+to\s+anon"],
    },
    "memory_hides": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.memory_hides",
            r"alter\s+table\s+public\.memory_hides\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+memory_hides_select_owner",
            r"create\s+policy\s+memory_hides_insert_owner",
            r"create\s+policy\s+memory_hides_delete_owner",
            r"grant\s+select\s*,\s*insert\s*,\s*delete\s+on\s+public\.memory_hides\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.memory_hides\s+to\s+anon"],
    },
    "push_tokens": {
        "required": [
            r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.push_tokens",
            r"alter\s+table\s+public\.push_tokens\s+enable\s+row\s+level\s+security",
            r"create\s+policy\s+\"?push_tokens_select_own\"?",
            r"create\s+policy\s+\"?push_tokens_insert_own\"?",
            r"create\s+policy\s+\"?push_tokens_update_own\"?",
            r"grant\s+select\s*,\s*insert\s*,\s*update\s+on\s+public\.push_tokens\s+to\s+authenticated",
        ],
        "forbidden": [r"grant\s+.*\s+on\s+public\.push_tokens\s+to\s+anon"],
    },
}

BASELINE_REQUIRED_PATTERNS = [
    r"create\s+or\s+replace\s+function\s+private\.handle_new_user",
    r"create\s+trigger\s+on_auth_user_created",
    r"create\s+or\s+replace\s+function\s+private\.handle_friend_request_accepted",
    r"insert\s+into\s+storage\.buckets",
    r"delete\s+from\s+public\.app_schema_migrations",
]

BASELINE_FORBIDDEN_PATTERNS = [
    r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.drink_",
    r"create\s+table\s+(?:if\s+not\s+exists\s+)?public\.feed_hidden_drink_logs",
    r"create\s+policy\s+[^;]*drink_",
    r"grant\s+[^;]*public\.drink_",
    r"create\s+or\s+replace\s+function\s+public\.profile_is_plus_unchanged",
    r"grant\s+[^;]*public\.profile_is_plus_unchanged",
]


def normalize(sql: str) -> str:
    sql = re.sub(r"--.*", "", sql)
    return re.sub(r"\s+", " ", sql.lower()).strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--migrations-dir",
        default=str(Path(__file__).resolve().parents[1] / "supabase" / "migrations"),
    )
    args = parser.parse_args()
    migrations_dir = Path(args.migrations_dir)
    files = sorted(migrations_dir.glob("*.sql"))
    if not files:
        print(f"ERROR: no migration files found in {migrations_dir}", file=sys.stderr)
        return 1

    sql = normalize("\n".join(path.read_text() for path in files))
    failures: list[str] = []

    if len(files) != 1:
        failures.append(f"baseline: expected exactly 1 migration file, found {len(files)}")

    for pattern in BASELINE_REQUIRED_PATTERNS:
        if not re.search(pattern, sql, flags=re.IGNORECASE):
            failures.append(f"baseline: missing required pattern: {pattern}")
    for pattern in BASELINE_FORBIDDEN_PATTERNS:
        if re.search(pattern, sql, flags=re.IGNORECASE):
            failures.append(f"baseline: forbidden pattern matched: {pattern}")

    for table, spec in CHECKS.items():
        for pattern in spec["required"]:
            if not re.search(pattern, sql, flags=re.IGNORECASE):
                failures.append(f"{table}: missing required pattern: {pattern}")
        for pattern in spec["forbidden"]:
            if re.search(pattern, sql, flags=re.IGNORECASE):
                failures.append(f"{table}: forbidden pattern matched: {pattern}")

    if failures:
        print("Supabase RLS contract FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Supabase RLS contract OK")
    print(f"checked_migrations={len(files)}")
    print("checked_tables=" + ",".join(CHECKS.keys()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
