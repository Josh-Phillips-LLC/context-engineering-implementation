#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path

UPSTREAM_CONTRACT_PATH = Path("contracts/upstream/governance-implementation-contract.json")
LOCK_PATH = Path("contracts/governance-contract-lock.json")
CONTRACT_BOUNDARY_PATH = Path("CONTRACT_BOUNDARY.md")
VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")

BOUNDARY_BLOCKED_PATHS = (
    Path("governance.md"),
    Path("context-flow.md"),
    Path("00-os/adr"),
)


def fail(message: str) -> int:
    print(f"Contract consumption validation failed: {message}", file=sys.stderr)
    return 1


def load_json(path: Path, label: str):
    if not path.exists():
        raise RuntimeError(f"missing {label}: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"invalid JSON in {label} ({path}): {exc}") from exc


def parse_semver(version: str, label: str):
    match = VERSION_RE.fullmatch(version)
    if match is None:
        raise RuntimeError(f"{label} must be semantic version format X.Y.Z (got '{version}')")
    return tuple(int(part) for part in match.groups())


def main() -> int:
    try:
        upstream = load_json(UPSTREAM_CONTRACT_PATH, "upstream contract")
        lock = load_json(LOCK_PATH, "lock file")
    except RuntimeError as exc:
        return fail(str(exc))

    for key in ("contract_id", "version", "compatibility", "governance_authoritative_paths"):
        if key not in upstream:
            return fail(f"upstream contract missing key '{key}'")

    for key in ("contract_version", "supported_major", "source_commit"):
        if key not in lock:
            return fail(f"lock file missing key '{key}'")

    upstream_version = upstream.get("version")
    lock_version = lock.get("contract_version")

    if not isinstance(upstream_version, str):
        return fail("upstream contract 'version' must be a string")
    if not isinstance(lock_version, str):
        return fail("lock 'contract_version' must be a string")

    try:
        upstream_semver = parse_semver(upstream_version, "upstream version")
        lock_semver = parse_semver(lock_version, "lock contract_version")
    except RuntimeError as exc:
        return fail(str(exc))

    if upstream_version != lock_version:
        return fail(
            f"lock contract_version '{lock_version}' does not match upstream version '{upstream_version}'"
        )

    supported_major = lock.get("supported_major")
    if not isinstance(supported_major, int) or supported_major < 0:
        return fail("lock 'supported_major' must be a non-negative integer")

    if upstream_semver[0] != supported_major:
        return fail(
            f"upstream major version {upstream_semver[0]} is incompatible with supported_major {supported_major}"
        )

    compatibility = upstream.get("compatibility", {})
    if not isinstance(compatibility, dict):
        return fail("upstream 'compatibility' must be an object")

    declared_major = compatibility.get("supported_major_for_current_impl")
    if declared_major != supported_major:
        return fail(
            "lock supported_major does not match upstream compatibility.supported_major_for_current_impl"
        )

    if not CONTRACT_BOUNDARY_PATH.exists():
        return fail("missing CONTRACT_BOUNDARY.md")

    for blocked in BOUNDARY_BLOCKED_PATHS:
        if blocked.exists():
            return fail(
                f"boundary violation: '{blocked.as_posix()}' must not exist in implementation repository"
            )

    print("Governance contract consumption validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
