hl.on("hyprland.start", function()
  hl.dispatch(hl.dsp.focus({ workspace = wsStart }))
  -- autostart lainnya di sini
  hl.exec_cmd("waybar")
  hl.exec_cmd("mako")
  hl.exec_cmd("sh -c 'swaybg -i \"$(cat $HOME/.cache/current-wallpaper)\" -m fill &'")
end)
