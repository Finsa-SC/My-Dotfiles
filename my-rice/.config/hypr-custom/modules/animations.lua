-- Curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Animations
hl.animation({ leaf = "global",          enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "windows",         enabled = true, speed = 4,    bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",       enabled = true, speed = 4,    bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",      enabled = true, speed = 2,    bezier = "quick",        style = "popin 87%" })
hl.animation({ leaf = "fade",            enabled = true, speed = 3,    bezier = "quick" })
hl.animation({ leaf = "layers",          enabled = true, speed = 3,    bezier = "easeOutQuint" })