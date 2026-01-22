#!/bin/bash

# VideoPipe2 Docker Run Script
# This script runs the VideoPipe2 Docker container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================================"
echo "Starting VideoPipe2 Docker Container"
echo "================================================"

# Configuration
CONTAINER_NAME="videopipe2_dev"
IMAGE_NAME="videopipe2:latest"
VP_DATA_PATH="${VP_DATA_PATH:-../vp_data}"

# Check if container is already running
if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "Container ${CONTAINER_NAME} is already running."
    echo "Attaching to existing container..."
    docker exec -it ${CONTAINER_NAME} /bin/bash
    exit 0
fi

# Check if container exists but is stopped
if [ "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
    echo "Starting stopped container ${CONTAINER_NAME}..."
    docker start ${CONTAINER_NAME}
    docker exec -it ${CONTAINER_NAME} /bin/bash
    exit 0
fi

# Run new container
echo "Creating new container ${CONTAINER_NAME}..."

# Check if running on a system with NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected, enabling GPU support..."
    GPU_ARGS="--runtime=nvidia --gpus all"
else
    echo "No NVIDIA GPU detected, running in CPU mode..."
    GPU_ARGS=""
fi

# X11 configuration
# For Docker Desktop on macOS, use host.docker.internal for X11
if [[ "$OSTYPE" == "darwin"* ]]; then
    DISPLAY_VALUE="host.docker.internal:0"
    NETWORK_MODE=""
    echo "Using Docker Desktop X11 forwarding mode (host.docker.internal:0)"
else
    DISPLAY_VALUE="${DISPLAY:-:0}"
    NETWORK_MODE="--network host"
    echo "Using Linux X11 forwarding mode (DISPLAY=$DISPLAY_VALUE)"
fi

docker run -it --rm \
    --name ${CONTAINER_NAME} \
    ${GPU_ARGS} \
    -e DISPLAY=${DISPLAY_VALUE} \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
    -v ${SCRIPT_DIR}:/workspace/VideoPipe2 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v ${VP_DATA_PATH}:/workspace/vp_data \
    -v "${VP_DATA_PATH}/output:/app/output" \
    ${NETWORK_MODE} \
    --privileged \
    -w /workspace/VideoPipe2 \
    ${IMAGE_NAME} \
    /bin/bash

echo ""
echo "================================================"
echo "Container stopped."
echo "================================================"
