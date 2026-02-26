#!/usr/bin/env python3
"""Build deterministic AGENTS job-description content from canonical spec sources."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path
from typing import Dict, List

REQUIRED_SECTION_KEYS: List[str] = [
    "mission",
    "responsibilities",
    "non_responsibilities",
    "authority_boundaries",
    "required_workflow",
    "escalation_triggers",
    "prohibited_actions",
    "output_quality_standards",
]

OPTIONAL_SECTION_KEYS: List[str] = ["required_protocol_includes"]
ALL_KEYS = REQUIRED_SECTION_KEYS + OPTIONAL_SECTION_KEYS

SECTION_TITLES = {
    "mission": "Mission",
    "responsibilities": "Responsibilities",
    "non_responsibilities": "Non-Responsibilities",
    "authority_boundaries": "Authority Boundaries and Approval Limits",
    "required_workflow": "Required Workflow",
    "escalation_triggers": "Escalation Triggers",
    "prohibited_actions": "Prohibited Actions",
    "output_quality_standards": "Output and Quality Standards",
}


def err(msg: str) -> None:
    print(f"Error: {msg}", file=sys.stderr)


def default_role_name(role_slug: str) -> str:
    names = {
        "implementation-specialist": "Implementation Specialist",
        "compliance-officer": "Compliance Officer",
    }
    if role_slug in names:
        return names[role_slug]
    return role_slug.replace("-", " ").title()


def load_json(path: Path) -> Dict[str, List[str]]:
    if not path.is_file():
        raise FileNotFoundError(f"Missing spec file: {path}")

    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Spec must be a JSON object: {path}")

    for key, value in data.items():
        if key not in ALL_KEYS:
            raise ValueError(f"Unknown key '{key}' in {path}")
        if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
            raise ValueError(f"Key '{key}' must be an array of strings in {path}")

    return data  # type: ignore[return-value]


def load_contract_lock(path: Path) -> Dict[str, object]:
    if not path.is_file():
        raise FileNotFoundError(f"Missing contract lock file: {path}")

    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Contract lock must be a JSON object: {path}")
    return data


def dedupe_preserve_order(items: List[str]) -> List[str]:
    seen = set()
    out: List[str] = []
    for item in items:
        normalized = item.strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        out.append(normalized)
    return out


def merge_specs(global_spec: Dict[str, List[str]], role_spec: Dict[str, List[str]]) -> Dict[str, List[str]]:
    merged: Dict[str, List[str]] = {}
    for key in ALL_KEYS:
        merged[key] = dedupe_preserve_order(global_spec.get(key, []) + role_spec.get(key, []))

    missing = [key for key in REQUIRED_SECTION_KEYS if not merged.get(key)]
    if missing:
        raise ValueError(f"Merged spec missing required non-empty sections: {', '.join(missing)}")

    return merged


def require_file(path: Path) -> None:
    if not path.is_file():
        raise FileNotFoundError(f"Required source file missing: {path}")


def render_list_section(lines: List[str], title: str, items: List[str]) -> None:
    lines.append(f"## {title}")
    lines.append("")
    for item in items:
        lines.append(f"- {item}")
    lines.append("")


def render_protocol_includes(lines: List[str], repo_root: Path, include_paths: List[str]) -> None:
    if not include_paths:
        return

    lines.append("## Required Protocol Includes")
    lines.append("")

    for include_rel in include_paths:
        include_path = repo_root / include_rel
        require_file(include_path)

        lines.append(f"### `{include_rel}`")
        lines.append("")
        lines.append(include_path.read_text(encoding="utf-8").rstrip())
        lines.append("")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build role AGENTS job-description content from structured specs.")
    parser.add_argument("--role-slug", required=True)
    parser.add_argument("--role-name", default="")
    parser.add_argument("--source-ref", default="unknown")
    parser.add_argument("--generated-at-utc", default="")
    parser.add_argument("--repo-root", default="")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    script_dir = Path(__file__).resolve().parent
    repo_root = Path(args.repo_root).resolve() if args.repo_root else script_dir.parents[3]

    role_slug = args.role_slug
    role_name = args.role_name or default_role_name(role_slug)
    generated_at_utc = args.generated_at_utc or dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    global_spec_path = repo_root / "10-templates/job-description-spec/global.json"
    role_spec_path = repo_root / f"10-templates/job-description-spec/roles/{role_slug}.json"

    governance_file = repo_root / "contracts/upstream/governance.md"
    charter_file = repo_root / f"00-os/role-charters/{role_slug}.md"
    base_instructions_file = repo_root / "10-templates/agent-instructions/base.md"
    role_instructions_file = repo_root / f"10-templates/agent-instructions/roles/{role_slug}.md"
    contract_lock_file = repo_root / "contracts/governance-contract-lock.json"

    try:
        require_file(governance_file)
        require_file(charter_file)
        require_file(base_instructions_file)
        require_file(role_instructions_file)
        contract_lock = load_contract_lock(contract_lock_file)
        global_spec = load_json(global_spec_path)
        role_spec = load_json(role_spec_path)
        merged = merge_specs(global_spec, role_spec)
    except Exception as exc:  # pylint: disable=broad-except
        err(str(exc))
        return 1

    lines: List[str] = [
        "# Agent Job Description",
        "",
        f"Role: {role_name}",
        f"Role-Slug: {role_slug}",
        "Source-Repo: Context-Engineering-Implementation",
        f"Source-Ref: {args.source_ref}",
        f"Governance-Contract-Version: {contract_lock.get('contract_version', 'unknown')}",
        f"Governance-Source-Commit: {contract_lock.get('source_commit', 'unknown')}",
        f"Generated-At-UTC: {generated_at_utc}",
        "Job-Description-Spec-Version: 1",
        "",
    ]

    for key in REQUIRED_SECTION_KEYS:
        render_list_section(lines, SECTION_TITLES[key], merged[key])

    lines.append("## Source Metadata")
    lines.append("")
    lines.append("- Canonical source chain (authoritative order):")
    lines.append("  1. `contracts/upstream/governance.md`")
    lines.append("  2. `00-os/role-charters/`")
    lines.append("  3. `10-templates/agent-instructions/`")
    lines.append("  4. `10-templates/job-description-spec/`")
    lines.append("  5. `contracts/governance-contract-lock.json`")
    lines.append("- Assembly inputs:")
    lines.append("  - `10-templates/job-description-spec/global.json`")
    lines.append(f"  - `10-templates/job-description-spec/roles/{role_slug}.json`")
    lines.append(f"  - `00-os/role-charters/{role_slug}.md`")
    lines.append("  - `10-templates/agent-instructions/base.md`")
    lines.append(f"  - `10-templates/agent-instructions/roles/{role_slug}.md`")
    lines.append("  - `contracts/upstream/governance.md`")
    lines.append("  - `contracts/governance-contract-lock.json`")
    lines.append(f"- Builder: `10-templates/repo-starters/role-repo-template/scripts/{Path(__file__).name}`")
    lines.append("")

    try:
        render_protocol_includes(lines, repo_root, merged.get("required_protocol_includes", []))
    except Exception as exc:  # pylint: disable=broad-except
        err(str(exc))
        return 1

    sys.stdout.write("\n".join(lines).rstrip() + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
