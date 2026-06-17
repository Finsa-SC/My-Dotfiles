#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../../.." && pwd)"

exec kitty --detach --title="Sandbox" -- podman run --rm -it \
  --volume "$HOME:/home/$USER/real:ro" \
  --volume "$DOTFILES/my-rice/.config/fish-sandbox/fish/config.fish:/root/.config/fish/config.fish:ro" \
  --volume "$DOTFILES/my-rice/.config/fish-sandbox/ascii.txt:/root/.config/fish-sandbox/ascii.txt:ro" \
  localhost/kali-fish \
  fish