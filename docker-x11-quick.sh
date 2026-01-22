#!/bin/bash

# VideoPipe2 X11 Quick Setup for macOS
# Simplified script to enable X11 forwarding for Docker containers

set -e

echo "================================================"
echo "VideoPipe2 X11 Quick Setup (macOS)"
echo "================================================"

# Check if XQuartz is running
if ! pgrep -x "Xquartz" > /dev/null && ! pgrep -x "X11" > /dev/null; then
    echo "Starting XQuartz..."
    open -a XQuartz
    sleep 3
fi

echo "✓ XQuartz is running"

# Stop existing socat processes
pkill -f "socat TCP-LISTEN:6000" 2>/dev/null || true

# Set DISPLAY
export DISPLAY=:0

# Enable X11 access using xhost
echo ""
echo "Configuring X11 access..."
if [ -x "/opt/X11/bin/xhost" ]; then
    /opt/X11/bin/xhost +localhost 2>&1 || {
        echo "⚠ xhost failed. Please manually allow connections in XQuartz settings:"
        echo "  XQuartz → Settings → Security → 'Allow connections from network clients'"
    }
else
    echo "⚠ xhost not found at /opt/X11/bin/xhost"
fi

# Try to find XQuartz socket
echo ""
echo "Looking for XQuartz socket..."
X11_SOCKET="/tmp/.X11-unix/X0"

if [ ! -S "$X11_SOCKET" ]; then
    echo "⚠ Unix socket not found at $X11_SOCKET"
    echo "XQuartz is likely configured to use TCP only"
    echo ""
    echo "Checking TCP connection on port 6000..."
    if lsof -i -P | grep -q "LISTEN.*:6000"; then
        echo "✓ XQuartz is listening on TCP port 6000"
        echo ""
        echo "Using TCP connection - no socat needed"
        echo "Docker will connect directly to host's X server via network"
    else
        echo "❌ XQuartz is not listening on port 6000"
        echo ""
        echo "Please enable TCP connections:"
        echo "  1. Quit XQuartz"
        echo "  2. Run: defaults write org.xquartz.X11 nolisten_tcp 0"
        echo "  3. Start XQuartz: open -a XQuartz"
        exit 1
    fi
else
    echo "✓ Unix socket found at $X11_SOCKET"
fi

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Environment variables set:"
echo "  DISPLAY=$DISPLAY"
echo ""
echo "You can now use Docker with X11 forwarding."
echo ""
echo "Note: Docker is using host network mode, so it can"
echo "connect to XQuartz via localhost:6000"
echo ""
