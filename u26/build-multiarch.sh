#!/bin/bash
#
# Multi-architecture build & publish for the u26 line.
#
# Builds linux/amd64 + linux/arm64 (Ampere) and pushes the same set of tags
# the CI publishes, so a manual release from a developer machine produces an
# identical Docker Hub state.
#
# Usage:
#   ./build-multiarch.sh                  # default PHP, pushes
#   PHP_VERSION=8.4 ./build-multiarch.sh  # other PHP minor
#   PUSH=0 ./build-multiarch.sh           # local-only (no push, no extra tags)

set -euo pipefail

IMAGE="${IMAGE:-ownercz/nginx-php}"
OS_TAG="${OS_TAG:-u26}"
DEFAULT_PHP="${DEFAULT_PHP:-8.5}"
PHP_VERSION="${PHP_VERSION:-$DEFAULT_PHP}"
UBUNTU_CODENAME="${UBUNTU_CODENAME:-resolute}"
PUSH="${PUSH:-1}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$SCRIPT_DIR"

VCS_REF="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo local)}"
SHORT_SHA="${VCS_REF:0:10}"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "Image:    ${IMAGE}"
echo "OS tag:   ${OS_TAG}"
echo "PHP:      ${PHP_VERSION}  (default: ${DEFAULT_PHP})"
echo "Codename: ${UBUNTU_CODENAME}"
echo "Sha:      ${SHORT_SHA}"
echo "Build:    ${BUILD_DATE}"
echo "Push:     ${PUSH}"

TAGS=()
add_tag() { TAGS+=(--tag "${IMAGE}:$1"); echo "  + ${IMAGE}:$1"; }

echo "Tags:"
add_tag "${OS_TAG}-php${PHP_VERSION}"
add_tag "${OS_TAG}-php${PHP_VERSION}-${SHORT_SHA}"
add_tag "php${PHP_VERSION}"

if [ "$PHP_VERSION" = "$DEFAULT_PHP" ]; then
    add_tag "${OS_TAG}"
    add_tag "${OS_TAG}-${SHORT_SHA}"
    add_tag "latest"
fi

if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
    echo "Creating buildx builder..."
    docker buildx create --name multiarch-builder --driver docker-container --bootstrap
fi
docker buildx use multiarch-builder

BUILD_ARGS=(
    --platform "linux/amd64,linux/arm64"
    --file Dockerfile
    --build-arg "PHP_VERSION=${PHP_VERSION}"
    --build-arg "UBUNTU_CODENAME=${UBUNTU_CODENAME}"
    --build-arg "VCS_REF=${VCS_REF}"
    --build-arg "BUILD_DATE=${BUILD_DATE}"
    --progress=plain
)

if [ "$PUSH" = "1" ]; then
    docker buildx build "${BUILD_ARGS[@]}" "${TAGS[@]}" --push .
    echo "Pushed."
    docker buildx imagetools inspect "${IMAGE}:${OS_TAG}-php${PHP_VERSION}"
else
    # Local builds: skip multi-arch (buildx --load only supports single platform),
    # rebuild for the host arch only and apply just the OS-pinned per-PHP tag.
    docker buildx build \
        --platform "$(docker version -f '{{.Server.Os}}/{{.Server.Arch}}')" \
        --file Dockerfile \
        --build-arg "PHP_VERSION=${PHP_VERSION}" \
        --build-arg "UBUNTU_CODENAME=${UBUNTU_CODENAME}" \
        --build-arg "VCS_REF=${VCS_REF}" \
        --build-arg "BUILD_DATE=${BUILD_DATE}" \
        --tag "${IMAGE}:${OS_TAG}-php${PHP_VERSION}" \
        --load \
        --progress=plain \
        .
    echo "Loaded ${IMAGE}:${OS_TAG}-php${PHP_VERSION} into local docker."
fi

