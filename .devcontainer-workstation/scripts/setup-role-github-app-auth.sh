#!/usr/bin/env bash
set -euo pipefail

ROLE_GITHUB_AUTH_MODE="${ROLE_GITHUB_AUTH_MODE:-}"
ROLE_GITHUB_APP_ID="${ROLE_GITHUB_APP_ID:-}"
ROLE_GITHUB_APP_INSTALLATION_ID="${ROLE_GITHUB_APP_INSTALLATION_ID:-}"
ROLE_GITHUB_APP_PRIVATE_KEY_PATH="${ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-}"

if [ "$ROLE_GITHUB_AUTH_MODE" != "app" ]; then
  echo "ROLE_GITHUB_AUTH_MODE is not set to app; skipping role GitHub App auth."
  exit 0
fi

missing_vars=()
if [ -z "$ROLE_GITHUB_APP_ID" ]; then
  missing_vars+=("ROLE_GITHUB_APP_ID")
fi
if [ -z "$ROLE_GITHUB_APP_INSTALLATION_ID" ]; then
  missing_vars+=("ROLE_GITHUB_APP_INSTALLATION_ID")
fi
if [ -z "$ROLE_GITHUB_APP_PRIVATE_KEY_PATH" ]; then
  missing_vars+=("ROLE_GITHUB_APP_PRIVATE_KEY_PATH")
fi

if [ "${#missing_vars[@]}" -gt 0 ]; then
  printf 'Missing required variables for role GitHub App auth: %s\n' "${missing_vars[*]}" >&2
  exit 1
fi

if [ ! -r "$ROLE_GITHUB_APP_PRIVATE_KEY_PATH" ]; then
  echo "GitHub App private key path is not readable: ${ROLE_GITHUB_APP_PRIVATE_KEY_PATH}" >&2
  exit 1
fi

base64url() {
  openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

now="$(date +%s)"
iat="$((now - 30))"
exp="$((now + 540))"
header='{"alg":"RS256","typ":"JWT"}'
payload="{\"iat\":${iat},\"exp\":${exp},\"iss\":\"${ROLE_GITHUB_APP_ID}\"}"

header_b64="$(printf '%s' "$header" | base64url)"
payload_b64="$(printf '%s' "$payload" | base64url)"
unsigned_token="${header_b64}.${payload_b64}"
signature="$(printf '%s' "$unsigned_token" | openssl dgst -sha256 -sign "$ROLE_GITHUB_APP_PRIVATE_KEY_PATH" | base64url)"
app_jwt="${unsigned_token}.${signature}"

installation_token_response="$(curl -fsS \
  -X POST \
  -H "Authorization: Bearer ${app_jwt}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/${ROLE_GITHUB_APP_INSTALLATION_ID}/access_tokens" \
)"
installation_token="$(printf '%s' "$installation_token_response" | jq -r '.token // empty')"

if [ -z "$installation_token" ]; then
  echo "Failed to mint GitHub App installation token." >&2
  printf '%s\n' "$installation_token_response" >&2
  exit 1
fi

printf '%s' "$installation_token" | env -u GH_TOKEN -u GITHUB_TOKEN gh auth login --hostname github.com --git-protocol https --with-token >/dev/null

env -u GH_TOKEN -u GITHUB_TOKEN gh auth setup-git >/dev/null

principal="$(env -u GH_TOKEN -u GITHUB_TOKEN gh api graphql -f query='query { viewer { login } }' --jq '.data.viewer.login' 2>/dev/null || true)"
if [ -z "$principal" ]; then
  principal="unknown"
fi

echo "GitHub App installation auth ready (principal: ${principal})."
