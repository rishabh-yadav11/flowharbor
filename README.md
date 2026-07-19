# FlowHarbor App Scaffold

A minimal Express app with unit + integration tests, replacing the old static
HTML site. This is meant to be copied into the root of your `flowharbor` repo.

## What's included

- `package.json` — Express + Jest + Supertest
- `src/logic.js` — small pure functions (`greet`, `add`, `isPalindrome`) — easy,
  meaningful things to unit test
- `src/server.js` — Express app exposing `/`, `/health`, `/add`, `/palindrome/:word`
- `src/__tests__/logic.test.js` — unit tests for the pure logic
- `src/__tests__/server.test.js` — integration tests for the HTTP routes (via supertest)
- `Dockerfile` — multi-stage build: install deps + **run tests** in the build
  stage (build fails if tests fail), then a slim production runtime stage
- `.dockerignore`
- `Jenkinsfile` — updated with new `Install Dependencies` and `Run Unit Tests`
  stages before `Build Image`. Port mappings updated from `:80` to `:3000`
  (the port Express listens on) since this replaces the old Nginx-only setup.

## Before you push this

1. **Delete the old static site files** (old `index.html` etc.) from the repo
   root if they conflict with these new files — you don't want stale static
   content sitting alongside the app.
2. **Remove the old plain Dockerfile** (the `nginx:alpine` one) — this new
   multi-stage Dockerfile replaces it entirely.
3. Copy everything in this scaffold into your repo root, preserving folder
   structure (`src/`, `src/__tests__/`).

## Verified locally

Ran in this sandbox before handing off to you:
```
npm install
npm test
```
Result: **16/16 tests passing**, ~88-90% coverage on `logic.js`/`server.js`.
(One real bug was caught and fixed in the process: `add()` wasn't rejecting
`NaN` inputs like `Number('x')`.)

## About the `junit allowEmptyResults: true, testResults: 'junit.xml'` line

This step in the Jenkinsfile publishes test results in Jenkins's UI (nice
pass/fail graphs over time). It needs `jest-junit` to actually produce that
file. This is optional — if you don't want to set it up right now, you can
either:
- Leave it as-is: with `allowEmptyResults: true` it just silently does
  nothing if `junit.xml` isn't found (won't break your build), or
- Remove the whole `post { always { junit ... } }` block from the
  `Run Unit Tests` stage if you'd rather skip it for now.

To make it actually work later:
```bash
npm install --save-dev jest-junit
```
And add to `package.json`:
```json
"jest": {
  "reporters": ["default", "jest-junit"]
}
```

## Port change note

Old Nginx containers served on port 80 inside the container, mapped to
8081/8082/8083 on the host. This Express app listens on port **3000** inside
the container — the Jenkinsfile's `docker run` commands have been updated
accordingly (e.g. `-p 8081:3000` instead of `-p 8081:80`). Host-side ports
(8081/8082/8083) and your Nginx reverse proxy upstream config on the public
server **do not need to change** — only the container-side port changed.

## What to check on your EC2 host before running the pipeline

Your Jenkins container needs Node.js and npm available to run
`Install Dependencies` / `Run Unit Tests` **directly on the Jenkins agent**
(not inside Docker) — these two new stages run as plain `sh` steps, same as
your existing `docker build` step.

Check:
```bash
docker exec 8e1a2934a9e7 node --version
docker exec 8e1a2934a9e7 npm --version
```

If those come back with "not found," you'll need to either:
- Install Node/npm inside the Jenkins container, or
- Use a Jenkins Docker agent/image that already includes Node (bigger change), or
- Wrap those two stages in `docker run node:20-alpine sh -c "npm ci && npm test"`
  instead of running them directly on the host

Let me know what those two commands return and I'll help you sort out
whichever path applies.
