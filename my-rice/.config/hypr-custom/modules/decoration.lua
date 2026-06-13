hl.config({
    decoration = {
        rounding         = rounding,
        rounding_power   = roundingPower,
        active_opacity   = activeOpacity,
        inactive_opacity = inactiveOpacity,

        shadow = {
            enabled      = shadowEnabled,
            range        = shadowRange,
            render_power = shadowRenderPower,
            color        = shadowColor,
        },

        blur = {
            enabled  = blurEnabled,
            size     = blurSize,
            passes   = blurPasses,
            vibrancy = blurVibrancy,
        },
    },
})
