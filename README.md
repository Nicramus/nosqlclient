## Nosqlclient (Formerly Mongoclient), MongoDB Management Tool

> **Fork:** local development setup and scripts — see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

Cross-platform and self hosted, easy to use, MongoDB 4.0+ support and more features!

> NOSQLCLIENT IS NO LONGER BEING ACTIVELY DEVELOPED. I BELIEVE YOU CAN STILL USE DOCKER BUILDS AND FEEL FREE TO MAIL FOR INQUIRIES: ozdemirsercan27@gmail.com
  

[![Build Status](https://travis-ci.org/nosqlclient/nosqlclient.svg?branch=master)](https://travis-ci.org/nosqlclient/nosqlclient)
[![GitHub release](https://img.shields.io/github/release/nosqlclient/nosqlclient.svg)](https://github.com/nosqlclient/nosqlclient)
[![Docker Pulls](https://img.shields.io/docker/pulls/mongoclient/mongoclient.svg)](https://hub.docker.com/r/mongoclient/mongoclient/)
[![AGPLv3 License](https://img.shields.io/github/license/nosqlclient/nosqlclient.svg)](https://github.com/nosqlclient/nosqlclient/blob/master/LICENSE)


## Demo
[Try Demo Application](https://www.nosqlclient.com/demo/)

## Documentation
All documentation can be found in https://www.nosqlclient.com/docs

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
Please check [history](https://github.com/nosqlclient/nosqlclient/blob/master/HISTORY.MD) file for version information.


## License
Nosqlclient is licensed under [MIT](https://en.wikipedia.org/wiki/MIT_License) for prior version 2.0.0, but for 2.0.0 and higher versions are licensed under [AGPLv3](https://www.gnu.org/licenses/agpl-3.0.html).

### We use JetBrains products to develop Nosqlclient !
[![www.jetbrains.com](https://github.com/nosqlclient/nosqlclient/blob/master/public/jetbrains.svg)](http://www.jetbrains.com)
