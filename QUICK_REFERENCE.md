# VideoPipe2 Docker Quick Reference

> **Essential commands for daily use**

---

## Quick Start (macOS + Docker Desktop)

```bash
# First-time setup (run once)
defaults write org.xquartz.X11 nolisten_tcp 0
pkill Xquartz && sleep 2 && open -a XQuartz
export DISPLAY=:0 && /opt/X11/bin/xhost +localhost

# Daily workflow
./docker-run.sh
cd /workspace/VideoPipe2
./build/bin/sample_name
```

---

## Container Commands

### Start/Stop

```bash
# Start container
./docker-run.sh

# Start with docker-compose
docker-compose -f docker-compose-dev.yml up -d

# Stop container
docker stop videopipe2_dev

# Remove container
docker stop videopipe2_dev && docker rm videopipe2_dev

# Restart container
docker restart videopipe2_dev
```

### Enter Container

```bash
# Interactive shell
./docker-exec.sh bash

# Or use docker exec
docker exec -it videopipe2_dev bash
```

---

## Build Commands

### Build Image

```bash
# Build Docker image
./docker-build.sh

# Build with specific tag
./docker-build.sh cuda
```

### Build VideoPipe2 Inside Container

```bash
# Full build
./docker-exec.sh rebuild

# Quick build (if configured)
./docker-exec.sh build

# Build with options
./docker-exec.sh build "-DVP_WITH_CUDA=ON -DVP_WITH_TRT=ON"

# Clean build
./docker-exec.sh clean
```

---

## Sample Execution

### List Samples

```bash
./docker-exec.sh list-samples

# Or from container
ls -la /workspace/VideoPipe2/build/bin/
```

### Run Sample

```bash
# From host
./docker-exec.sh run face_tracking_sample
./docker-exec.sh run 1-1-1_sample
./docker-exec.sh run trt_yolov8_sample

# From inside container
cd /workspace/VideoPipe2
./build/bin/face_tracking_sample
```

### Run with Arguments

```bash
# From host
docker exec -it videopipe2_dev bash -c "cd /workspace/VideoPipe2 && ./build/bin/sample --option value"

# From container
cd /workspace/VideoPipePipe2
./build/bin/sample --option value
```

---

## X11 Setup (macOS)

### One-Time Setup

```bash
# Enable XQuartz TCP
defaults write org.xquartz.X11 nolisten_tcp 0

# Restart XQuartz
pkill Xquartz && sleep 2 && open -a XQuartz

# Allow connections
export DISPLAY=:0
/opt/X11/bin/xhost +localhost
```

### Verify X11

```bash
# Check XQuartz is running
ps aux | grep -i xquartz

# Check XQuartz is listening
lsof -i -P | grep LISTEN | grep 6000

# Test X11 forwarding
./docker-test-x11.sh

# Run simple test
./docker-exec.sh run 1-1-1_sample
```

### Fix X11 Issues

```bash
# If GTK errors appear
pkill Xquartz && sleep 2 && open -a XQuartz

# Reset permissions
export DISPLAY=:0
/opt/X11/bin/xhost +

# Restart container
docker stop videopipe2_dev && docker rm videopipe2_dev
./docker-run.sh
```

---

## GPU Setup (Linux)

### Check GPU

```bash
# From host
nvidia-smi

# From container
docker exec videopipe2_dev nvidia-smi
```

### Enable GPU Support

```bash
# Build with CUDA
./docker-exec.sh build "-DVP_WITH_CUDA=ON -DVP_WITH_TRT=ON"

# Or use docker-compose with env vars
docker-compose -f docker-compose-dev.yml up -d
```

---

## File Locations

### Inside Container

```
/workspace/VideoPipe2/          # Project root
/workspace/VideoPipe2/build/    # Build directory
/workspace/VideoPipe2/build/bin/  # Executables
/workspace/VideoPipe2/build/libs/ # Libraries
/workspace/vp_data/               # Data directory
/workspace/vp_data/test_video/  # Test videos
/workspace/vp_data/models/       # Model files
```

### On Host

```
/Users/fengming/projects/VideoPipe2/  # Project directory
/Users/fengming/.Xauthority           # X11 auth (macOS)
/tmp/.X11-unix/                 # X11 socket (Linux)
```

---

## CMake Build Options

### Basic Options

```bash
cd /workspace/VideoPipe2/build

cmake -DVP_WITH_CUDA=ON \
      -DVP_WITH_TRT=ON \
      -DVP_WITH_PADDLE=ON \
      -DVP_WITH_KAFKA=ON \
      -DVP_WITH_LLM=ON \
      -DVP_WITH_FFMPEG=ON \
      ..
```

### All Options

```bash
# View all available options
cmake -L ..

# Or check CMakeLists.txt
cat /workspace/VideoPipe2/CMakeLists.txt | grep -A 5 "option("
```

---

## Debugging

### Check Logs

