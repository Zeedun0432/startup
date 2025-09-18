#!/bin/bash

set -e

echo "======================================="
echo "SA-MP Kodo Hybrid Auto-Detect Startup"
echo "======================================="

cd /mnt/server || exit 1

DETECTED_OS="windows"  # Default to Windows
PLATFORM_DETECTED=false

echo "Checking for server.cfg..."
if [ -f "server.cfg" ]; then
    echo "Found server.cfg, analyzing plugins for OS detection..."
    
    # Check if plugins line exists
    if grep -q "^plugins " server.cfg; then
        PLUGINS_LINE=$(grep "^plugins " server.cfg)
        echo "Found plugins line: $PLUGINS_LINE"
        
        # Check if any .so extension exists in plugins line
        if echo "$PLUGINS_LINE" | grep -q "\.so"; then
            DETECTED_OS="linux"
            PLATFORM_DETECTED=true
            echo "✅ Detected OS: Linux (found .so plugins)"
        else
            DETECTED_OS="windows"
            PLATFORM_DETECTED=true
            echo "✅ Detected OS: Windows (no .so plugins found)"
        fi
    else
        echo "⚠️  No plugins line found in server.cfg"
        echo "   Defaulting to Windows (most common)"
        DETECTED_OS="windows"
    fi
else
    echo "⚠️  No server.cfg found"
    echo "   Defaulting to Windows (most common)"
    DETECTED_OS="windows"
fi

echo ""
echo "🔍 Detection Summary:"
echo "   - OS Detected: ${DETECTED_OS^^}"
echo "   - Platform Auto-Detected: $PLATFORM_DETECTED"
echo ""

# Start server based on detected OS
case "${DETECTED_OS}" in
    "linux")
        echo "🐧 Starting SA-MP Linux Server..."
        
        # Find Linux executable
        if [ -f "samp03svr" ]; then
            EXECUTABLE="samp03svr"
        elif [ -f "samp-server" ]; then
            EXECUTABLE="samp-server"
        else
            echo "❌ Error: SA-MP Linux executable not found!"
            echo "   Expected files: samp03svr or samp-server"
            exit 1
        fi
        
        echo "   Executable: ${EXECUTABLE}"
        chmod +x "${EXECUTABLE}"
        
        # Start Linux server
        echo "🚀 Launching Linux SA-MP Server..."
        exec "./${EXECUTABLE}"
        ;;
        
    "windows")
        echo "🪟 Starting SA-MP Windows Server..."
        
        # Find Windows executable
        if [ -f "samp-server.exe" ]; then
            EXECUTABLE="samp-server.exe"
        elif [ -f "samp03svr.exe" ]; then
            EXECUTABLE="samp03svr.exe"
        else
            echo "❌ Error: SA-MP Windows executable not found!"
            echo "   Expected files: samp-server.exe or samp03svr.exe"
            exit 1
        fi
        
        echo "   Executable: ${EXECUTABLE}"
        
        # Check if we're in a Wine container or need to use wine
        if command -v wine >/dev/null 2>&1; then
            echo "🍷 Using Wine to run Windows executable..."
            
            # Set up virtual display for wine if needed
            export DISPLAY=:99
            if command -v Xvfb >/dev/null 2>&1; then
                echo "   Starting virtual display..."
                Xvfb :99 -screen 0 1024x768x16 &
                XVFB_PID=$!
                sleep 2
            fi
            
            # Start Windows server with Wine
            echo "🚀 Launching Windows SA-MP Server with Wine..."
            exec wine "${EXECUTABLE}"
        else
            echo "❌ Error: Wine not found!"
            echo "   Windows executable detected but Wine is not available."
            echo "   Please use a Wine-enabled Docker image or install Wine."
            exit 1
        fi
        ;;
        
    *)
        echo "❌ Error: Unsupported OS detection result: ${DETECTED_OS}"
        exit 1
        ;;
esac
