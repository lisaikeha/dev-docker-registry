#!/bin/sh
set -e

REGISTRY_URL="${REGISTRY_URL:-http://registry:5000}"
REGISTRY_DATA="${REGISTRY_DATA:-/var/lib/registry}"
REGISTRY_USER="${REGISTRY_USER:-}"
REGISTRY_PASS="${REGISTRY_PASS:-}"

CURL_AUTH=""
if [ -n "$REGISTRY_USER" ] && [ -n "$REGISTRY_PASS" ]; then
  CURL_AUTH="-u ${REGISTRY_USER}:${REGISTRY_PASS}"
fi

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "Starting registry cleanup..."

# Step 1: Collect all tagged manifest digests per repository
catalog=$(curl -sSf ${CURL_AUTH} "${REGISTRY_URL}/v2/_catalog" | sed 's/.*"repositories":\[//;s/\].*//;s/"//g; s/,/ /g')

for repo in $catalog; do
  log "  Processing repository: $repo"

  # Get all tags for this repo
  tags_json=$(curl -sSf ${CURL_AUTH} "${REGISTRY_URL}/v2/${repo}/tags/list")
  tags=$(echo "$tags_json" | sed 's/.*"tags":\[//;s/\].*//;s/"//g; s/,/ /g')

  # Collect digests for every tagged manifest
  tagged_digests=""
  for tag in $tags; do
    if [ "$tag" = "null" ] || [ -z "$tag" ]; then continue; fi
    digest=$(curl -sSfI ${CURL_AUTH} \
      -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      "${REGISTRY_URL}/v2/${repo}/manifests/${tag}" \
      | grep -i 'docker-content-digest' | head -1 | awk '{print $2}' | tr -d '\r')
    if [ -n "$digest" ]; then
      tagged_digests="${tagged_digests} ${digest}"
    fi
  done

  # Find all manifests stored on disk
  manifests_dir="${REGISTRY_DATA}/docker/registry/v2/repositories/${repo}/_manifests/revisions/sha256"
  if [ -d "$manifests_dir" ]; then
    for hash_dir in "$manifests_dir"/*; do
      [ -d "$hash_dir" ] || continue
      digest="sha256:$(basename "$hash_dir")"

      # If this digest is not in the tagged set, delete it
      if ! echo "$tagged_digests" | grep -qF "$digest"; then
        log "    Deleting untagged manifest: ${digest}"
        curl -sSf -X DELETE ${CURL_AUTH} "${REGISTRY_URL}/v2/${repo}/manifests/${digest}" || true
      fi
    done
  fi
done

# Step 2: Run garbage collection on the registry container
log "  Running garbage collection..."
docker exec registry /bin/registry garbage-collect /etc/docker/registry/config.yml

log "Cleanup complete."
