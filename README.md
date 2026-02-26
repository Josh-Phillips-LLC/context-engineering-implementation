# Context Engineering Implementation

Execution and tooling source for Context Engineering.

## Purpose

This repository owns implementation mechanics for agent/repo operations, including scripts, generators, and operational workflows.

Normative dependency direction:

- governance -> implementation -> role repositories

## Scope

Included in bootstrap:

- execution scripts under `00-os/scripts/`
- operational workflows under `.github/workflows/`
- generator sources under `10-templates/repo-starters/`
- tooling configuration inputs (`00-os/role-registry.yml`, `00-os/governed-repos.yml`)

## Authority Boundary

This repository is not the governance authority source. Governance policy decisions, approval rules, and protected-path definitions are authoritative in:

- `Josh-Phillips-LLC/context-engineering-governance`

See `CONTRACT_BOUNDARY.md` and `MIGRATION_PROVENANCE.md`.
