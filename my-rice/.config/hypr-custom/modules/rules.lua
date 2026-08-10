hl.on("hyprland.start", function()
    hl.window_rule({
        match = { title = "^(Picture-in-Picture)$" },
        float = true,
        pin = true,
        size = "400 225",
        opaque = true,
    })

    -- Floating windows: reduced rounding
    hl.window_rule({
        match = { float = true },
        rounding = 5,
        border_size = 1,
    })

    -- Pinned windows: reduced rounding
    hl.window_rule({
        match = { pin = true },
        rounding = 5,
        border_size = 1,
    })
end)
