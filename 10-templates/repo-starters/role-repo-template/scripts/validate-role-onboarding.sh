#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  validate-role-onboarding.sh \
    --role-slug <role-slug>

Required:
  --role-slug   Role slug (for example: implementation-specialist)
USAGE
}

ROLE_SLUG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --role-slug)
      ROLE_SLUG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$ROLE_SLUG" ]; then
  echo "Missing required arg: --role-slug" >&2
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

missing=()

check_file() {
  local path="$1"
  local label="$2"
  if [ ! -f "${REPO_ROOT}/${path}" ]; then
    missing+=("${label} (${path})")
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  local label="$3"
  if ! grep -qE "$pattern" "${REPO_ROOT}/${path}"; then
    missing+=("${label} (${path})")
  fi
}

echo "Role onboarding preflight for ${ROLE_SLUG}"

check_file "00-os/role-charters/${ROLE_SLUG}.md" "Role charter"
check_file "10-templates/agent-instructions/roles/${ROLE_SLUG}.md" "Role instruction source"
check_file "10-templates/job-description-spec/roles/${ROLE_SLUG}.json" "Role job-description spec"
check_file ".devcontainer-workstation/codex/role-profiles/${ROLE_SLUG}.env" "Role profile env"

check_grep "ROLE_PROFILE=.*${ROLE_SLUG}" ".devcontainer-workstation/docker-compose.yml" "Compose role profile wiring"
check_grep "ROLE_PROFILE=.*${ROLE_SLUG}" ".devcontainer-workstation/docker-compose.ghcr.yml" "Compose GHCR role profile wiring"
check_grep "role_slug: ${ROLE_SLUG}" ".github/workflows/sync-role-repos.yml" "Sync workflow matrix entry"
check_grep "role_profile: ${ROLE_SLUG}" ".github/workflows/publish-role-workstation-images.yml" "Publish workflow matrix entry"

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing required touchpoints:"
  for item in "${missing[@]}"; do
    echo "- ${item}"
  done
  exit 1
fi

echo "All required touchpoints are present."
