#!/usr/bin/env bash
#
# Build the Ubuntu 26 image from this repository.
#
# Default behavior is local host-arch builds (no push):
#   ./build-local.sh
#
# Examples:
#   VARIANTS=u26 PHP_VERSION=8.5 ./build-local.sh
#   PUSH=1 ./build-local.sh
#   MULTI_ARCH=1 PUSH=1 ./build-local.sh
#
# Environment variables:
#   IMAGE          Docker image name (default: ownercz/nginx-php)
#   PHP_VERSION    Single PHP version to build (default: 8.5)
#   PHP_VERSIONS   Space-separated PHP versions to build; overrides PHP_VERSION when set
#   VARIANTS       Variant to build (only u26 is supported)
#   PUSH           0 local only, 1 push to registry (default: 0)
#   MULTI_ARCH     0 host arch build, 1 buildx multi-arch build (default: 0)
#   PLATFORMS      Buildx platforms when MULTI_ARCH=1 (default: linux/amd64,linux/arm64)
#   U26_CODENAME   Optional override for the u26 nginx repository codename
#   DEFAULT_PHP    Default PHP line for unscoped release tag behavior (default: 8.5)
#   ADDITIONAL_TAG Optional release tag; defaults to current UTC date dd-mm-yyyy

set -euo pipefail

IMAGE="${IMAGE:-ownercz/nginx-php}"
PHP_VERSION="${PHP_VERSION:-8.5}"
PHP_VERSIONS="${PHP_VERSIONS:-}"
VARIANTS="${VARIANTS:-u26}"
PUSH="${PUSH:-0}"
MULTI_ARCH="${MULTI_ARCH:-0}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
U26_CODENAME="${U26_CODENAME:-}"
DEFAULT_PHP="${DEFAULT_PHP:-8.5}"
ADDITIONAL_TAG="${ADDITIONAL_TAG:-}"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${REPO_ROOT}"

VCS_REF="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo local)}"
SHORT_SHA="${VCS_REF:0:10}"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EFFECTIVE_ADDITIONAL_TAG="${ADDITIONAL_TAG:-$(date -u +%d-%m-%Y)}"

create_builder_if_needed() {
    if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
        echo "Creating buildx builder..."
        docker buildx create --name multiarch-builder --driver docker-container --bootstrap
    fi
    docker buildx use multiarch-builder
}

build_variant() {
    local variant="$1"
    local php_version="$2"
    local tag_os_php="${IMAGE}:${variant}-php${php_version}"
    local tag_os="${IMAGE}:${variant}"
    local tag_sha="${IMAGE}:${variant}-php${php_version}-${SHORT_SHA}"
    local tag_os_php_additional="${IMAGE}:${variant}-php${php_version}-${EFFECTIVE_ADDITIONAL_TAG}"
    local tag_os_additional="${IMAGE}:${variant}-${EFFECTIVE_ADDITIONAL_TAG}"
    local tag_additional="${IMAGE}:${EFFECTIVE_ADDITIONAL_TAG}"

    echo
    echo "== Building ${variant} / PHP ${php_version} =="
    echo "  image:        ${IMAGE}"
    echo "  php:          ${php_version}"
    echo "  push:         ${PUSH}"
    echo "  multi-arch:   ${MULTI_ARCH}"
    echo "  extra tag:    ${EFFECTIVE_ADDITIONAL_TAG}"

    local build_args=(
        --file "${variant}/Dockerfile"
        --build-arg "PHP_VERSION=${php_version}"
        --build-arg "VCS_REF=${VCS_REF}"
        --build-arg "BUILD_DATE=${BUILD_DATE}"
        --tag "${tag_os_php}"
        --tag "${tag_sha}"
        --tag "${tag_os_php_additional}"
        --tag "${tag_os_additional}"
    )

    if [[ "${variant}" == "u26" && -n "${U26_CODENAME}" ]]; then
        build_args+=(--build-arg "UBUNTU_CODENAME=${U26_CODENAME}")
        echo "  u26 codename: ${U26_CODENAME}"
    fi

    build_args+=(--tag "${tag_os}")

    # Keep unscoped release tag aligned with the primary line only.
    if [[ "${variant}" == "u26" && "${php_version}" == "${DEFAULT_PHP}" ]]; then
        build_args+=(--tag "${tag_additional}")
    fi

    if [[ "${MULTI_ARCH}" == "1" ]]; then
        create_builder_if_needed

        if [[ "${PUSH}" == "1" ]]; then
            docker buildx build \
                --platform "${PLATFORMS}" \
                "${build_args[@]}" \
                --push \
                --progress=plain \
                "${variant}"
        else
            # buildx --load supports one platform only.
            local host_platform
            host_platform="$(docker version -f '{{.Server.Os}}/{{.Server.Arch}}')"
            echo "MULTI_ARCH=1 with PUSH=0 requested; loading host platform only: ${host_platform}"
            docker buildx build \
                --platform "${host_platform}" \
                "${build_args[@]}" \
                --load \
                --progress=plain \
                "${variant}"
        fi
    else
        if [[ "${PUSH}" == "1" ]]; then
            docker build \
                "${build_args[@]}" \
                "${variant}"
            docker push "${tag_os_php}"
            docker push "${tag_sha}"
            docker push "${tag_os_php_additional}"
            docker push "${tag_os_additional}"
            docker push "${tag_os}"
            if [[ "${variant}" == "u26" && "${php_version}" == "${DEFAULT_PHP}" ]]; then
                docker push "${tag_additional}"
            fi
        else
            docker build \
                "${build_args[@]}" \
                "${variant}"
        fi
    fi

    echo "Built ${tag_os_php}"
}

validate_variant() {
    local variant="$1"

    case "${variant}" in
        u26)
            ;;
        *)
            echo "Unknown variant: ${variant}" >&2
            echo "Supported variants: u26" >&2
            exit 1
            ;;
    esac

    if [[ ! -f "${variant}/Dockerfile" ]]; then
        echo "Missing Dockerfile for variant: ${variant}" >&2
        exit 1
    fi
}

echo "Repository:   ${REPO_ROOT}"
echo "Commit:       ${SHORT_SHA}"
echo "Build date:   ${BUILD_DATE}"
echo "Extra tag:    ${EFFECTIVE_ADDITIONAL_TAG}"
echo "Variants:     ${VARIANTS}"

if [[ -n "${PHP_VERSIONS}" ]]; then
    echo "PHP versions: ${PHP_VERSIONS}"
else
    echo "PHP versions: ${PHP_VERSION}"
fi

for variant in ${VARIANTS}; do
    validate_variant "${variant}"

    if [[ -n "${PHP_VERSIONS}" ]]; then
        for php_version in ${PHP_VERSIONS}; do
            build_variant "${variant}" "${php_version}"
        done
    else
        build_variant "${variant}" "${PHP_VERSION}"
    fi
done

echo
echo "Done."
