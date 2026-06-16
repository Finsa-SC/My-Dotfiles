#!/bin/bash
REAL_HOME="$HOME"
exec bwrap \
  --tmpfs / \
  --ro-bind /usr /usr \
  --ro-bind /etc /etc \
  --symlink usr/bin /bin \
  --symlink usr/lib /lib \
  --symlink usr/lib64 /lib64 \
  --dev /dev \
  --proc /proc \
  --tmpfs /tmp \
  --tmpfs /root \
  --tmpfs /home \
  --ro-bind "$REAL_HOME" "/home/silence-suzuka/real" \
  --ro-bind "$REAL_HOME/.config/fish-sandbox" "/home/silence-suzuka/.config/fish-sandbox" \
  --unshare-pid \
  --setenv HOME /home/silence-suzuka \
  --setenv HISTFILE /dev/null \
  --setenv HISTSIZE 0 \
  --setenv HISTFILESIZE 0 \
  --setenv XDG_CONFIG_HOME /home/silence-suzuka/.config/fish-sandbox \
  -- fish
