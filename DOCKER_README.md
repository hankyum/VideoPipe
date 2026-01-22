# VideoPipe2 Docker Setup Guide

This directory contains Docker configuration files and helper scripts to easily build and run VideoPipe2 in a containerized environment.

## 📚 Additional Documentation

For detailed environment-specific setup instructions, see:
- **[Environment Setup Guide](./ENVIRONMENT_SETUP.md)** - Complete setup for macOS, Linux (CPU/GPU)
- **[X11 Quick Start](./X11_QUICKSTART.md)** - Quick X11 forwarding setup for macOS

## 📋 Prerequisites

- Docker Engine (20.10+)
- Docker Compose (1.29+)
- NVIDIA Docker Runtime (if using GPU)
- At least 10GB free disk space

## 🚀 Quick Start

### Option 1: Using Shell Scripts (Recommended)

```bash
# 1. Build the Docker image
./docker-build.sh

# 2. (macOS only) Enable XQuartz TCP and set up X11 forwarding
defaults write org.xquartz.X11 nolisten_tcp 0
pkill Xquartz && sleep 2 && open -a XQuartz
./docker-setup-x11.sh

# 3. Run the container
./docker-run.sh

# 4. Inside the container, build VideoPipe2
cd /workspace/VideoPipe2
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# 5. Run samples
./docker-exec.sh list-samples
./docker-exec.sh run face_tracking_sample
```

**Note for macOS:**
The script automatically uses `host.docker.internal:0` for X11 forwarding on macOS, which is required for Docker Desktop.

### Option 2: Using Docker Compose

```bash
# Start the development container
docker-compose -f docker-compose-dev.yml up -d

# Enter the container
docker-compose -f docker-compose-dev.yml exec videopipe2-dev bash

# Build VideoPipe2 inside container
cd build
cmake ..
make -j$(nproc)
```

## 📁 File Structure

```
VideoPipe2/
├── Dockerfile                 # Main Docker image definition
├── docker-compose.yml         # Docker Compose configuration
├── docker-compose-dev.yml     # Development environment configuration
├── .dockerignore             # Files to exclude from Docker build
├── docker-build.sh           # Script to build Docker image
├── docker-run.sh             # Script to run Docker container
├── docker-exec.sh            # Script for common container operations
├── docker-setup-x11.sh        # X11 setup script for macOS GUI applications
├── docker-test-x11.sh         # X11 forwarding test script
└── DOCKER_README.md          # This file
```

## 🛠️ Helper Scripts

### docker-build.sh
Builds the Docker image with all dependencies.

```bash
./docker-build.sh [base|cuda|full]
```

### docker-run.sh
Runs the Docker container with proper GPU and volume mounts.

```bash
./docker-run.sh
```

Features:
- Automatically detects NVIDIA GPU
- Mounts project directory for live development
- Enables X11 forwarding for GUI applications
- Reuses existing container if available

### docker-exec.sh
Provides easy access to common operations inside the container.

```bash
# Open bash shell
./docker-exec.sh bash

# Build VideoPipe2
./docker-exec.sh build

# Build with CMake options
./docker-exec.sh build "-DVP_WITH_CUDA=ON -DVP_WITH_TRT=ON"

# Clean build directory
./docker-exec.sh clean

# Complete rebuild
./docker-exec.sh rebuild

# List available samples
./docker-exec.sh list-samples

# Run a sample
./docker-exec.sh run face_tracking_sample

# Run custom command
./docker-exec.sh "cd build && ls -la"
```

### docker-setup-x11.sh
Configures X11 forwarding for GUI applications (macOS only).

```bash
# Run before starting container for GUI support
./docker-setup-x11.sh
```

This script:
- Checks and installs XQuartz if needed
- Configures socat for X11 socket forwarding
- Sets up X11 permissions for Docker containers
- Creates necessary X11 socket files

Required for running samples that use `cv::imshow()` or other OpenCV GUI functions on macOS.

### docker-test-x11.sh
Tests X11 forwarding configuration in the running container.

```bash
# Run after starting container to verify X11 forwarding
./docker-test-x11.sh
```

This script checks:
- DISPLAY environment variable in container
- X11 socket connectivity
- XAUTHORITY file mounting
- OpenCV installation and GUI support

Use this script to troubleshoot X11 forwarding issues.

## ⚙️ Configuration

### Environment Variables

Set these before running the container:

```bash
# Path to model and test data (optional)
export VP_DATA_PATH=/path/to/vp_data

# Display for GUI applications
export DISPLAY=:0
```

### CMake Build Options

You can customize the build by setting environment variables in `docker-compose-dev.yml`:

