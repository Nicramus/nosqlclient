# Local development

Tested on Ubuntu 24.04. Nothing is installed system-wide; no sudo needed.

## One-time setup
```bash
# 1. Meteor 1.10.2 (bundles Node 12 and its own MongoDB for the app's internal data)
curl -s "https://install.meteor.com/?release=1.10.2" | sh     # the final sudo step may fail — that's fine
echo 'export PATH="$HOME/.meteor:$PATH"' >> ~/.bashrc && source ~/.bashrc

# 2. Dependencies — always through meteor (Node 12), never system npm
cd nosqlclient-fork
meteor npm ci
```
Optional, for testing against several MongoDB versions: `mongosh` on PATH and the test servers from `scripts/mongo-matrix.sh` (binaries for 6.0/7.0/8.0 go to `~/.local/share/mongo-matrix/`, see `.claude/skills/mongo-matrix/SKILL.md` for download steps; 4.2 is Meteor's bundled mongod).

## Run the app
```bash
meteor run --settings settings.json
```
Open http://localhost:3000. Code changes reload automatically (client refresh / server restart).
- The app's own data (saved connections, settings, query history) lives in `.meteor/local/db`, served by Meteor's mongod on port **3001**. Wipe it with `meteor reset` (app stopped).
- Port busy: `meteor run --settings settings.json --port 3100`.
- Stop: Ctrl+C.

## Test MongoDB servers (optional)
```bash
scripts/mongo-matrix.sh start      # 4.2 :27042, 6.0 :27060, 7.0 :27070, 8.0 :27080 (admin/admin), 8.0 replica set :27081
scripts/mongo-matrix.sh status
scripts/mongo-matrix.sh stop
```
They run as plain background processes (no containers), bind to 127.0.0.1 only and never touch port 27017.
In the app: Connect → e.g. `mongodb://admin:admin@localhost:27080/nosqlclient_test?authSource=admin`.

Test data:
```bash
mongosh "mongodb://admin:admin@localhost:27080/admin" --quiet scripts/compat-seed.js    # nosqlclient_test: BSON types, items, view, GridFS…
mongosh "mongodb://admin:admin@localhost:27080/admin" --quiet scripts/perf-seed.js      # perf10k / perf50k / perf100k
mongosh "mongodb://admin:admin@localhost:27080/admin" --quiet --eval "PERF_TARGETS=[['perf1m',1000000]]" scripts/perf-seed.js
```

## Checks
```bash
meteor npm run lint
meteor npm test                    # server + client mocha tests (client: headless Chromium via puppeteer); add `-- --port 3300` if 3000 is busy
meteor npm run test:client         # client tests only (514); test:server has no tests yet, it only checks the server starts
node --experimental-websocket scripts/compat-matrix.mjs            # app running + servers started + seeded; see docs/compat-matrix.md
node --experimental-websocket scripts/perf-find.mjs m80 3 perf1m   # browse-collection timings; see docs/perf-browse.md
node --experimental-websocket scripts/check-ordering.mjs m80        # read-after-write ordering (guards this.unblock() in methods)
```
CI (`.github/workflows/ci.yml`) runs lint and `meteor npm test` on every PR and push to master.
`compat-matrix.mjs` saves connections named `compat-*` in the app; `perf-find.mjs` reuses `compat-m80-url`, so run the compat test once first.

## CI checks
| Workflow | Runs on | What |
|---|---|---|
| `codeql.yml` | PR, master, weekly | CodeQL `security-and-quality` for JS (vendored `client/plugins` ignored). Results: Security → Code scanning. |
| `dependency-review.yml` | PR | Fails when the PR adds a dependency with a high/critical advisory. Existing advisories don't block. |
| `docker.yml` | PRs touching the image, releases | Builds the image, Trivy scan (HIGH/CRITICAL, report-only) → Code scanning, category `trivy-image`. |
| `lint-config.yml` | PR, master | actionlint (workflows), hadolint (`Dockerfile`, config `.hadolint.yaml`), shellcheck (`.docker/entrypoint.sh`, `scripts/*.sh`). |

Locally, same tools via Docker:
```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.7
docker run --rm -v "$PWD:/repo" -w /repo hadolint/hadolint:v2.12.0 hadolint --config .hadolint.yaml Dockerfile
docker run --rm -v "$PWD:/repo" -w /repo koalaman/shellcheck:v0.10.0 .docker/entrypoint.sh scripts/*.sh
```
Third-party actions are pinned to commit SHAs; Dependabot (`.github/dependabot.yml`, GitHub Actions only) bumps them weekly.
Trivy runs from its Docker image pinned by digest, not via `aquasecurity/trivy-action` (its tags were hijacked in March 2026, CVE-2026-33634).

## Docker image
```bash
docker build -t nosqlclient:dev .                                   # multi-stage: Meteor 1.10.2 builder → node:12-bullseye-slim runtime
docker build -t nosqlclient:dev --build-arg INSTALL_MONGO_TOOLS=false .   # without MongoDB 4.2 client tools
docker run --rm -p 3000:3000 -e MONGO_URL=mongodb://host.docker.internal:27042/meteor nosqlclient:dev
docker compose up -d --build                                        # app + mongo service (volume mongo-data)
docker compose down -v                                              # stop and wipe the app DB volume
```
- No embedded `mongod`: `MONGO_URL` is required, the entrypoint exits with an error without it. Env vars are listed in the README.
- The image ships MongoDB 4.2 client tools only — legacy `mongo` shell and `mongodump`/`mongorestore` under `/opt/mongodb/bin/` (the app's default binary path).
- From a container the mongo-matrix servers are reachable as `host.docker.internal:<port>` (with Docker Desktop; on plain Docker add `--add-host=host.docker.internal:host-gateway` and note the servers bind to 127.0.0.1 only). The replica set `m80rs` advertises `localhost:27081`, so connect to it without `replicaSet=`.

## Gotchas
- Meteor builds every directory except `imports/`, `public/`, `private/`, `tests/` and dot-dirs as app code. Dev scripts belong in `scripts/` (ignored via `.meteorignore`), otherwise the app crashes on start.
- Shell / Schema Analyzer need a legacy `mongo` shell: set Settings → "Mongo binary path" to `~/.meteor/packages/meteor-tool/1.10.2/mt-os.linux.x86_64/dev_bundle/mongodb/bin/` (the default `/opt/mongodb/bin/` exists only in the Docker image; the bundled 3.4 shell can't connect to modern servers).
- Ignore the "Meteor 3.x is available" banner — don't run `meteor update`.
