#!/bin/bash
MAX_PLAYERS=$MAX_PLAYERS
Slots=$MAX_PLAYERS


if [ "$PLATFORM" = "windows" ]; then
  echo "Running via wine64 (windows platform) with max players $MAX_PLAYERS"
  wine64 ./samp-server.exe
else
  echo "Running via native (linux platform) with max players $Slots"
  ./samp03svr
fi
