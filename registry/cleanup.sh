#!/bin/sh
# Registry cleanup using the official built-in garbage-collect.
#
# --delete-untagged does everything in one step:
#   removes all manifests that have no tag pointing to them,
#   then deletes blobs that are no longer referenced.
#
# No JSON parsing, no API calls, no fragile shell scripting.
# This is the recommended approach per Docker Distribution docs.

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "Running garbage collection (--delete-untagged)..."
docker exec registry /bin/registry garbage-collect --delete-untagged /etc/docker/registry/config.yml

log "Cleanup complete."
