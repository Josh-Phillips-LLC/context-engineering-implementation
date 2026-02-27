# Role Repo Template (Proposed)

This starter defines a reusable template for generating public, role-specific repositories from repository-governed role definitions.

It is intended for the role-repo migration program and is not yet ratified governance policy.

## Purpose

- Provide a single scaffold source for role repositories.
- Keep role-repo instruction files deterministic and regenerable.
- Avoid hand-edit drift across role repos.

## Output Shape

The renderer writes this minimum file set to a target role repo:

- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.vscode/settings.json`
- `README.md`

Instruction model:

- `AGENTS.md` is the canonical compiled role instruction set.
- `.github/copilot-instructions.md` is a lightweight adapter that points to `AGENTS.md`.

## Source Inputs

Role `AGENTS.md` job descriptions are assembled from structured spec inputs:

- `10-templates/job-description-spec/global.json`
- `10-templates/job-description-spec/roles/<role-slug>.json`

Canonical governance artifacts are also required as source-of-truth anchors:

- `governance.md`
- `00-os/role-charters/<role-slug>.md`
- `10-templates/agent-instructions/base.md`
- `10-templates/agent-instructions/roles/<role-slug>.md`

For `compliance-officer`, required protocol includes are embedded from:

- `10-templates/compliance-officer-pr-review-brief.md`

## Builder

Script:

- `scripts/build-agent-job-description.py`

This script merges global + role spec, validates required contract sections, and emits deterministic `AGENTS.md` job description content.

## Renderer

Script:

- `scripts/render-role-repo-template.sh`

This script calls the builder and renders final repository files from templates.

Required args:

- `--role-slug`
- `--repo-name`
- `--output-dir`

Optional args:

- `--role-name`
- `--source-ref` (defaults to current `git rev-parse --short HEAD`)
- `--force` (allow writing into non-empty output directories)

## Example

```bash
10-templates/repo-starters/role-repo-template/scripts/render-role-repo-template.sh \
  --role-slug implementation-specialist \
  --repo-name context-engineering-role-implementation-specialist \
  --output-dir /tmp/context-engineering-role-implementation-specialist
```

## Public Repo Creation Workflow

Script:

- `scripts/create-public-role-repo.sh`

This script composes the renderer and creates a **public** GitHub repository with an initial commit and push.

Required args:

- `--role-slug`
- `--owner` (organization or user)

Optional args:

- `--repo-name` (defaults to `context-engineering-role-<role-slug>`)
- `--role-name`
- `--description`
- `--output-dir`
- `--source-ref`
- `--force`
- `--dry-run`

Example:

```bash
10-templates/repo-starters/role-repo-template/scripts/create-public-role-repo.sh \
  --role-slug implementation-specialist \
  --owner Josh-Phillips-LLC
```

Dry-run example:

```bash
10-templates/repo-starters/role-repo-template/scripts/create-public-role-repo.sh \
  --role-slug compliance-officer \
  --owner Josh-Phillips-LLC \
  --dry-run
```

## Role Repo Sync Workflow

Script:

- `scripts/sync-role-repo.sh`

This script syncs managed role-repo artifacts from Context-Engineering-Implementation source into an existing public role repository and opens or updates a sync PR.

Required args:

- `--role-slug`
- `--owner`

Optional args:

- `--repo-name` (defaults to `context-engineering-role-<role-slug>`)
- `--role-name`
- `--base-branch` (defaults to `main`)
- `--source-ref`
- `--sync-branch` (defaults to `sync/role-repo/<role-slug>`)
- `--pr-title`
- `--work-dir`
- `--auto-merge` (best-effort request GitHub auto-merge on sync PR)
- `--no-pr`
- `--dry-run`

Example:

```bash
10-templates/repo-starters/role-repo-template/scripts/sync-role-repo.sh \
  --role-slug implementation-specialist \
  --owner Josh-Phillips-LLC \
  --auto-merge
```

Dry-run example:

```bash
10-templates/repo-starters/role-repo-template/scripts/sync-role-repo.sh \
  --role-slug compliance-officer \
  --owner Josh-Phillips-LLC \
  --dry-run
