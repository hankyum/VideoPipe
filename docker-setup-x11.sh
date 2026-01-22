#!/bin/bash

# VideoPipe2 X11 Setup Script for macOS
# This script helps configure X11 forwarding for GUI applications in Docker containers

set -e

echo "================================================"
echo "VideoPipe2 X11 Setup for macOS"
echo "================================================"

# Check OS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script is designed for macOS only."
    echo "For Linux, use: xhost +local:docker"
    exit 1
fi

# Check if XQuartz is installed
if ! command -v xquartz &> /dev/null && ! [ -d /Applications/Utilities/XQuartz.app ]; then
    echo ""
    echo "❌ Error: XQuartz is not installed."
    echo ""
    echo "Please install XQuartz first:"
    echo "  brew install --cask xquartz"
    echo ""
    echo "After installation, restart your terminal and run this script again."
    exit 1
fi

echo "✓ XQuartz found"

# Check if socat is installed (for forwarding X11 socket on macOS)
if ! command -v socat &> /dev/null; then
    echo ""
    echo "⚠ socat is not installed. Installing..."
    brew install socat
fi

echo "✓ socat found"

# Stop existing socat processes
echo ""
echo "Stopping existing socat processes..."
pkill -f "socat TCP-LISTEN:6000" 2>/dev/null || true

# Set DISPLAY
export DISPLAY=:0
echo "✓ DISPLAY set to: $DISPLAY"

# Check if XQuartz is running
if ! pgrep -x "X11" > /dev/null && ! pgrep -x "Xquartz" > /dev/null; then
    echo ""
    echo "⚠ XQuartz is not running. Starting XQuartz..."
    open -a XQuartz
    echo "Waiting for XQuartz to start..."
    sleep 5
fi

# Wait for XQuartz to be ready
echo "Waiting for X server to be ready..."
for i in {1..10}; do
    if /opt/X11/bin/xhost info &>/dev/null; then
        echo "✓ X server is ready"
        break
    fi
    echo "Waiting... ($i/10)"
    sleep 1
done

# Allow connections from localhost using xauth
echo ""
echo "Configuring X11 access..."
if [ -f "$HOME/.Xauthority" ]; then
    # Allow local connections using xauth
    if command -v xauth &> /dev/null; then
        xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $HOME/.Xauthority nmerge - 2>/dev/null || true
    fi
fi

# Try xhost first, but don't fail if it doesn't work
if [ -x "/opt/X11/bin/xhost" ]; then
    /opt/X11/bin/xhost +localhost 2>/dev/null && echo "✓ Xhost permissions set" || echo "⚠ xhost not available (will use TCP)"
fi

# Create X11 socket directory if it doesn't exist
echo ""
echo "Setting up X11 socket..."
sudo mkdir -p /tmp/.X11-unix 2>/dev/null || true
sudo chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# Start socat for X11 socket forwarding
echo "Starting socat for X11 socket forwarding..."
SOCKET_FILE="/tmp/.X11-unix/X0"

# Remove existing socket if any
sudo rm -f "$SOCKET_FILE" 2>/dev/null || true

# Start socat in background
nohup socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:"/tmp/.X11-unix/X0" > /tmp/socat.log 2>&1 &
SOCAT_PID=$!

# Wait a bit for socat to start
sleep 2

if ps -p $SOCAT_PID > /dev/null; then
    echo "✓ socat started (PID: $SOCAT_PID)"
    echo $SOCAT_PID > /tmp/videopipe2_socat.pid
else
    echo "⚠ socat may have failed. Check /tmp/socat.log for details."
fi

echo ""
echo "================================================"
echo "X11 Setup Complete!"
echo "================================================"
echo ""
echo "You can now run Docker containers with GUI support:"
echo "  ./docker-run.sh"
echo "  or"
echo "  docker-compose up -d"
echo ""
echo "Troubleshooting tips:"
echo "  1. If you still have display issues, open XQuartz Preferences → Security"
echo "  2. Check 'Allow connections from network clients'"
echo "  3. Restart XQuartz and run this script again"
echo "  4. Check socat log: tail -f /tmp/socat.log"
echo ""
