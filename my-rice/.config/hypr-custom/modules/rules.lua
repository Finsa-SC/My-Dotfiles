hl.on("hyprland.start", function()
    hl.window_rule({
        match = { title = "^(Picture-in-Picture)$" },
        float = true,
        pin = true,
        size = "400 225" -- Jika pakai spasi aman di dispatch dasar, silakan dipertahankan
    })

    hl.dispatch("windowrulev2", "opaque, title:^(Picture-in-Picture)$")
    hl.dispatch("windowrulev2", "noblur, title:^(Picture-in-Picture)$")
end)
