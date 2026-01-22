#!/bin/bash

# VideoPipe2 Docker Build Script
# This script builds the Docker image for VideoPipe2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================================"
echo "Building VideoPipe2 Docker Image"
echo "================================================"

# Build options
BUILD_TYPE=${1:-"base"}  # base, cuda, full
IMAGE_NAME="videopipe2"
IMAGE_TAG="latest"

case $BUILD_TYPE in
    base)
        echo "Building base image (CPU only)..."
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        ;;
    cuda)
        echo "Building CUDA-enabled image..."
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG}-cuda .
        ;;
    full)
        echo "Building full image with all features..."
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG}-full .
        ;;
    *)
        echo "Unknown build type: $BUILD_TYPE"
        echo "Usage: $0 [base|cuda|full]"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "Build completed successfully!"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "================================================"
echo ""
echo "To run the container, use:"
echo "  ./docker-run.sh"
echo "Or with docker-compose:"
echo "  docker-compose up -d"
echo ""
