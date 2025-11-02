#!/bin/bash

# Multi-architecture build script for Ampere CPU support

set -e

IMAGE_NAME="ownercz/nginx-php"
TAG="u24"
COMMIT_SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"

echo "Building multi-architecture Docker image for AMD64 and ARM64 (Ampere)..."

# Create buildx builder if it doesn't exist
if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
    echo "Creating buildx builder for multi-architecture builds..."
    docker buildx create --name multiarch-builder --driver docker-container --bootstrap
fi

# Use the multiarch builder
docker buildx use multiarch-builder

# Build and push the multi-architecture image
echo "Building for linux/amd64 and linux/arm64..."
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --file Dockerfile \
    --tag ${IMAGE_NAME}:${TAG} \
    --tag ${IMAGE_NAME}:${TAG}-${COMMIT_SHA} \
    --push \
    .

echo "Build completed successfully!"
echo "Image ${IMAGE_NAME}:${TAG} is now available for both AMD64 and ARM64 (Ampere) architectures."

# Show image info
docker images ${IMAGE_NAME}:${TAG}
