#!/bin/bash
export MAX_PLAYERS=$MAX_PLAYERS
export Slots=$MAX_PLAYERS

echo "=== DEBUG INFO ==="
echo "PLATFORM: $PLATFORM"
echo "PWD: $(pwd)"
echo "FILES: $(ls -la)"
echo "WINE VERSION: $(wine64 --version 2>&1)"
echo "==================="

if [ "$PLATFORM" = "windows" ]; then
  echo "Running via wine64 (windows platform) with max players $MAX_PLAYERS"
  # Force output to stdout/stderr
  exec wine64 ./samp-server.exe 2>&1
else
  echo "Running via native (linux platform) with max players $Slots"
  exec ./samp03svr 2>&1
fi
