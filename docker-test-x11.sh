#!/bin/bash

# X11 Test Script for VideoPipe2 Docker Container
# This script helps verify that X11 forwarding is working correctly

set -e

echo "================================================"
echo "X11 Forwarding Test"
echo "================================================"

CONTAINER_NAME="videopipe2_dev"

# Check if container is running
if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "❌ Error: Container ${CONTAINER_NAME} is not running."
    echo "Please start it first with: ./docker-run.sh"
    exit 1
fi

echo "✓ Container is running"

# Test 1: Check DISPLAY environment variable
echo ""
echo "Test 1: Checking DISPLAY environment..."
DISPLAY_VALUE=$(docker exec ${CONTAINER_NAME} sh -c 'echo $DISPLAY')
if [ -n "$DISPLAY_VALUE" ]; then
    echo "✓ DISPLAY is set to: $DISPLAY_VALUE"
else
    echo "❌ DISPLAY is not set in container"
    exit 1
fi

# Test 2: Check X11 socket
echo ""
echo "Test 2: Checking X11 socket..."
SOCKET_EXISTS=$(docker exec ${CONTAINER_NAME} sh -c 'ls /tmp/.X11-unix/X0 2>/dev/null && echo "exists" || echo "not found"')
if [ "$SOCKET_EXISTS" = "exists" ]; then
    echo "✓ X11 socket exists in container"
else
    echo "⚠ X11 socket not found at /tmp/.X11-unix/X0"
    echo "This is expected on macOS; will use TCP connection"
fi

# Test 3: Check XAUTHORITY
echo ""
echo "Test 3: Checking XAUTHORITY..."
XAUTH_EXISTS=$(docker exec ${CONTAINER_NAME} sh -c 'ls $XAUTHORITY 2>/dev/null && echo "exists" || echo "not found"')
if [ "$XAUTH_EXISTS" = "exists" ]; then
    echo "✓ XAUTHORITY file is mounted"
else
    echo "⚠ XAUTHORITY file not found"
fi

# Test 4: Check if xeyes is available
echo ""
echo "Test 4: Testing xeyes (if available)..."
if docker exec ${CONTAINER_NAME} which xeyes > /dev/null 2>&1; then
    echo "xeyes is available. Running test..."
    echo "If a window appears with moving eyes, X11 forwarding is working!"
    echo "Press Ctrl+C to stop xeyes"
    docker exec ${CONTAINER_NAME} timeout 5 xeyes || echo "xeyes test completed or timed out"
else
    echo "⚠ xeyes not installed in container"
fi

# Test 5: Check OpenCV
echo ""
echo "Test 5: Checking OpenCV..."
OPENCV_VERSION=$(docker exec ${CONTAINER_NAME} python3 -c "import cv2; print(cv2.__version__)" 2>/dev/null || echo "not available")
if [ "$OPENCV_VERSION" != "not available" ]; then
    echo "✓ OpenCV version: $OPENCV_VERSION"
else
    echo "⚠ OpenCV not available"
fi

# Test 6: Try a simple OpenCV test
echo ""
echo "Test 6: Creating a simple OpenCV test..."
docker exec ${CONTAINER_NAME} sh -c 'cat > /tmp/test_opencv.py << EOF
import cv2
import numpy as np
import time

# Create a simple image
img = np.zeros((100, 100, 3), dtype=np.uint8)
img[:] = (255, 0, 0)  # Blue image

# Try to display it
print("Trying to display image...")
print("If a window appears, X11 forwarding is working!")
cv2.imshow("Test", img)
cv2.waitKey(1000)
cv2.destroyAllWindows()
print("Test completed")
EOF
python3 /tmp/test_opencv.py' 2>&1 || echo "OpenCV display test failed (expected if X11 not working)"

echo ""
echo "================================================"
echo "Test Complete"
echo "================================================"
echo ""
echo "Summary:"
echo "  - Container is running: ✓"
echo "  - DISPLAY environment: $([ -n "$DISPLAY_VALUE" ] && echo "✓" || echo "❌")"
echo "  - X11 socket: $([ "$SOCKET_EXISTS" = "exists" ] && echo "✓" || echo "⚠ using TCP")"
echo ""
echo "If you still see GTK errors when running samples:"
echo "  1. Ensure XQuartz is running: open -a XQuartz"
echo "  2. Run X11 setup: ./docker-setup-x11.sh"
echo "  3. Restart the container"
echo ""
