# syntax=docker/dockerfile:1

# Node version must stay on 12.x — Meteor 1.10.2 bundles target Node 12.
ARG NODE_VERSION=12.22.12

# ---------- builder: Meteor toolchain + app build ----------
FROM node:${NODE_VERSION}-bullseye AS builder

ARG METEOR_RELEASE=1.10.2

USER node
ENV PATH=/home/node/.meteor:$PATH
WORKDIR /home/node/app

# Meteor installed as the unprivileged node user (no METEOR_ALLOW_SUPERUSER needed);
# release pinned to match .meteor/release
RUN curl -sSfL "https://install.meteor.com/?release=${METEOR_RELEASE}" | sh \
 && meteor --version

# npm deps first for layer caching
COPY --chown=node:node package.json package-lock.json ./
RUN meteor npm ci

COPY --chown=node:node . .
RUN meteor build --directory /home/node/dist --server-only \
 && cd /home/node/dist/bundle/programs/server \
 && meteor npm install --production \
 && meteor npm cache clean --force

# ---------- runtime: bundle only ----------
FROM node:${NODE_VERSION}-bullseye-slim

# Embedded MongoDB 4.2 as the app's internal DB (used when no MONGO_URL is given).
# Also provides the legacy `mongo` shell and mongodump/mongorestore used by the Shell and Backup pages.
ARG INSTALL_MONGO=true
ARG MONGO_TARBALL=mongodb-linux-x86_64-debian10-4.2.25

# default values for Meteor environment variables
ENV ROOT_URL=http://localhost \
    PORT=3000 \
    MONGOCLIENT_DEFAULT_CONNECTION_URL='' \
    MONGOCLIENT_CONNECTIONS_FILE_PATH=/opt/meteor/dist/predefined_connections.json

# Debian 11 is past end of LTS — its packages now live on archive.debian.org only.
RUN if [ "$INSTALL_MONGO" = true ]; then \
      printf '%s\n' 'deb http://archive.debian.org/debian bullseye main' \
                    'deb http://archive.debian.org/debian-security bullseye-security main' > /etc/apt/sources.list \
   && apt-get update \
   && apt-get install -y --no-install-recommends ca-certificates curl libcurl4 libssl1.1 \
   && curl -sSfL "https://fastdl.mongodb.org/linux/${MONGO_TARBALL}.tgz" -o /tmp/mongo.tgz \
   && mkdir -p /opt/mongodb \
   && tar -xzf /tmp/mongo.tgz --strip-components=1 -C /opt/mongodb \
   && ln -sf /opt/mongodb/bin/* /usr/local/bin/ \
   && mkdir -p /data/db && chown -R node:node /data \
   && apt-get purge -y --auto-remove curl \
   && rm -rf /tmp/* /var/lib/apt/lists/*; \
    fi

COPY --from=builder --chown=node:node /home/node/dist /opt/meteor/dist
COPY --chown=node:node .docker/entrypoint.sh /opt/meteor/dist/bundle/entrypoint.sh
COPY LICENSE /opt/meteor/LICENSE

EXPOSE 3000
USER node
WORKDIR /opt/meteor/dist/bundle

ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "main.js"]
