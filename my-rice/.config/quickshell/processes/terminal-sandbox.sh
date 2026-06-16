#!/bin/bash
exec kitty --detach --title="Sandbox" -- podman run --rm -it \
  --volume "$HOME:/home/silence-suzuka/real:ro" \
  --volume "$HOME/Project/dotfiles/my-rice/.config/fish-sandbox/fish/config.fish:/root/.config/fish/config.fish:ro" \
  --volume "$HOME/Project/dotfiles/my-rice/.config/fish-sandbox/ascii.txt:/root/.config/fish-sandbox/ascii.txt:ro" \
  --volume "/usr/bin:/usr/bin/host:ro" \
  localhost/kali-fish \
  fish
