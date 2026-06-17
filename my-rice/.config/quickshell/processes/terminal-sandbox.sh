#!/bin/bash
exec kitty --detach --title="Sandbox" -- podman run --rm -it \
  --volume "$HOME:/home/$USER/real:ro" \
  --volume "$HOME/.config/fish-sandbox/fish/config.fish:/root/.config/fish/config.fish:ro" \
  --volume "$HOME/.config/fish-sandbox/ascii.txt:/root/.config/fish-sandbox/ascii.txt:ro" \
  localhost/kali-fish \
  fish