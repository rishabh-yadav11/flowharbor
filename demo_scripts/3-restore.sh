#!/usr/bin/env bash
#
# 3-restore.sh
#
# Reverts the intentional breakage from 2-break-a-test.sh and pushes a
# clean, passing commit so the pipeline goes green again.

set -euo pipefail

BRANCH="main"
TEST_FILE="src/logic.test.js"

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

if [[ ! -f "$TEST_FILE" ]]; then
  echo "ERROR: $TEST_FILE not found. Run this from the repo root."
  exit 1
fi

if ! grep -q "BROKEN FOR DEMO" "$TEST_FILE"; then
  echo "Nothing to restore — no 'BROKEN FOR DEMO' marker found in $TEST_FILE."
  exit 0
fi

echo "==> Restoring the assertion in $TEST_FILE..."
sed -i.bak "s|expect(add(2, 3)).toBe(999); // BROKEN FOR DEMO|expect(add(2, 3)).toBe(5);|" "$TEST_FILE"
rm -f "${TEST_FILE}.bak"

echo "==> Committing and pushing fix..."
git add "$TEST_FILE"
git commit -m "demo: restore passing test"
git push origin "$BRANCH"

echo ""
echo "==> Done. Pushed a clean build to $BRANCH — pipeline should go fully green."
echo "    https://jenkins.flowharbor.in/job/flowharbor/"
