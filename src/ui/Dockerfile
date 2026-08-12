# Angular UI image - built by Node, served by Caddy, non-root, digest-pinned.
# Build context is ALWAYS the repo root:
#   docker build -t reference-ui:local -f src/ui/Dockerfile .
#
# Digests below were resolved 2026-08-12.

# --- Angular build (Node v22.23.2, npm 10.9.8) ---
FROM node:22-alpine@sha256:c610fcdfb1d5b4740dd70c284ed3cb16bb857e0f7166196e36a5501df7a3aa32 AS ng-builder
WORKDIR /src
# Dependency lists first, so the npm ci layer stays cached until THEY change.
COPY src/ui/package*.json ./
RUN npm ci
COPY src/ui/ ./
RUN npm run build -- --configuration production

# --- runtime (Caddy 2) ---
FROM caddy:2-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648 AS final
# libcap is unpinned deliberately: pinning an Alpine utility version breaks the
# build on every Alpine patch, and the base image itself is already digest-pinned.
# hadolint ignore=DL3018
RUN apk upgrade --no-cache && apk add --no-cache libcap
# UID is pinned and USER is NUMERIC on purpose - see the note in src/api/Dockerfile.
RUN addgroup -g 1001 -S appgroup && adduser -u 1001 -S -G appgroup appuser
# Strip the file capability BuildKit preserves. Caddy binds 2015/2016, which are
# non-privileged, so cap_net_bind_service is unnecessary - and its presence
# blocks exec under allowPrivilegeEscalation:false, so the pod never starts.
RUN setcap -r /usr/bin/caddy || true

# These defaults must never be empty strings. An empty BASE_URL leaves Caddy's
# `uri strip_prefix` with no argument and the container fails to start. Override
# BASE_URL with the real path prefix, or leave this sentinel in place.
ENV API_URL=http://127.0.0.1:8080 \
    BASE_URL=/__no_prefix__

COPY src/ui/Caddyfile /etc/caddy/Caddyfile
# 0555 so an arbitrary UID can still read and execute it.
COPY --chmod=0555 src/ui/docker-entrypoint.sh /docker-entrypoint.sh
# GP-21: angular.json must set outputPath to `dist`, so the bundle lands here.
COPY --from=ng-builder /src/dist/browser/ /site
# Group 0, not appgroup - see the note in src/api/Dockerfile.
RUN chown -R 1001:0 /site /config/caddy /data/caddy \
 && chmod -R g=u /site /config/caddy /data/caddy
USER 1001
EXPOSE 2015 2016
ENTRYPOINT ["/docker-entrypoint.sh"]
