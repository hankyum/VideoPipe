#!/bin/bash

# VideoPipe2 Docker Exec Script
# This script provides easy access to common operations inside the container
#
# Usage: ./docker-exec.sh <command> [options]
#
# Commands:
#   bash, shell        - Open bash shell in container
#   build              - Build VideoPipe2 inside container
#   clean              - Clean build directory
#   rebuild            - Rebuild VideoPipe2 from scratch
#   test               - Run sample tests (list binaries)
#   list-samples       - List all available sample programs
#   run <sample_name>  - Run a specific sample program
#   custom             - Execute custom command inside container

set -e

CONTAINER_NAME="videopipe2_dev"

# Check if container is running
if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "Error: Container ${CONTAINER_NAME} is not running."
    echo "Please start it first with: ./docker-run.sh or docker-compose up -d"
    exit 1
fi

# Parse command
COMMAND=${1:-"bash"}

case $COMMAND in
    bash|shell)
        echo "Opening bash shell in container..."
        docker exec -it ${CONTAINER_NAME} /bin/bash
        ;;
    build)
        echo "Building VideoPipe2 inside container..."
        docker exec -it ${CONTAINER_NAME} /bin/bash -c "
            cd /workspace/VideoPipe2
            mkdir -p build
            cd build
            cmake ${2:-.} ..
            make -j\$(nproc)
        "
        ;;
    clean)
        echo "Cleaning build directory..."
        docker exec -it ${CONTAINER_NAME} /bin/bash -c "
            cd /workspace/VideoPipe2
            rm -rf build/*
            echo 'Build directory cleaned.'
        "
        ;;
    rebuild)
        echo "Rebuilding VideoPipe2 from scratch..."
        docker exec -it ${CONTAINER_NAME} /bin/bash -c "
            cd /workspace/VideoPipe2
            rm -rf build
            mkdir -p build
            cd build
            cmake ${2:-.} ..
            make -j\$(nproc)
        "
        ;;
    list-samples)
        echo "Listing available samples..."
        docker exec -it ${CONTAINER_NAME} /bin/bash -c "
            cd /workspace/VideoPipe2/build
            if [ -d 'bin' ]; then
                echo '=== Simple Samples (in build/bin) ==='
                ls -1 bin/
            else
                echo 'No binaries found. Please build first.'
            fi
        "
        echo ""
        echo "=== Complex Samples (need VP_BUILD_COMPLEX_SAMPLES=ON) ==="
        echo "  face_recognize/face_recognize_pipeline"
        echo "  similiarity_search/face_encoding_pipeline"
        echo "  similiarity_search/vehicle_encoding_pipeline"
        echo "  vehicle_behaviour_analysis/vehicle_ba_pipeline"
        echo "  vehicle_property_and_similiarity_search/vehicle_encoding_classify_pipeline"
        echo "  lpr_camera/plate_recognize_pipeline"
        echo "  math_review/math_expression_check_pipeline"
        ;;
    run)
        SAMPLE_NAME=${2:-""}
        if [ -z "$SAMPLE_NAME" ]; then
            echo "Error: Please specify a sample name"
            echo "Usage: ./docker-exec.sh run <sample_name>"
            echo ""
            echo "Use './docker-exec.sh list-samples' to see available samples"
            exit 1
        fi

        # Check if sample is in build/bin
        if docker exec ${CONTAINER_NAME} [ -f "/workspace/VideoPipe2/build/bin/$SAMPLE_NAME" ]; then
            echo "Running sample: $SAMPLE_NAME"
            docker exec -it ${CONTAINER_NAME} /bin/bash -c "
                cd /workspace/VideoPipe2/build
                ./bin/$SAMPLE_NAME
            "
        # Check if sample is in complex samples directories
        elif docker exec ${CONTAINER_NAME} [ -f "/workspace/VideoPipe2/samples/$SAMPLE_NAME/$SAMPLE_NAME" ]; then
            echo "Running complex sample: $SAMPLE_NAME"
            docker exec -it ${CONTAINER_NAME} /bin/bash -c "
                cd /workspace/VideoPipe2/samples/$SAMPLE_NAME
                ./$SAMPLE_NAME
            "
        else
            echo "Error: Sample '$SAMPLE_NAME' not found"
            echo ""
            echo "Use './docker-exec.sh list-samples' to see available samples"
            exit 1
        fi
        ;;
    test)
        echo "Running sample tests..."
        docker exec -it ${CONTAINER_NAME} /bin/bash -c "
            cd /workspace/VideoPipe2/build
            if [ -d 'bin' ]; then
                ls -la bin/
            else
                echo 'No binaries found. Please build first.'
            fi
        "
        ;;
    *)
        echo "Executing custom command: $*"
        docker exec -it ${CONTAINER_NAME} /bin/bash -c "$*"
        ;;
esac
