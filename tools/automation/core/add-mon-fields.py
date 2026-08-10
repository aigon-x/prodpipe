#!/usr/bin/env python3
"""Add MON-* fields to each pipeline entry in pipelines.yaml.

Inserts the MON-* block after each `contract:` line within the `pipelines:`
section, preserving all comments and formatting. Idempotent: skips entries
that already have a `schedule:` field.

Usage: python3 add-mon-fields.py [path-to-pipelines.yaml]
"""
import sys
import re

DEFAULT_MON = {
    "schedule": "manual",
    "schedule_spec": '""',
    "control": "[pause, resume, cancel, retry, skip, restart]",
    "monitor": "[status, progress, logs, metrics, dashboard, timeline]",
    "notify": "[dashboard]",
    "timeout": "300",
    "retries": "3",
    "priority": "NORMAL",
}

MON_BLOCK = "\n".join(
    f"    {k}: {v}" for k, v in DEFAULT_MON.items()
)


def main(path: str) -> int:
    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.readlines()

    # Find the `pipelines:` section start.
    pipelines_idx = None
    for i, line in enumerate(lines):
        if re.match(r"^pipelines:\s*$", line):
            pipelines_idx = i
            break
    if pipelines_idx is None:
        print("ERROR: no `pipelines:` section found", file=sys.stderr)
        return 1

    out = []
    added = 0
    skipped = 0
    in_pipelines = False
    for i, line in enumerate(lines):
        out.append(line)
        if i == pipelines_idx:
            in_pipelines = True
            continue
        if not in_pipelines:
            continue
        # Stop at the next top-level key (non-indented, non-comment).
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*:\s*$", line) and i > pipelines_idx:
            in_pipelines = False
            continue
        # Detect end of a pipeline entry: a `contract:` line.
        if re.match(r"^    contract: \[", line):
            # Check if the next non-comment line already has schedule: (idempotent)
            j = i + 1
            already = False
            while j < len(lines):
                nxt = lines[j].strip()
                if nxt.startswith("#") or nxt == "":
                    j += 1
                    continue
                if nxt.startswith("schedule:"):
                    already = True
                break
            if already:
                skipped += 1
            else:
                out.append("\n")
                out.append(MON_BLOCK + "\n")
                added += 1

    with open(path, "w", encoding="utf-8") as fh:
        fh.writelines(out)

    print(f"OK: added MON-* fields to {added} pipelines, skipped {skipped} (already present)")
    return 0


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "config/canonical/pipelines.yaml"
    sys.exit(main(path))
