#!/usr/bin/env bash
set -euo pipefail

SIGNING_EMAIL="${SIGNING_EMAIL:-$(git config --global user.email || true)}"
if [ -z "$SIGNING_EMAIL" ]; then
  echo "git user.email is not configured."
  echo "Run: git config --global user.email \"you@example.com\""
  exit 1
fi

if ! git config --global user.name >/dev/null 2>&1; then
  echo "git user.name is not configured."
  echo "Run: git config --global user.name \"Your Name\""
  exit 1
fi

mkdir -p "$HOME/.ssh" "$HOME/.config/git"
chmod 700 "$HOME/.ssh"

SIGNING_KEY_PRIVATE="$HOME/.ssh/id_ed25519_signing"
SIGNING_KEY_PUBLIC="$SIGNING_KEY_PRIVATE.pub"

if [ ! -f "$SIGNING_KEY_PRIVATE" ] || [ ! -f "$SIGNING_KEY_PUBLIC" ]; then
  echo "Generating SSH signing key: $SIGNING_KEY_PRIVATE"
  echo "You can set a passphrase when prompted."
  ssh-keygen -t ed25519 -f "$SIGNING_KEY_PRIVATE" -C "$SIGNING_EMAIL"
fi

git config --global gpg.format ssh
git config --global user.signingkey "$SIGNING_KEY_PUBLIC"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

ALLOWED_SIGNERS_FILE="$HOME/.config/git/allowed_signers"
printf "%s %s\n" "$SIGNING_EMAIL" "$(cat "$SIGNING_KEY_PUBLIC")" > "$ALLOWED_SIGNERS_FILE"
git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS_FILE"

echo
echo "SSH signing is configured."
echo "Add this public key in GitHub as a Signing Key:"
cat "$SIGNING_KEY_PUBLIC"
