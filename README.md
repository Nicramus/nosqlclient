## Nosqlclient (fork), MongoDB Management Tool

Web-based, self-hosted MongoDB management tool (formerly Mongoclient).

[![ci](https://github.com/Nicramus/nosqlclient/actions/workflows/ci.yml/badge.svg)](https://github.com/Nicramus/nosqlclient/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/v/release/Nicramus/nosqlclient)](https://github.com/Nicramus/nosqlclient/releases/latest)
[![AGPLv3 License](https://img.shields.io/github/license/Nicramus/nosqlclient)](LICENSE)

> **This is a maintained fork** of [nosqlclient/nosqlclient](https://github.com/nosqlclient/nosqlclient)
> by Sercan Özdemir and contributors, which is no longer actively developed (last upstream release 4.0.1).
> Please report issues for this fork at [Nicramus/nosqlclient](https://github.com/Nicramus/nosqlclient/issues),
> not upstream.

### What's different from upstream
- Docker image rebuilt: multi-stage build, no embedded `mongod` (external `MONGO_URL` required),
  [docker-compose.yml](docker-compose.yml) reference deployment, images published to
  `ghcr.io/nicramus/nosqlclient` instead of Docker Hub `mongoclient/mongoclient`.
- Browsing a collection no longer runs a full collection scan; `defaultFindLimit` setting for FIND without a limit.
- "New version available" check points at this fork's releases.
- CI: lint, unit tests, CodeQL, dependency review and image scanning on every PR.

See [CHANGELOG.md](CHANGELOG.md) for all changes, [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the local
development setup. Upstream documentation (https://www.nosqlclient.com/docs) still describes most features,
but the site and its demo are no longer maintained.

## Docker

> **Breaking change (fork 4.1.0):** the image no longer contains its own `mongod`.
> `MONGO_URL` (a MongoDB for the app's own data: saved connections, settings) is now required,
> and mounting `/data/db` into the nosqlclient container has no effect.
> To keep data from an older container, `mongodump` its `/data/db` database (`meteor`) and restore it
> into the new MongoDB, or start a `mongo` container on the old `/data/db` directory.

Images are published to GHCR for every release: `ghcr.io/nicramus/nosqlclient` with tags `X.Y.Z`, `X.Y`, `X`
and `latest` (linux/amd64).

Reference deployment with [docker-compose.yml](docker-compose.yml) (nosqlclient + a `mongo` service with a volume):

```bash
docker compose up -d                 # http://localhost:3000
docker compose pull && docker compose up -d   # update to the latest release
docker compose up -d --build         # build the image from this checkout instead
```

Or run the image against an existing MongoDB:

```bash
docker run -d -p 3000:3000 -e MONGO_URL=mongodb://db.example.com:27017/nosqlclient ghcr.io/nicramus/nosqlclient:latest
```

The image still ships the MongoDB 4.2 client tools (legacy `mongo` shell, `mongodump`/`mongorestore`/
`mongoexport`/`mongoimport` in `/opt/mongodb/bin/`) for the Shell and Backup pages.

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `MONGO_URL` | — (required) | MongoDB for the app's own data. Alternatively built from `MONGO_ADDRESSES` (`host:port[,host:port]`), `MONGO_USERNAME`, `MONGO_PASSWORD`, `MONGO_DATABASE` (`meteor`), `MONGO_SCHEME` (`mongodb`), `MONGO_TLS` (`false`), `MONGO_OPT_PARAMS`. |
| `ROOT_URL` | `http://localhost` | Public URL of the app. |
| `PORT` | `3000` | HTTP port inside the container. |
| `MONGOCLIENT_DEFAULT_CONNECTION_URL` | — | Connection added on startup. When `MONGO_URL` is built from `MONGO_ADDRESSES`, defaults to that URL. |
| `MONGOCLIENT_CONNECTIONS_FILE_PATH` | `/opt/meteor/dist/predefined_connections.json` | JSON file with connections added on startup. |
| `MONGOCLIENT_AUTH` | — | `true` enables HTTP basic auth with `MONGOCLIENT_USERNAME` / `MONGOCLIENT_PASSWORD`. |
| `MONGOCLIENT_LOG_LEVEL` | `debug` | Server log level. |
| `STARTUP_DELAY` | — | Seconds to wait before starting the app. |

Every variable read by the entrypoint (`MONGO_*`, `MONGOCLIENT_DEFAULT_CONNECTION_URL`, `MONGOCLIENT_USERNAME`,
`MONGOCLIENT_PASSWORD`) can also be read from a file via `<NAME>_FILE` (Docker secrets).

Build arg `INSTALL_MONGO_TOOLS=false` leaves out the MongoDB client tools (Shell and Backup pages won't work).


## History
Changes in this fork: [CHANGELOG.md](CHANGELOG.md). Upstream history up to 4.0.1: [HISTORY.MD](HISTORY.MD).


## License
Nosqlclient is licensed under [MIT](https://en.wikipedia.org/wiki/MIT_License) for prior version 2.0.0, but for 2.0.0 and higher versions are licensed under [AGPLv3](https://www.gnu.org/licenses/agpl-3.0.html) ([LICENSE](LICENSE)).
This fork is distributed under the same AGPLv3 terms. Original work © Sercan Özdemir and the nosqlclient contributors.

If you run a modified version of this fork as a network service, AGPLv3 §13 requires you to offer its users the
corresponding source code; the "Source code" link in the app's About dialog points here — update it if you publish
your changes elsewhere.

Upstream was developed with JetBrains products ([jetbrains.svg](public/jetbrains.svg)).
