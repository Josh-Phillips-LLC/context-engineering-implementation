#!/usr/bin/env python3

import fnmatch
import sys
from pathlib import Path

RULES = [
    (
        "BND-IMP-001",
        "governance.md",
        "Governance authority document is not allowed in implementation repository.",
        "Move governance.md to context-engineering-governance and reference it via contract.",
    ),
    (
        "BND-IMP-002",
        "context-flow.md",
        "Context-flow governance document is not allowed in implementation repository.",
        "Keep context-flow.md in context-engineering-governance.",
    ),
    (
        "BND-IMP-003",
        "00-os/adr/**",
        "Governance ADR artifacts are not allowed in implementation repository.",
        "Author ADR files only in context-engineering-governance.",
    ),
    (
        "BND-IMP-004",
        "00-os/workflow.md",
        "Governance workflow authority document is not allowed in implementation repository.",
        "Keep governance workflow source in context-engineering-governance.",
    ),
    (
        "BND-IMP-005",
        "00-os/protected-path-policy-map.md",
        "Protected-path policy map authority is not allowed in implementation repository.",
        "Define protected-path policy only in context-engineering-governance.",
    ),
    (
        "BND-IMP-006",
        "contracts/governance-implementation-contract.json",
        "Canonical governance contract source must not live in implementation repository root contracts path.",
        "Keep canonical contract in governance repo; only consume via lock/upstream mirror paths.",
    ),
]


def list_repo_files() -> list[str]:
    files: list[str] = []
    for path in Path(".").rglob("*"):
        if not path.is_file():
            continue
        relative = path.as_posix()
        if relative.startswith("./"):
            relative = relative[2:]
        if relative.startswith(".git/"):
            continue
        files.append(relative)
    return sorted(files)


def main() -> int:
    files = list_repo_files()
    violations: list[str] = []

    for file_path in files:
        for rule_id, pattern, message, remediation in RULES:
            if fnmatch.fnmatch(file_path, pattern):
                violations.append(
                    f"{rule_id} error {file_path} {message} | remediation: {remediation}"
                )

    if violations:
        print("Implementation boundary validation failed:", file=sys.stderr)
        for violation in sorted(violations):
            print(f"- {violation}", file=sys.stderr)
        return 1

    print("Implementation boundary validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
