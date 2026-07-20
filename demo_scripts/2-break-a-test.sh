#!/usr/bin/env bash
#
# 2-break-a-test.sh
#
# Intentionally breaks one assertion in logic.test.js and pushes, so you
# can demo the pipeline correctly FAILING at the "Run Unit Tests" stage
# and never reaching Build/Deploy. Great for showing the pipeline isn't
# just decorative.
#
# Pair with 3-restore.sh to undo this afterwards.

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

if [[ ! -f "$TEST_FILE" ]]; then
  echo "ERROR: $TEST_FILE not found. Run this from the repo root."
  exit 1
fi

echo "==> Pulling latest..."
git pull origin "$BRANCH"

echo "==> Intentionally breaking an assertion in $TEST_FILE..."
# Flips the expected result of the 'adds two positive numbers' test so it fails.
sed -i.bak "s|expect(add(2, 3)).toBe(5);|expect(add(2, 3)).toBe(999); // BROKEN FOR DEMO|" "$TEST_FILE"
rm -f "${TEST_FILE}.bak"

if ! grep -q "BROKEN FOR DEMO" "$TEST_FILE"; then
  echo "ERROR: couldn't find the expected line to break. Did the test file change?"
  echo "Open $TEST_FILE and check the 'adds two positive numbers' test manually."
  exit 1
fi

echo "==> Committing and pushing broken test..."
git add "$TEST_FILE"
git commit -m "demo: intentionally break a test to show pipeline catching it"
git push origin "$BRANCH"

echo ""
echo "==> Done. Pushed a failing test to $BRANCH."
echo "    Watch Jenkins fail at 'Run Unit Tests' and skip everything after."
echo "    https://jenkins.flowharbor.in/job/flowharbor/"
echo ""
echo "    Run 3-restore.sh afterwards to fix it and push a clean build."