```

## Role Onboarding Preflight Validator

Script:

- `scripts/validate-role-onboarding.sh`

This script checks required role onboarding touchpoints for a given role slug.

Required args:

- `--role-slug`

Example:

```bash
10-templates/repo-starters/role-repo-template/scripts/validate-role-onboarding.sh \
  --role-slug implementation-specialist
```

## Publishability Preflight Gate

Role-repo create and sync automation run a publishability preflight gate before any publish action.
The gate scans generated role-repo artifacts for disallowed patterns and fails fast when detected.

Patterns checked:

- Private key headers (RSA/OPENSSH/EC/PGP)
- GitHub tokens (`ghp_`, `github_pat_`, `ghs_`, `ghu_`)
- Slack bot tokens (`xoxb-`)
- OpenAI API keys (`sk-`, `sk-proj-`, `sk_` with length guard)
- AWS access key prefixes (`AKIA`, `ASIA`)
- Private IP ranges (10/8, 172.16/12, 192.168/16)
- Internal hostnames (`.internal`, `.corp`, `.lan`, `.local`)

If the preflight fails:

1. Remove or redact the flagged content from the role instruction sources.
2. Regenerate role-repo artifacts.
3. Rerun the create/sync automation.

## GitHub Actions Sync Automation

Workflow:

- `.github/workflows/sync-role-repos.yml`

Behavior:

- Runs on `main` pushes that touch role instruction source inputs.
- Supports manual runs via `workflow_dispatch`.
- Syncs matrix roles:
  - `implementation-specialist`
  - `compliance-officer`
  - `systems-architect`
- Requests auto-merge on generated sync PRs by default (unless `no_pr`/`dry_run` is used or manual `auto_merge` input is disabled).
- Auto-merge request is best-effort and non-fatal; sync still succeeds if repo policy blocks auto-merge.

Required secret:

- `IMPLEMENTATION_SPECIALIST_APP_ID`
- `IMPLEMENTATION_SPECIALIST_APP_PRIVATE_KEY`
- `COMPLIANCE_OFFICER_APP_ID`
- `COMPLIANCE_OFFICER_APP_PRIVATE_KEY`
- `SYSTEMS_ARCHITECT_APP_ID`
- `SYSTEMS_ARCHITECT_APP_PRIVATE_KEY`

These secrets must map to GitHub Apps installed on the target role repositories. The sync workflow mints a short-lived installation token per role and uses it as `GH_TOKEN` for `gh` and git operations.

Optional variable:

- `ROLE_REPO_OWNER`

If `ROLE_REPO_OWNER` is unset, workflow defaults to `github.repository_owner`.

Verification (audit):

- Check workflow logs for the `Configure git auth for gh operations` step and confirm `gh auth status` reports the expected role App identity.
- Review the sync PR actor in the role repo; it should show the role App identity rather than a shared human account.

Failure modes:

- Missing role App secrets will stop the workflow with a missing token error.
- If the App is not installed on a target role repo, token minting will fail.

## GitHub Actions GHCR Publish Path

Workflow:

- `.github/workflows/publish-role-workstation-images.yml`

Behavior:

- Builds one image per role profile.
- Pulls role-repo `AGENTS.md` from:
  - `context-engineering-role-implementation-specialist`
  - `context-engineering-role-compliance-officer`
  - `context-engineering-role-systems-architect`
- Bakes role-repo `AGENTS.md` into `/etc/codex/runtime-role-instructions/<role>.md`.
- Falls back to Context-Engineering-Implementation instruction sources only when role-repo artifacts are unavailable in build context.
- Fails publish if the role-repo `AGENTS.md` `Source ref` does not match the current `Context-Engineering-Implementation` commit. Run the role-repo sync workflow and rerun publish after the sync PR merges.

Naming and versioning conventions:

- Role repo names: `context-engineering-role-<role-slug>`
- Image names: `ghcr.io/<owner>/context-engineering-workstation-<role-slug>`
- Published tags:
  - `latest`
  - `<role-slug>-latest`
  - `<role-slug>-<short-sha>`
