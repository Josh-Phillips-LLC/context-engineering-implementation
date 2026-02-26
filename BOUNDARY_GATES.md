# Implementation Boundary Gates

These CI gates prevent governance policy artifacts from drifting into implementation scope.

## Enforced by CI

Workflow: `.github/workflows/validate-boundary-implementation.yml`

Checks:
- Governance-authoritative documents and ADR artifacts are blocked in this repository.
- Governance contract lock/upstream compatibility is validated.

## Failure Remediation

If the boundary gate fails:

1. Remove governance-authoritative artifacts from implementation.
2. Keep implementation changes scoped to scripts/workflows/generators.
3. Sync contract lock/upstream files to the supported governance contract version.
4. Re-run CI and include remediation evidence in PR notes.
