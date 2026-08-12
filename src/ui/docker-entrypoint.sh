#!/bin/sh
set -e

# Caddy's `uri strip_prefix` requires an argument. A Caddyfile default of the
# form {$BASE_URL:/sentinel} only applies when the variable is UNSET - it does
# not apply when the variable is set to an empty string, which is exactly what
# `env: [{name: BASE_URL, value: ""}]` produces in a Deployment.
#
# Normalising here makes the container immune to how the Deployment is written,
# rather than relying on everyone remembering the rule.
[ -z "${BASE_URL}" ] && BASE_URL=/__no_prefix__
[ -z "${API_URL}" ] && API_URL=http://127.0.0.1:8080
export BASE_URL API_URL

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
