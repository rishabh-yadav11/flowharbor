#!/usr/bin/env bash
#
# 1-trigger-happy-path.sh
#
# Makes a small, harmless change (bumps a demo marker comment) and pushes
# to main, triggering a full green pipeline run: Checkout -> Tests ->
# Build -> Deploy Test -> Health Check -> Approve Staging -> Health Check
# -> Approve Production -> Health Check.
#
# Safe to run repeatedly. Run from inside your local flowharbor repo clone.

set -euo pipefail

BRANCH="main"
MARKER_FILE="src/public/index.html"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "==> Checking repo state..."
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
  echo "ERROR: not inside a git repo. cd into your flowharbor clone first."
  exit 1
}

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
  echo "ERROR: you're on branch '$CURRENT_BRANCH', expected '$BRANCH'."
  echo "Run: git checkout $BRANCH"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: you have uncommitted changes. Commit or stash them first."
  git status --short
  exit 1
fi

echo "==> Pulling latest..."
git pull origin "$BRANCH"

echo "==> Bumping demo marker in $MARKER_FILE..."
if [[ ! -f "$MARKER_FILE" ]]; then
  echo "ERROR: $MARKER_FILE not found. Run this from the repo root."
  exit 1
fi

# Insert or update a harmless HTML comment marker near the top of the file
if grep -q "<!-- demo-marker:" "$MARKER_FILE"; then
  sed -i.bak "s|<!-- demo-marker:.*-->|<!-- demo-marker: $TIMESTAMP -->|" "$MARKER_FILE"
  rm -f "${MARKER_FILE}.bak"
else
  sed -i.bak "1s|^|<!-- demo-marker: $TIMESTAMP -->\n|" "$MARKER_FILE"
  rm -f "${MARKER_FILE}.bak"
fi

echo "==> Committing and pushing..."
git add "$MARKER_FILE"
git commit -m "demo: trigger pipeline run ($TIMESTAMP)"
git push origin "$BRANCH"

echo ""
echo "==> Done. Pushed to $BRANCH — go watch Jenkins pick this up."
echo "    https://jenkins.flowharbor.in/job/flowharbor/"
