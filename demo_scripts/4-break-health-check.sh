#!/usr/bin/env bash
#
# 4-break-health-check.sh
#
# Intentionally makes /health return a 500 so tests still pass and the
# image still builds, but the pipeline's Health Check stage fails and
# blocks promotion. This is the strongest single demo point — it shows
# the pipeline catching a bad deploy that unit tests alone wouldn't.
#
# Pair with 5-restore-health-check.sh to undo this afterwards.

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

if [[ ! -f "$SERVER_FILE" ]]; then
  echo "ERROR: $SERVER_FILE not found. Run this from the repo root."
  exit 1
fi

echo "==> Pulling latest..."
git pull origin "$BRANCH"

echo "==> Breaking /health in $SERVER_FILE..."
sed -i.bak "s|res.status(200).json({ status: 'ok' });|res.status(500).json({ status: 'BROKEN FOR DEMO' });|" "$SERVER_FILE"
rm -f "${SERVER_FILE}.bak"

if ! grep -q "BROKEN FOR DEMO" "$SERVER_FILE"; then
  echo "ERROR: couldn't find the /health handler to break. Check $SERVER_FILE manually."
  exit 1
fi

# server.test.js asserts /health returns 200 + {status:'ok'} — this will now
# also fail, which is fine: it demonstrates unit tests catching it locally
# even before the Health Check stage would. If you want to demo ONLY the
# Health Check gate (not the unit test), see the note in 5-restore-health-check.sh.

echo "==> Committing and pushing broken health endpoint..."
git add "$SERVER_FILE"
git commit -m "demo: intentionally break /health to show health-check gate"
git push origin "$BRANCH"

echo ""
echo "==> Done. Pushed to $BRANCH."
echo "    Note: this will actually fail 'Run Unit Tests' first (health test asserts 200)."
echo "    If you want to see the Health Check STAGE specifically fail instead,"
echo "    also update the health test assertion in src/server.test.js to expect 500,"
echo "    or temporarily skip that one test — see README notes."
echo "    https://jenkins.flowharbor.in/job/flowharbor/"
