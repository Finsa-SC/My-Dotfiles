hl.on("hyprland.start", function()
    hl.window_rule({
        match = { title = "^(Picture-in-Picture)$" },
        float = true,
        pin = true,
        size = "400 225",
        opaque = true,
    })
end)
