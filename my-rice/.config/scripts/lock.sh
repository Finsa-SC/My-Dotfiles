#!/usr/bin/env bash
SCREENSHOT_PATH="/tmp/qs-lockscreen-bg.png"
QS_LOCK_DIR="$HOME/.config/qs-lock"

grim -o eDP-1 "$SCREENSHOT_PATH"

killall quickshell
sleep 0.2

quickshell -p "$QS_LOCK_DIR"

quickshell & disown