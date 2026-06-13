hl.on("hyprland.start", function()
    -- Rule dasar yang pakai tabel (untuk float, pin, size)
    hl.window_rule({
        match = { title = "^(Picture-in-Picture)$" },
        float = true,
        pin = true,
        size = "400 225"
    })

    -- Tembak rule dekorasi langsung pakai dispatcher mentah
    -- Menggunakan syntax asli Hyprland: windowrulev2 = rule, kriteria
    hl.dispatch("windowrulev2", "opaque, title:^(Picture-in-Picture)$")
    hl.dispatch("windowrulev2", "alphaoverride 1.0 1.0, title:^(Picture-in-Picture)$")
    hl.dispatch("windowrulev2", "noblur, title:^(Picture-in-Picture)$")
end)
