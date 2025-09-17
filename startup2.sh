#!/bin/bash

# SA-MP Smart Startup Script with Auto Platform Detection
# Auto-detects platform from Docker image and server.cfg

export MAX_PLAYERS=$MAX_PLAYERS
export Slots=$MAX_PLAYERS

echo "============================================"
echo "SA-MP Smart Startup - Auto Platform Detect"
echo "============================================"

# Function to detect platform from Docker image
detect_platform_from_docker() {
    if [[ "$SERVER_IMAGE" == *"wine"* ]] || [[ "$SERVER_IMAGE" == *"windows"* ]]; then
        echo "windows"
    elif [[ "$SERVER_IMAGE" == *"samp"* ]] || [[ "$SERVER_IMAGE" == *"linux"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Function to detect platform from server.cfg plugins
detect_platform_from_plugins() {
    if [ -f "server.cfg" ]; then
        if grep -q "^plugins " server.cfg; then
            PLUGINS_LINE=$(grep "^plugins " server.cfg)
            echo "Found plugins: $PLUGINS_LINE"
            
            # Check if any .so extension exists
            if echo "$PLUGINS_LINE" | grep -q "\.so"; then
                echo "linux"
            else
                echo "windows"
            fi
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Function to detect platform from available executables
detect_platform_from_executable() {
    if [ -f "samp03svr" ] && [ -f "samp-server.exe" ]; then
        echo "both"
    elif [ -f "samp03svr" ]; then
        echo "linux"
    elif [ -f "samp-server.exe" ]; then
        echo "windows"
    else
        echo "none"
    fi
}

# Primary detection: Docker image
DOCKER_PLATFORM=$(detect_platform_from_docker)
echo "Docker detection: $DOCKER_PLATFORM"

# Secondary detection: server.cfg plugins
PLUGINS_PLATFORM=$(detect_platform_from_plugins)
echo "Plugins detection: $PLUGINS_PLATFORM"

# Tertiary detection: Available executables
EXEC_PLATFORM=$(detect_platform_from_executable)
echo "Executable detection: $EXEC_PLATFORM"

# Smart platform selection logic
FINAL_PLATFORM="unknown"

if [ "$DOCKER_PLATFORM" != "unknown" ]; then
    # Docker image detection is most reliable
    FINAL_PLATFORM="$DOCKER_PLATFORM"
    echo "Using Docker-based detection: $FINAL_PLATFORM"
elif [ "$PLUGINS_PLATFORM" != "unknown" ]; then
    # Plugin detection as fallback
    FINAL_PLATFORM="$PLUGINS_PLATFORM"
    echo "Using plugins-based detection: $FINAL_PLATFORM"
elif [ "$EXEC_PLATFORM" = "both" ]; then
    # Both executables exist, default to windows (more common)
    FINAL_PLATFORM="windows"
    echo "Both executables found, defaulting to: $FINAL_PLATFORM"
elif [ "$EXEC_PLATFORM" != "none" ] && [ "$EXEC_PLATFORM" != "unknown" ]; then
    # Use available executable
    FINAL_PLATFORM="$EXEC_PLATFORM"
    echo "Using executable-based detection: $FINAL_PLATFORM"
else
    # Last resort: check for wine/xvfb availability
    if command -v wine64 &> /dev/null; then
        FINAL_PLATFORM="windows"
        echo "Wine64 detected, defaulting to: $FINAL_PLATFORM"
    else
        FINAL_PLATFORM="linux"
        echo "No wine64 detected, defaulting to: $FINAL_PLATFORM"
    fi
fi

echo "============================================"
echo "Final Platform Decision: $FINAL_PLATFORM"
echo "Max Players: $MAX_PLAYERS"
echo "============================================"

# Execute based on detected platform
if [ "$FINAL_PLATFORM" = "windows" ]; then
    echo "🍷 Starting SA-MP via Wine64 (Windows Platform)"
    echo "Max Players: $MAX_PLAYERS"
    
    # Setup Wine environment
    export WINEDEBUG=-all
    export DISPLAY=:99
    
    # Start Xvfb if not running
    if ! pgrep -x "Xvfb" > /dev/null; then
        echo "Starting Xvfb virtual display..."
        Xvfb :99 -screen 0 1024x768x16 &
        XVFB_PID=$!
        echo "Xvfb started with PID: $XVFB_PID"
    fi
    
    # Cleanup function
    cleanup() {
        echo "Shutting down SA-MP server..."
        if [ ! -z "$XVFB_PID" ]; then
            kill $XVFB_PID 2>/dev/null || true
            echo "Xvfb stopped"
        fi
        exit
    }
    
    # Set trap for cleanup
    trap cleanup EXIT INT TERM
    
    # Check for Windows executable
    if [ -f "samp-server.exe" ]; then
        echo "Found samp-server.exe, starting server..."
        wine64 ./samp-server.exe 2>&1 | tee samp.log
    else
        echo "❌ Error: samp-server.exe not found!"
        echo "Available files:"
        ls -la *.exe 2>/dev/null || echo "No .exe files found"
        exit 1
    fi
    
elif [ "$FINAL_PLATFORM" = "linux" ]; then
    echo "🐧 Starting SA-MP via Native Linux"
    echo "Max Players: $Slots"
    
    # Check for Linux executable
    if [ -f "samp03svr" ]; then
        echo "Found samp03svr, starting server..."
        chmod +x samp03svr
        exec ./samp03svr
    else
        echo "❌ Error: samp03svr not found!"
        echo "Available files:"
        ls -la samp* 2>/dev/null || echo "No samp files found"
        exit 1
    fi
    
else
    echo "❌ Error: Unable to determine platform!"
    echo "Docker: $DOCKER_PLATFORM"
    echo "Plugins: $PLUGINS_PLATFORM" 
    echo "Executable: $EXEC_PLATFORM"
    echo "Available files:"
    ls -la
    exit 1
fi