```yaml
environment:
  - VP_WITH_CUDA=ON          # Enable CUDA support
  - VP_WITH_TRT=ON           # Enable TensorRT
  - VP_WITH_PADDLE=ON        # Enable PaddlePaddle
  - VP_WITH_KAFKA=ON         # Enable Kafka support
  - VP_WITH_LLM=ON           # Enable LLM support
  - VP_WITH_FFMPEG=ON        # Enable FFmpeg
  - VP_BUILD_COMPLEX_SAMPLES=ON  # Build complex samples
```

Or pass them when building:

```bash
# Inside container
cd build
cmake -DVP_WITH_CUDA=ON -DVP_WITH_TRT=ON ..
make -j$(nproc)
```

## 🎯 Common Workflows

### Development Workflow

```bash
# 1. Start container in background
docker-compose -f docker-compose-dev.yml up -d

# 2. Enter container
./docker-exec.sh bash

# 3. Build your changes
cd build
cmake ..
make -j$(nproc)

# 4. Run samples
cd bin
./1-1-1_sample
```

### Testing Workflow

```bash
# Rebuild and test
./docker-exec.sh rebuild
./docker-exec.sh test
```

### GPU-Enabled Build

```bash
# Enter container
./docker-run.sh

# Build with CUDA and TensorRT
cd build
cmake -DVP_WITH_CUDA=ON -DVP_WITH_TRT=ON ..
make -j$(nproc)
```

## 🐛 Troubleshooting

### GPU Not Detected

```bash
# Check NVIDIA Docker runtime
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# If fails, install nvidia-docker2
sudo apt-get install nvidia-docker2
sudo systemctl restart docker
```

### Display Issues (GUI)

#### On macOS (Docker Desktop):

**Common Error:**
```
Can't initialize GTK backend in function 'cvInitSystem'
```

**Quick Solution:**

1. Enable XQuartz TCP (one-time setup):
   ```bash
   defaults write org.xquartz.X11 nolisten_tcp 0
   pkill Xquartz && sleep 2 && open -a XQuartz
   ```

2. Run the container:
   ```bash
   ./docker-run.sh
   ```

3. Test X11 forwarding:
   ```bash
   ./docker-test-x11.sh
   ```

**Note:** The docker-run.sh script automatically uses `host.docker.internal:0` for X11 forwarding on macOS, which is the recommended method for Docker Desktop.

#### On Linux:

```bash
# Allow X11 connections
xhost +local:docker

# Run with display
DISPLAY=:0 ./docker-run.sh
```

**Verification:**

1. Check XQuartz is listening:
   ```bash
   lsof -i -P | grep LISTEN | grep 6000
   ```

2. Check container DISPLAY:
   ```bash
   docker exec videopipe2_dev echo $DISPLAY
   # macOS should output: host.docker.internal:0
   ```

3. Run test sample:
   ```bash
   ./docker-exec.sh run 1-1-1_sample
   ```

### Permission Issues

```bash
# Fix permissions on scripts
chmod +x docker-*.sh

# Fix build directory permissions
sudo chown -R $USER:$USER build/
```

### Container Already Exists

```bash
# Stop and remove existing container
docker stop videopipe2_dev
docker rm videopipe2_dev

# Or use docker-compose
docker-compose -f docker-compose-dev.yml down
```

## 📊 Resource Usage

Expected resource requirements:
- **Disk Space**: ~8-10 GB for image + build artifacts
- **RAM**: 4GB minimum, 8GB recommended
- **Build Time**: 20-40 minutes (depends on CPU)

## 🔍 Verification

After building, verify the installation:

```bash
# Enter container
./docker-run.sh

# Check OpenCV
python3 -c "import cv2; print(cv2.__version__)"

# Check GStreamer
gst-inspect-1.0 --version

# List build artifacts
ls -la build/libs
ls -la build/bin
```

## 📝 Notes

1. The project directory is mounted as a volume, so changes made on the host are immediately visible in the container and vice versa.

2. Build artifacts are stored in a Docker volume (`videopipe2_build`) for persistence across container restarts.

3. For production deployment, consider creating a separate Dockerfile that only includes the compiled binaries.

4. The Dockerfile includes CUDA 11.8 support. Adjust the base image if you need a different CUDA version.

## 🤝 Contributing

When adding new dependencies:
1. Update the `Dockerfile`
2. Test the build process
3. Update this README with any new instructions

## 📚 Additional Resources

- [VideoPipe2 Main README](./README.md)
- [Sample Code](./samples/)
- [Node Documentation](./nodes/README.md)
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Docker Guide](https://github.com/NVIDIA/nvidia-docker)