```bash
# Container logs
docker logs videopipe2_dev --tail 100

# Follow logs
docker logs -f videopipe2_dev

# Build logs
cat /workspace/VideoPipe2/build/log/*.log
```

### Check Processes

```bash
# Container processes
docker exec videopipe2_dev ps aux

# Check for sample processes
docker exec videopipe2_dev ps aux | grep sample
```

### Network Debug

```bash
# Check network mode
docker inspect videopipe2_dev | grep -A 5 NetworkMode

# Check port bindings
docker port videopipe2_dev

# Check DNS
docker exec videopipe2_dev cat /etc/resolv.conf
```

### X11 Debug

```bash
# Check DISPLAY variable
docker exec videopipe2_dev echo $DISPLAY

# Check XAUTHORITY (Linux)
docker exec videopipe2_dev ls -la /root/.Xauthority

# Test X11 connection
docker exec videopipe2_dev xeyes
```

---

## Common Workflows

### Development Loop

```bash
# 1. Edit code on host
vim /path/to/file.cpp

# 2. Rebuild in container
./docker-exec.sh rebuild

# 3. Test immediately
./docker-exec.sh run sample_name

# 4. Repeat as needed
```

### Testing New Feature

```bash
# 1. Build with options
./docker-exec.sh build "-DNEW_FEATURE=ON"

# 2. Run related samples
./docker-exec.sh list-samples | grep new_feature
./docker-exec.sh run new_feature_sample

# 3. Debug if needed
docker exec -it videopipe2_dev bash
cd /workspace/VideoPipe2/build
gdb ./bin/new_feature_sample
```

### Performance Testing

```bash
# 1. Start container
./docker-run.sh

# 2. Run benchmark
./docker-exec.sh run benchmark_sample

# 3. Monitor resources
docker stats videopipe2_dev

# 4. Check logs
docker logs videopipe2_dev
```

---

## Environment Variables

### Set Before Running

```bash
# Custom data path
export VP_DATA_PATH=/path/to/data

# Custom display (Linux)
export DISPLAY=:1

# Build options
export VP_WITH_CUDA=ON
export VP_WITH_TRT=ON
```

### Check in Container

```bash
# View all environment
docker exec videopipe2_dev env

# View specific variables
docker exec videopipe2_dev bash -c "echo \$CUDA_VISIBLE_DEVICES"
docker exec videopipe2_dev bash -c "echo \$VP_WITH_CUDA"
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check if container exists
docker ps -a | grep videopipe2

# Remove existing container
docker stop videopipe2_dev && docker rm videopipe2_dev

# Check for port conflicts
lsof -i :6000  # macOS/Linux
```

### Build Errors

```bash
# Clean and rebuild
./docker-exec.sh clean
./docker-exec.sh rebuild

# Check CMake version
docker exec videopipe2_dev cmake --version

# Check compiler
docker exec videopipe2_dev gcc --version
```

### Permission Errors

```bash
# Fix permissions on build directory
docker exec videopipe2_dev chown -R root:root /workspace/VideoPipe2/build

# Or rebuild from scratch
./docker-exec.sh rebuild
```

### Out of Memory

```bash
# Increase Docker resources (Docker Desktop → Settings)
# - CPUs: Increase count
# - Memory: Increase allocation
# - Swap: Enable and increase

# Then restart container
docker restart videopipe2_dev
```

---

## Help Resources

- **[Full Environment Guide](./ENVIRONMENT_SETUP.md)** - Detailed setup for all platforms
- **[X11 Quick Start](./X11_QUICKSTART.md)** - X11 forwarding setup
- **[Docker Setup Guide](./DOCKER_README.md)** - Complete Docker documentation
- **[Main README](./README.md)** - Project overview
- **[Samples Documentation](./SAMPLES.md)** - Sample descriptions

---

## Script Index

| Script | Purpose | Location |
|---------|-----------|----------|
| docker-build.sh | Build Docker image | Project root |
| docker-run.sh | Start container | Project root |
| docker-exec.sh | Execute commands | Project root |
| docker-setup-x11.sh | Setup X11 (macOS) | Project root |
| docker-test-x11.sh | Test X11 | Project root |
| docker-x11-quick.sh | Quick X11 setup | Project root |

---

## Quick Commands Summary

```bash
# Essential commands
./docker-run.sh                    # Start container
./docker-exec.sh bash                # Enter container
./docker-exec.sh rebuild              # Rebuild project
./docker-exec.sh list-samples         # List samples
./docker-exec.sh run sample_name       # Run sample
./docker-test-x11.sh                 # Test X11

# X11 commands (macOS)
defaults write org.xquartz.X11 nolisten_tcp 0
pkill Xquartz && open -a XQuartz
export DISPLAY=:0 && /opt/X11/bin/xhost +localhost

# Container management
docker ps -a | grep videopipe2    # Check container
docker logs videopipe2_dev --tail 50  # View logs
docker stop videopipe2_dev            # Stop container
docker restart videopipe2_dev          # Restart container
```

**Tip:** Bookmark this page for quick command reference! 📑
