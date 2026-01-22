# VideoPipe2 Docker Environment Setup Guide

This document provides step-by-step instructions for setting up and running VideoPipe2 in Docker containers on different environments.

---

## Table of Contents

1. [macOS with Docker Desktop](#macos-with-docker-desktop)
2. [macOS with Docker Desktop (GUI Applications)](#macos-with-docker-desktop-gui-applications)
3. [Linux with Docker](#linux-with-docker)
4. [Linux with Docker (GPU Support)](#linux-with-docker-gpu-support)
5. [Common Issues and Solutions](#common-issues-and-solutions)

---

## macOS with Docker Desktop

### Prerequisites

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install XQuartz for GUI support
brew install --cask xquartz

# Verify installation
xquartz --version
```

### One-Time Setup

```bash
# 1. Enable XQuartz TCP connections (required for X11 forwarding)
defaults write org.xquartz.X11 nolisten_tcp 0

# 2. Restart XQuartz to apply changes
pkill Xquartz && sleep 2 && open -a XQuartz

# 3. Verify XQuartz is running and listening on TCP
lsof -i -P | grep LISTEN | grep 6000
```

### Daily Usage

```bash
# Build the Docker image
./docker-build.sh

# Start the container
./docker-run.sh

# Or using docker-compose
docker-compose -f docker-compose-dev.yml up -d
docker exec -it videopipe2_dev bash

# Run samples
./docker-exec.sh list-samples
./docker-exec.sh run face_tracking_sample

# Or from inside container
cd /workspace/VideoPipe2
./build/bin/face_tracking_sample
```

### Environment Variables

```bash
# Optional: Set custom data path
export VP_DATA_PATH=/path/to/your/data

# Optional: Set display (auto-configured by scripts)
export DISPLAY=:0
```

### Key Configuration Points

- **DISPLAY**: `host.docker.internal:0` (automatically set by scripts)
- **Network**: Uses Docker Desktop networking (not `--network host`)
- **X11**: Uses TCP connection to XQuartz
- **GPU**: Not available on macOS (CPU mode only)

---

## macOS with Docker Desktop (GUI Applications)

### Additional Steps for GUI Support

After completing the basic macOS setup, follow these steps:

```bash
# 1. Allow X11 connections (one-time setup)
export DISPLAY=:0
/opt/X11/bin/xhost +localhost

# 2. Start the container
./docker-run.sh

# 3. Verify X11 forwarding
./docker-test-x11.sh

# 4. Run GUI sample
./docker-exec.sh run face_tracking_sample
```

### X11 Configuration Details

**XQuartz Preferences:**
- Open XQuartz → Preferences → Security
- Check "Allow connections from network clients"
- Check "Allow connections from network clients" (for older XQuartz versions)

**Verification:**
```bash
# Check XQuartz is running
ps aux | grep -i xquartz

# Check XQuartz is listening on port 6000
lsof -i -P | grep LISTEN | grep 6000

# Check xhost permissions
/opt/X11/bin/xhost
# Should show: INET:localhost, INET6:localhost
```

### Troubleshooting GUI Issues

**Issue: "Can't initialize GTK backend"**
```bash
# Solution 1: Restart XQuartz
pkill Xquartz && sleep 2 && open -a XQuartz

# Solution 2: Reset xhost permissions
export DISPLAY=:0
/opt/X11/bin/xhost +
export DISPLAY=:0
/opt/X11/bin/xhost +localhost

# Solution 3: Restart container
docker stop videopipe2_dev
docker rm videopipe2_dev
./docker-run.sh
```

---

## Linux with Docker

### Prerequisites

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Setup

```bash
# 1. Allow X11 connections for Docker containers
xhost +local:docker

# 2. Build the Docker image
./docker-build.sh

# 3. Start the container
./docker-run.sh

# Or using docker-compose
docker-compose -f docker-compose.yml up -d
docker exec -it videopipe2_dev bash

# 4. Run samples
./docker-exec.sh list-samples
./docker-exec.sh run 1-1-1_sample
```

### Environment Variables

```bash
# Set display environment
export DISPLAY=:0

# Optional: Set custom data path
export VP_DATA_PATH=/path/to/your/data

# Optional: Build with specific options
export VP_WITH_CUDA=OFF
export VP_WITH_TRT=OFF
```

### Key Configuration Points

- **DISPLAY**: `:0` (uses host X11 socket)
- **Network**: `--network host` (access to host X11)
- **X11 Socket**: `/tmp/.X11-unix/X0`
- **Permissions**: Uses `xhost +local:docker`

---

## Linux with Docker (GPU Support)

### Prerequisites

```bash
# Install NVIDIA Drivers
sudo apt-get update
sudo apt-get install -y nvidia-driver-535

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Verify installation
sudo nvidia-smi
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Setup with GPU Support

```bash
# 1. Allow X11 connections
xhost +local:docker

# 2. Build the Docker image with CUDA support
./docker-build.sh cuda

# 3. Start the container with GPU
./docker-run.sh

# The script automatically detects NVIDIA GPU and enables it

# 4. Inside container, build VideoPipe2 with CUDA
cd /workspace/VideoPipe2
mkdir -p build && cd build
cmake -DVP_WITH_CUDA=ON -DVP_WITH_TRT=ON ..
make -j$(nproc)

# 5. Run samples with GPU acceleration
./docker-exec.sh run trt_yolov8_sample
```

### Environment Variables for GPU

```bash
# GPU configuration
export VP_WITH_CUDA=ON
export VP_WITH_TRT=ON
export VP_WITH_PADDLE=ON

# Display configuration
export DISPLAY=:0

# Data configuration
export VP_DATA_PATH=/path/to/your/data

# Complex samples (optional)
export VP_BUILD_COMPLEX_SAMPLES=ON
```

### Key Configuration Points

- **DISPLAY**: `:0` (host X11)
- **Network**: `--network host`
- **GPU**: `--runtime=nvidia --gpus all`
- **CUDA**: CUDA 11.8 pre-installed
- **NVIDIA Driver**: Required for GPU access

### Verify GPU Access

```bash
# Check GPU from host
nvidia-smi

# Check GPU from container
docker exec -it videopipe2_dev nvidia-smi

# Should show NVIDIA GPU information
```

---

## Common Issues and Solutions

### Issue: GTK Backend Initialization Failed

**Error Message:**
```
terminate called after throwing an instance of 'cv::Exception'
  what():  OpenCV(4.8.0) /tmp/opencv-4.8.0/modules/highgui/src/window_gtk.cpp:638: error: (-2:Unspecified error) Can't initialize GTK backend in function 'cvInitSystem'
```

**macOS Solution:**
```bash
# 1. Enable XQuartz TCP
defaults write org.xquartz.X11 nolisten_tcp 0

# 2. Restart XQuartz
pkill Xquartz && sleep 2 && open -a XQuartz

# 3. Configure xhost
export DISPLAY=:0
/opt/X11/bin/xhost +localhost

# 4. Restart container
docker stop videopipe2_dev && docker rm videopipe2_dev
./docker-run.sh
```

**Linux Solution:**
```bash
# 1. Allow X11 connections
xhost +local:docker

# 2. Restart container
docker restart videopipe2_dev
```

### Issue: Permission Denied

**Error Message:**
```
Permission denied (publickey,keyboard-interactive).
```

**Solution:**
```bash
# Fix file permissions on mounted volumes
sudo chown -R $USER:$USER /path/to/data

# Or rebuild container without cached volumes
docker-compose down -v
docker-compose up -d
```

### Issue: Container Won't Start

**Error Message:**
```
Error starting userland proxy: listen tcp 0.0.0.0:80: bind: address already in use
```

**Solution:**
```bash
# Check for existing containers
docker ps -a

# Stop and remove conflicting container
docker stop videopipe2_dev
docker rm videopipe2_dev

# Or find and stop the process using the port
sudo lsof -i :80 | grep LISTEN
```

### Issue: GPU Not Detected

**Error Message:**
```
WARNING: The NVIDIA Driver was not detected.  GPU functionality will not be available.
```

**Solution:**
```bash
# 1. Install NVIDIA Container Toolkit (see Linux GPU section)

# 2. Verify NVIDIA driver is loaded
sudo nvidia-smi

# 3. Test GPU access
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# 4. If still failing, restart Docker daemon
sudo systemctl restart docker
```

### Issue: Slow Build Performance

**Solution:**
```bash
# Increase Docker resources (Docker Desktop → Settings → Resources)
# - CPUs: 4+
# - Memory: 8GB+
# - Swap: 2GB+

# Use build cache
cd /workspace/VideoPipe2/build
make -j$(nproc)
```

### Issue: Video File Not Found

**Solution:**
```bash
# Check data directory mount
docker exec videopipe2_dev ls -la /workspace/vp_data/test_video/

# Verify data path is correct
docker inspect videopipe2_dev | grep -A 10 Mounts

# Run from correct working directory
cd /workspace/VideoPipe2
./build/bin/sample_name
```

---

## Quick Reference Commands

### Container Management

```bash
# Start container
./docker-run.sh

# Stop container
docker stop videopipe2_dev

# Restart container
docker restart videopipe2_dev

# Remove container
docker stop videopipe2_dev && docker rm videopipe2_dev

# View logs
docker logs videopipe2_dev --tail 100
```

### Build Commands

```bash
# Build from scratch
./docker-exec.sh rebuild

# Clean build
./docker-exec.sh clean

# Build with options
./docker-exec.sh build "-DVP_WITH_CUDA=ON -DVP_WITH_TRT=ON"
```

### Sample Execution

```bash
# List all samples
./docker-exec.sh list-samples

# Run specific sample
./docker-exec.sh run face_tracking_sample

# Run with custom arguments
docker exec -it videopipe2_dev bash -c "cd /workspace/VideoPipe2 && ./build/bin/sample_name --option value"
```

### Development Workflow

```bash
# 1. Edit source code on host
vim /path/to/source.cpp

# 2. Rebuild inside container
./docker-exec.sh rebuild

# 3. Test immediately
./docker-exec.sh run sample_name

# 4. Iterate as needed
```

---

## Environment Comparison

| Feature | macOS Desktop | Linux (No GPU) | Linux (GPU) |
|----------|---------------|-------------------|--------------|
| X11 Support | ✓ (via host.docker.internal:0) | ✓ (via /tmp/.X11-unix/X0) | ✓ (via /tmp/.X11-unix/X0) |
| GPU Support | ✗ | ✗ | ✓ (CUDA 11.8) |
| Network Mode | Docker Desktop | --network host | --network host |
| X11 Method | TCP to XQuartz | Unix Socket | Unix Socket |
| Authorization | xhost +localhost | xhost +local:docker | xhost +local:docker |
| Performance | Good | Best | Best (with GPU) |

---

## Advanced Configuration

### Custom CMake Build Options

```bash
# Inside container, in build directory:
cmake -DVP_WITH_CUDA=ON \
      -DVP_WITH_TRT=ON \
      -DVP_WITH_PADDLE=ON \
      -DVP_WITH_KAFKA=ON \
      -DVP_WITH_LLM=ON \
      -DVP_WITH_FFMPEG=ON \
      -DVP_BUILD_COMPLEX_SAMPLES=ON \
      ..
```

### Multi-GPU Configuration

```bash
# Start container with multiple GPUs
docker run -it --rm \
    --gpus '"device=0,1"' \
    --name videopipe2_dev \
    -e NVIDIA_VISIBLE_DEVICES=0,1 \
    ... other options ...
```

### Custom Data Mounts

```bash
# Edit docker-run.sh or docker-compose.yml
# Add custom volume mounts:
-v /path/to/custom/data:/workspace/custom_data
-v /path/to/models:/workspace/models
```

---

## Additional Resources

- [Main README](./README.md)
- [Docker README](./DOCKER_README.md)
- [X11 Quick Start](./X11_QUICKSTART.md)
- [Samples Documentation](./SAMPLES.md)
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Docker Documentation](https://github.com/NVIDIA/nvidia-docker)

---

## Support

For issues or questions:

1. Check [Troubleshooting](#common-issues-and-solutions) section
2. Review [DOCKER_README.md](./DOCKER_README.md)
3. Search existing issues in GitHub repository
4. Create new issue with detailed environment information

**Required Information for Bug Reports:**
- Operating System and version
- Docker and Docker Compose versions
- XQuartz version (macOS) or Xorg version (Linux)
- NVIDIA driver version (Linux with GPU)
- Complete error message
- Steps to reproduce

---

## Summary

This guide covers:

✅ macOS with Docker Desktop setup
✅ X11 forwarding configuration
✅ GPU support setup (Linux)
✅ Common issues and solutions
✅ Development workflow
✅ Advanced configuration options

**Follow the appropriate section for your environment and start running VideoPipe2 in Docker today!** 🚀
