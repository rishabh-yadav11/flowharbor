#!/usr/bin/env bash
#
# 5-restore-health-check.sh
#
# Reverts the intentional breakage from 4-break-health-check.sh and
# pushes a clean, healthy build.

set -euo pipefail

BRANCH="main"
SERVER_FILE="src/server.js"

echo "==> Checking repo state..."
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
  echo "ERROR: not inside a git repo. cd into your flowharbor clone first."
  exit 1
}

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
  echo "ERROR: you're on branch '$CURRENT_BRANCH', expected '$BRANCH'."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: you have uncommitted changes. Commit or stash them first."
  git status --short
  exit 1
fi

echo "==> Pulling latest..."
git pull origin "$BRANCH"

if [[ ! -f "$SERVER_FILE" ]]; then
  echo "ERROR: $SERVER_FILE not found. Run this from the repo root."
  exit 1
fi

if ! grep -q "BROKEN FOR DEMO" "$SERVER_FILE"; then
  echo "Nothing to restore — no 'BROKEN FOR DEMO' marker found in $SERVER_FILE."
  exit 0
fi

echo "==> Restoring /health in $SERVER_FILE..."
sed -i.bak "s|res.status(500).json({ status: 'BROKEN FOR DEMO' });|res.status(200).json({ status: 'ok' });|" "$SERVER_FILE"
rm -f "${SERVER_FILE}.bak"

echo "==> Committing and pushing fix..."
git add "$SERVER_FILE"
git commit -m "demo: restore healthy /health endpoint"
git push origin "$BRANCH"

echo ""
echo "==> Done. Pushed a clean build to $BRANCH — pipeline should go fully green again."
echo "    https://jenkins.flowharbor.in/job/flowharbor/"
