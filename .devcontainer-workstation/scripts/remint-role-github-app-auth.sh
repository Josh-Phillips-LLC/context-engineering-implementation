#!/usr/bin/env bash
set -euo pipefail

ROLE_GITHUB_APP_AUTH_SCRIPT="${ROLE_GITHUB_APP_AUTH_SCRIPT:-/usr/local/bin/setup-role-github-app-auth.sh}"
ROLE_GITHUB_APP_AUTH_METADATA_FILE="${ROLE_GITHUB_APP_AUTH_METADATA_FILE:-${RUNTIME_GITHUB_APP_AUTH_METADATA_FILE:-/workspace/instructions/role-github-app-auth.env}}"
DEFAULT_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="${DEFAULT_ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-/run/secrets/role_github_app_private_key}"

metadata_loaded="false"
if [ -r "$ROLE_GITHUB_APP_AUTH_METADATA_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ROLE_GITHUB_APP_AUTH_METADATA_FILE"
  metadata_loaded="true"
fi

has_tty="false"
if [ -t 0 ] && [ -t 1 ]; then
  has_tty="true"
fi

ROLE_GITHUB_AUTH_MODE_RESOLVED="${ROLE_GITHUB_AUTH_MODE:-${RUNTIME_ROLE_GITHUB_AUTH_MODE:-}}"
ROLE_GITHUB_APP_ID_RESOLVED="${ROLE_GITHUB_APP_ID:-${RUNTIME_ROLE_GITHUB_APP_ID:-}}"
ROLE_GITHUB_APP_INSTALLATION_ID_RESOLVED="${ROLE_GITHUB_APP_INSTALLATION_ID:-${RUNTIME_ROLE_GITHUB_APP_INSTALLATION_ID:-}}"
ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RESOLVED="${ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-${RUNTIME_ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-$DEFAULT_ROLE_GITHUB_APP_PRIVATE_KEY_PATH}}"

if [ -z "$ROLE_GITHUB_AUTH_MODE_RESOLVED" ]; then
  echo "Cannot re-mint role GitHub App auth; missing required value: ROLE_GITHUB_AUTH_MODE." >&2
  if [ "$metadata_loaded" != "true" ]; then
    echo "Runtime metadata file is unavailable at ${ROLE_GITHUB_APP_AUTH_METADATA_FILE}." >&2
  fi
  if [ "$has_tty" != "true" ]; then
    echo "No interactive TTY detected; cannot prompt for missing values." >&2
  fi
  exit 1
fi

if [ "$ROLE_GITHUB_AUTH_MODE_RESOLVED" != "app" ]; then
  echo "Cannot re-mint role GitHub App auth: ROLE_GITHUB_AUTH_MODE is '${ROLE_GITHUB_AUTH_MODE_RESOLVED:-unset}'." >&2
  echo "Use ROLE_GITHUB_AUTH_MODE=app for role-attributed auth, or run gh auth login for user-mode auth." >&2
  exit 1
fi

missing_vars=()
if [ -z "$ROLE_GITHUB_APP_ID_RESOLVED" ]; then
  missing_vars+=("ROLE_GITHUB_APP_ID")
fi
if [ -z "$ROLE_GITHUB_APP_INSTALLATION_ID_RESOLVED" ]; then
  missing_vars+=("ROLE_GITHUB_APP_INSTALLATION_ID")
fi
if [ -z "$ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RESOLVED" ]; then
  missing_vars+=("ROLE_GITHUB_APP_PRIVATE_KEY_PATH")
fi

if [ "${#missing_vars[@]}" -gt 0 ]; then
  printf 'Cannot re-mint role GitHub App auth; missing required values: %s\n' "${missing_vars[*]}" >&2
  if [ "$metadata_loaded" != "true" ]; then
    echo "Runtime metadata file is unavailable at ${ROLE_GITHUB_APP_AUTH_METADATA_FILE}." >&2
  fi
  if [ "$has_tty" != "true" ]; then
    echo "No interactive TTY detected; cannot prompt for missing values." >&2
  fi
  echo "Expected private key secret path: /run/secrets/role_github_app_private_key" >&2
  exit 1
fi

if [ ! -r "$ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RESOLVED" ]; then
  echo "Cannot re-mint role GitHub App auth; private key path is not readable: ${ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RESOLVED}" >&2
  echo "Expected private key secret path: /run/secrets/role_github_app_private_key" >&2
  if [ "$has_tty" != "true" ]; then
    echo "No interactive TTY detected; cannot prompt for an alternate key path." >&2
  fi
  exit 1
fi

if [ ! -x "$ROLE_GITHUB_APP_AUTH_SCRIPT" ]; then
  echo "Cannot re-mint role GitHub App auth; helper script is missing or not executable: ${ROLE_GITHUB_APP_AUTH_SCRIPT}" >&2
  exit 1
fi

ROLE_GITHUB_AUTH_MODE="$ROLE_GITHUB_AUTH_MODE_RESOLVED" \
ROLE_GITHUB_APP_ID="$ROLE_GITHUB_APP_ID_RESOLVED" \
ROLE_GITHUB_APP_INSTALLATION_ID="$ROLE_GITHUB_APP_INSTALLATION_ID_RESOLVED" \
ROLE_GITHUB_APP_PRIVATE_KEY_PATH="$ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RESOLVED" \
"$ROLE_GITHUB_APP_AUTH_SCRIPT"

if command -v gh >/dev/null 2>&1; then
  if env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com >/dev/null 2>&1; then
    echo "GitHub CLI auth status is healthy after re-mint."
  else
    echo "Warning: re-mint completed, but gh auth status still reports a failure." >&2
  fi
fi
