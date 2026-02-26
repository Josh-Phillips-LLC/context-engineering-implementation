# Split-Source Role Sync Migration Plan

Date: 2026-02-26
Tracking Issue: Josh-Phillips-LLC/Context-Engineering#60

## Objective
Migrate role-repo generation and sync flows from mixed `Context-Engineering` assumptions to explicit split-source inputs.

## Split-Source Model

- Governance authority source: `context-engineering-governance`
- Implementation execution source: `context-engineering-implementation`
- Role repo sync pipeline consumes implementation outputs, with governance requirements enforced through contract inputs.

## Required Source Inputs

From implementation repository:
- `10-templates/repo-starters/role-repo-template/**`
- `10-templates/agent-instructions/**`
- `10-templates/job-description-spec/**`
- `10-templates/compliance-officer-pr-review-brief.md`
- `10-templates/github-app-auth-self-heal-protocol.md`
- `10-templates/systems-architect-session-brief.md`

From governance contract mirror in implementation:
- `contracts/upstream/governance-implementation-contract.json`
- `contracts/governance-contract-lock.json`
- `contracts/upstream/governance.md`

## Workflow Design Changes

1. `sync-role-repos.yml` now validates split-source boundary and contract compatibility before publishability preflight or sync.
2. Role job-description builder consumes governance context from `contracts/upstream/governance.md`.
3. Role sync PR metadata references `Context-Engineering-Implementation` as source.
4. Trigger paths include contract/boundary artifacts to ensure changes run through sync validation.

## Migration Steps

1. Keep role-repo owner and role app auth unchanged.
2. Update implementation source artifacts and contract mirror files.
3. Run preflight-only sync validation for each role.
4. Execute workflow-dispatch sync runs role-by-role or all roles.
5. Verify generated role repo PRs pass governance/compliance checks.

## Exit Criteria

- Preflight succeeds for all canonical roles.
- No sync tooling depends on root `governance.md` in implementation repo.
- Contract and boundary validators pass in CI.
