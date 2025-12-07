#!/bin/bash
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x24 &>/dev/null &
XVFB_PID=$!
sleep 2

for f in docs/diagrams/*.drawio; do
  drawio --no-sandbox -x -f svg --crop -o "${f%.drawio}.svg" "$f" 2>/dev/null
done

kill $XVFB_PID 2>/dev/null
