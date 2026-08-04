#!/usr/bin/env python3
# Copyright sashiko-shi contributors
# Licensed under the Apache License, Version 2.0
"""Cost report for sashiko-shi review sessions.

Queries the OpenCode SQLite database to calculate token usage and cost
for sashiko-shi review sessions.

Usage:
    # Most recent sashiko-shi session
    python3 scripts/cost-report.py

    # Specific session ID
    python3 scripts/cost-report.py ses_02d8e939fffeKjMr6JzZEwXAHi

    # Last 3 sessions
    python3 scripts/cost-report.py --last 3

    # Custom database path
    python3 scripts/cost-report.py --db /path/to/opencode.db
"""

import argparse
import json
import os
import sqlite3
import sys


def find_database():
    """Find the OpenCode SQLite database."""
    candidates = [
        os.path.expanduser("~/.local/share/opencode/opencode.db"),
        os.path.expanduser("~/.local/share/opencode/storage/opencode.db"),
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return None


def get_children(db, session_id):
    """Get direct child sessions."""
    return db.execute(
        "SELECT id, title, time_created FROM session WHERE parent_id=? "
        "ORDER BY time_created",
        (session_id,),
    ).fetchall()


def get_all_descendants(db, session_id):
    """Recursively get all descendant session IDs."""
    result = [session_id]
    children = db.execute(
        "SELECT id FROM session WHERE parent_id=?", (session_id,)
    ).fetchall()
    for (child_id,) in children:
        result.extend(get_all_descendants(db, child_id))
    return result


def get_session_stats(db, session_id):
    """Sum token usage and cost from step-finish parts in a session."""
    rows = db.execute(
        "SELECT data FROM part WHERE session_id=? "
        "AND data LIKE '%step-finish%'",
        (session_id,),
    ).fetchall()

    stats = {
        "input": 0,
        "output": 0,
        "reasoning": 0,
        "cache_read": 0,
        "cache_write": 0,
        "cost": 0.0,
        "steps": 0,
    }
    for (data,) in rows:
        try:
            d = json.loads(data)
            if d.get("type") != "step-finish":
                continue
            tokens = d.get("tokens", {})
            stats["input"] += tokens.get("input", 0)
            stats["output"] += tokens.get("output", 0)
            stats["reasoning"] += tokens.get("reasoning", 0)
            cache = tokens.get("cache", {})
            stats["cache_read"] += cache.get("read", 0)
            stats["cache_write"] += cache.get("write", 0)
            stats["cost"] += d.get("cost", 0)
            stats["steps"] += 1
        except (json.JSONDecodeError, KeyError):
            pass
    return stats


def get_session_time_range(db, session_id):
    """Get the first and last part timestamps for a session."""
    row = db.execute(
        "SELECT MIN(time_created), MAX(time_created) FROM part "
        "WHERE session_id=?",
        (session_id,),
    ).fetchone()
    return row[0], row[1]


def aggregate_stats(stats_list):
    """Sum a list of stats dicts."""
    total = {
        "input": 0, "output": 0, "reasoning": 0,
        "cache_read": 0, "cache_write": 0,
        "cost": 0.0, "steps": 0,
    }
    for s in stats_list:
        for key in total:
            total[key] += s[key]
    return total


def find_sashiko_sessions(db, last_n=1):
    """Find the most recent sashiko-shi top-level sessions.

    Matches sessions by title containing 'sashiko', or by having a
    child session that is a sashiko-shi subagent (for cases where the
    user's title doesn't mention sashiko-shi).
    """
    return db.execute(
        "SELECT id, title, time_created FROM session "
        "WHERE (parent_id IS NULL OR parent_id = '') "
        "AND (title LIKE '%sashiko%' "
        "     OR id IN (SELECT parent_id FROM session "
        "              WHERE title LIKE '%@sashiko-shi %')) "
        "ORDER BY time_created DESC LIMIT ?",
        (last_n,),
    ).fetchall()


def extract_commit_issues(db, orchestrator_id):
    """Extract issue count from the orchestrator's output text."""
    rows = db.execute(
        "SELECT data FROM part WHERE session_id=? "
        "AND data LIKE '%text%' ORDER BY time_created DESC LIMIT 10",
        (orchestrator_id,),
    ).fetchall()

    for (data,) in rows:
        try:
            d = json.loads(data)
            if d.get("type") != "text":
                continue
            text = d.get("text", "")
            if "No regressions found" in text:
                return 0, "none"
            if "Issues found:" in text:
                for line in text.split("\n"):
                    if "Issues found:" in line:
                        parts = line.split("Issues found:")[1].strip()
                        count = int(parts.split()[0])
                        severity = "unknown"
                        if "(" in parts and ")" in parts:
                            severity = parts.split("(")[1].split(")")[0]
                        return count, severity
        except (json.JSONDecodeError, ValueError):
            pass
    return -1, "unknown"


def fmt_tokens(n):
    """Format a token count with commas."""
    return f"{n:,}"


def fmt_cost(c):
    """Format a cost value."""
    return f"${c:.2f}"


def fmt_duration(ms):
    """Format milliseconds as minutes."""
    if ms is None or ms <= 0:
        return "?"
    minutes = ms / 1000 / 60
    if minutes < 1:
        return f"{ms/1000:.0f}s"
    return f"{minutes:.1f}m"


def report_session(db, session_id, title, start_ts):
    """Generate a full cost report for one review session."""

    print("sashiko-shi cost report")
    print("=" * 60)
    print()
    print(f"Session:  {session_id}")
    print(f"Title:    {title}")

    # Find the overall time range
    all_sessions = get_all_descendants(db, session_id)
    all_starts = []
    all_ends = []
    for sid in all_sessions:
        s, e = get_session_time_range(db, sid)
        if s is not None:
            all_starts.append(s)
        if e is not None:
            all_ends.append(e)

    if all_starts and all_ends:
        duration_ms = max(all_ends) - min(all_starts)
        print(f"Duration: {fmt_duration(duration_ms)}")
    print()

    # Classify sessions by level
    primary_ids = [session_id]
    coordinator_ids = []
    orchestrator_ids = []
    stage_ids = []

    coordinator_children = get_children(db, session_id)
    for cid, ctitle, _ in coordinator_children:
        coordinator_ids.append(cid)
        orchestrator_children = get_children(db, cid)
        for oid, otitle, _ in orchestrator_children:
            orchestrator_ids.append((oid, otitle))
            stage_children = get_children(db, oid)
            for sid, stitle, _ in stage_children:
                stage_ids.append(sid)

    total_sessions = (
        len(primary_ids) + len(coordinator_ids)
        + len(orchestrator_ids) + len(stage_ids)
    )

    # Aggregate totals
    all_stats = []
    for sid in all_sessions:
        all_stats.append(get_session_stats(db, sid))
    total = aggregate_stats(all_stats)

    # Overview
    print("Overview")
    print("-" * 40)
    print(f"  Sessions:   {total_sessions}")
    print(f"  Steps:      {fmt_tokens(total['steps'])}")
    print(f"  Cost:       {fmt_cost(total['cost'])}")
    print()

    # Tokens
    print("Tokens")
    print("-" * 40)
    print(f"  Input:        {fmt_tokens(total['input']):>14}")
    print(f"  Output:       {fmt_tokens(total['output']):>14}")
    if total["reasoning"] > 0:
        print(f"  Reasoning:    {fmt_tokens(total['reasoning']):>14}")
    print(f"  Cache read:   {fmt_tokens(total['cache_read']):>14}")
    print(f"  Cache write:  {fmt_tokens(total['cache_write']):>14}")
    print()

    # Cost by level
    print("Cost by level")
    print("-" * 40)

    levels = [
        ("Primary", primary_ids),
        ("Coordinator", [cid for cid in coordinator_ids]),
        ("Orchestrators", [oid for oid, _ in orchestrator_ids]),
        ("Stages", stage_ids),
    ]

    for level_name, sids in levels:
        level_stats = [get_session_stats(db, sid) for sid in sids]
        level_total = aggregate_stats(level_stats)
        print(
            f"  {level_name + ':':15s} {fmt_cost(level_total['cost']):>8}  "
            f"({len(sids)} sessions, "
            f"{fmt_tokens(level_total['steps'])} steps)"
        )
    print()

    # Per-commit breakdown (if there are orchestrators)
    if orchestrator_ids:
        print("Cost by commit")
        print("-" * 40)

        commit_costs = []
        for oid, otitle in orchestrator_ids:
            # Get orchestrator + all its stage children stats
            orch_descendants = get_all_descendants(db, oid)
            orch_stats = [get_session_stats(db, sid) for sid in orch_descendants]
            orch_total = aggregate_stats(orch_stats)

            # Duration
            o_start, o_end = get_session_time_range(db, oid)
            duration = (o_end - o_start) if o_start and o_end else 0

            # Extract commit info from title
            # Title format: "Review commit N/M: <sha> (@sashiko-shi-orchestrator subagent)"
            short_sha = ""
            if ":" in otitle:
                after_colon = otitle.split(":", 1)[1].strip()
                short_sha = after_colon.split()[0] if after_colon else ""

            # Extract commit number
            commit_num = ""
            if "/" in otitle:
                before_colon = otitle.split(":")[0]
                for part in before_colon.split():
                    if "/" in part:
                        commit_num = part
                        break

            # Issue count
            issues, severity = extract_commit_issues(db, oid)

            issue_str = ""
            if issues == 0:
                issue_str = "0 issues"
            elif issues > 0:
                issue_str = f"{issues} issue{'s' if issues != 1 else ''} ({severity})"
            else:
                issue_str = "?"

            commit_costs.append(orch_total["cost"])

            # Get subject from the orchestrator's first text part
            subject = ""
            first_text = db.execute(
                "SELECT data FROM part WHERE session_id=? "
                "AND data LIKE '%REVIEW:%' ORDER BY time_created DESC LIMIT 1",
                (oid,),
            ).fetchone()
            if first_text:
                try:
                    d = json.loads(first_text[0])
                    text = d.get("text", "")
                    for line in text.split("\n"):
                        if "REVIEW:" in line and '"' in line:
                            subject = line.split('"')[1][:50]
                            break
                except (json.JSONDecodeError, IndexError):
                    pass

            label = f"{commit_num} {short_sha}"
            print(
                f"  {label:20s} "
                f"{fmt_cost(orch_total['cost']):>8}  "
                f"{fmt_duration(duration):>6}  "
                f"{issue_str}"
            )

        # Subtotals
        per_commit_total = sum(commit_costs)
        coordination = total["cost"] - per_commit_total
        n = len(orchestrator_ids)
        print(f"  {'':20s} {'------':>8}")
        print(f"  {'Per-commit total:':20s} {fmt_cost(per_commit_total):>8}  ({n} commits)")
        print(f"  {'Coordination:':20s} {fmt_cost(coordination):>8}  (primary + series coordinator)")
        print(f"  {'Total:':20s} {fmt_cost(total['cost']):>8}")
        print()

        # Per-commit average
        avg_cost = total["cost"] / len(orchestrator_ids)
        print(f"  Average per commit: {fmt_cost(avg_cost)}")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="Cost report for sashiko-shi review sessions."
    )
    parser.add_argument(
        "session_id",
        nargs="?",
        help="Session ID to report on (default: most recent)",
    )
    parser.add_argument(
        "--last",
        type=int,
        default=1,
        help="Report on the last N sashiko-shi sessions (default: 1)",
    )
    parser.add_argument(
        "--db",
        help="Path to OpenCode database",
    )
    args = parser.parse_args()

    db_path = args.db or find_database()
    if not db_path:
        print(
            "Error: Could not find OpenCode database. "
            "Use --db to specify the path.",
            file=sys.stderr,
        )
        sys.exit(1)

    db = sqlite3.connect(db_path)

    if args.session_id:
        sessions = db.execute(
            "SELECT id, title, time_created FROM session WHERE id=?",
            (args.session_id,),
        ).fetchall()
        if not sessions:
            print(f"Error: Session {args.session_id} not found.", file=sys.stderr)
            sys.exit(1)
    else:
        sessions = find_sashiko_sessions(db, args.last)
        if not sessions:
            print("No sashiko-shi sessions found.", file=sys.stderr)
            sys.exit(1)

    for i, (session_id, title, start_ts) in enumerate(sessions):
        if i > 0:
            print()
            print("=" * 60)
            print()
        report_session(db, session_id, title, start_ts)

    db.close()


if __name__ == "__main__":
    main()
