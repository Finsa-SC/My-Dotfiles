-- Workspace navigation function
local function goWorkspace(dir)
    if dir == "up" or dir == "down" then
        hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slidevert" })
        hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slidevert" })
        hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slidevert" })
    else
        hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slide" })
        hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slide" })
        hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slide" })
    end

    local cur = hl.get_active_workspace().id
    local col = (cur - 1) % wsGrid.cols + 1
    local row = math.floor((cur - 1) / wsGrid.cols) + 1
    local next = nil

    if dir == "right" and col < wsGrid.cols then next = cur + 1
    elseif dir == "left" and col > 1 then next = cur - 1
    elseif dir == "down" and row < wsGrid.rows then next = cur + wsGrid.cols
    elseif dir == "up" and row > 1 then next = cur - wsGrid.cols
    end

    if next then hl.dispatch(hl.dsp.focus({ workspace = next })) end
end

-- Application
hl.bind(kbTerminal, hl.dsp.exec_cmd(terminal))
hl.bind(kbBrowser, hl.dsp.exec_cmd(browser))
hl.bind(kbSecondBrowser, hl.dsp.exec_cmd(secondBrowser))
hl.bind(kbEditor, hl.dsp.exec_cmd(editor))
hl.bind(kbFileManager, hl.dsp.exec_cmd(fileManager))
hl.bind(kbSystemMonitor, hl.dsp.exec_cmd(terminal .. " --title 'System Monitor' -e " .. systemMonitor))

-- Window Action
hl.bind(kbCloseWindow,  hl.dsp.window.close())
hl.bind(kbToggleFloat,  hl.dsp.window.float({ action = "toggle" }))
hl.bind(kbFullScreen,   hl.dsp.window.fullscreen())
hl.bind(kbBorderedFullScreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(kbPinWindow,    hl.dsp.window.pin())

-- Mouse window controls
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Directional navigation
for _, d in ipairs(dirs) do
  hl.bind(mainMod .. " + " .. d.key,
    hl.dsp.focus({ direction = d.dir }))
  hl.bind(mainMod .. " + SHIFT + " .. d.key,
    hl.dsp.window.move({ direction = d.dir }))
end

-- Resize
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 20,  y = 0, relative = true }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.resize({ x = 0,   y = -20, relative = true }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }))

-- Workspace 2D navigation (5x5 grid)
hl.bind(mainMod .. " + CTRL + right", function() goWorkspace("right") end, { repeating = false })
hl.bind(mainMod .. " + CTRL + left",  function() goWorkspace("left")  end, { repeating = false })
hl.bind(mainMod .. " + CTRL + down",  function() goWorkspace("down")  end, { repeating = false })
hl.bind(mainMod .. " + CTRL + up",    function() goWorkspace("up")    end, { repeating = false })

-- Move window 2D
local function moveToWorkspace(dir)
    local cur = hl.get_active_workspace().id
    local col = (cur - 1) % wsGrid.cols + 1
    local row = math.floor((cur - 1) / wsGrid.cols) + 1
    local next = nil

    if dir == "right" and col < wsGrid.cols then next = cur + 1
    elseif dir == "left" and col > 1 then next = cur - 1
    elseif dir == "down" and row < wsGrid.rows then next = cur + wsGrid.cols
    elseif dir == "up" and row > 1 then next = cur - wsGrid.cols
    end

    if next then hl.dispatch(hl.dsp.window.move({ workspace = next })) end
end

hl.bind(mainMod .. " + CTRL + SHIFT + right", function() moveToWorkspace("right") end, { repeating = false })
hl.bind(mainMod .. " + CTRL + SHIFT + left",  function() moveToWorkspace("left")  end, { repeating = false })
hl.bind(mainMod .. " + CTRL + SHIFT + down",  function() moveToWorkspace("down")  end, { repeating = false })
hl.bind(mainMod .. " + CTRL + SHIFT + up",    function() moveToWorkspace("up")    end, { repeating = false })

-- Workspace by number
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Volume control
hl.bind(kbVolumeUp,   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { repeating = true, locked = true })
hl.bind(kbVolumeDown, hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { repeating = true, locked = true })
hl.bind(kbVolumeMute, hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { repeating = false, locked = true })

-- Brightness Controls
hl.bind(kbBrightUp,   hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
hl.bind(kbBrightDown, hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })

-- Utilities
hl.bind(kbScreenshot, hl.dsp.exec_cmd(
    "wayfreeze & sleep 0.1 && grim -g \"$(slurp)\" - | wl-copy && pkill wayfreeze && notify-send 'Screenshot' 'Image copied to clipboard' -a 'Clipboard'"
))
hl.bind(kbSaveScreenshot, hl.dsp.exec_cmd(
    "wayfreeze & sleep 0.1 &&" ..
    "mkdir -p ~/Pictures/Screenshots && " ..
    "FILE=~/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png && " ..
    "grim -g \"$(slurp)\" \"$FILE\" && " ..
    "pkill wayfreeze &&" ..
    "notify-send 'Screenshot Saved' \"$FILE\" -a ''"
))
hl.bind(kbCopiedHistory, hl.dsp.exec_cmd(
    "qs ipc -p " .. os.getenv("HOME") .. "/.config/quickshell call clipboard toggle"
), { repeating = false })
hl.bind(kbLockScreen, hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/lock.sh"))

-- Readonly mode
local noop = function() end
local blockedKeys = {
    "a","b","c","d","e","f","g","h","i","j","k","l","m",
    "n","o","p","q","r","s","t","u","v","w","x","y","z",
    "0","1","2","3","4","5","6","7","8","9",
    "space","Return","BackSpace","Delete","Tab",
    "minus","equal","bracketleft","bracketright","backslash",
    "semicolon","apostrophe","comma","period","slash","grave",
}
local modifiers = { "", "SHIFT + ", "CTRL + ", "CTRL + SHIFT + ", "ALT + ", "ALT + SHIFT + " }

hl.bind(mainMod .. " + R", function()
    hl.dispatch(hl.dsp.exec_cmd(
        "notify-send 'Keyboard Locked' 'Read-Only Mode Enabled' -a 'System'"
    ))
    hl.dispatch(hl.dsp.submap("readonly"))
end, { repeating = false })

hl.define_submap("readonly", function()
    -- exit + notif
    hl.bind(mainMod .. " + SHIFT + R", function()
        hl.dispatch(hl.dsp.exec_cmd(
            "notify-send 'Keyboard Released' 'Exit from readonly mode' -a 'System'"
        ))
        hl.dispatch(hl.dsp.submap("reset"))
    end)

    -- navigasi fokus window
    hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
    hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
    hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
    hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

    -- navigasi workspace 2D
    hl.bind(mainMod .. " + CTRL + right", function() goWorkspace("right") end, { repeating = false })
    hl.bind(mainMod .. " + CTRL + left",  function() goWorkspace("left")  end, { repeating = false })
    hl.bind(mainMod .. " + CTRL + down",  function() goWorkspace("down")  end, { repeating = false })
    hl.bind(mainMod .. " + CTRL + up",    function() goWorkspace("up")    end, { repeating = false })

    -- tangkap semua kombinasi modifier + key supaya gak nembus ke app
    for _, mod in ipairs(modifiers) do
        for _, key in ipairs(blockedKeys) do
            hl.bind(mod .. key, noop)
        end
    end
end)

-- Quickshell
hl.bind(kbChangeWallpaper, hl.dsp.exec_cmd("qs ipc -p " .. os.getenv("HOME") .. "/.config/quickshell call wallpaper toggle"), { repeating = false })
hl.bind(kbLauncher, hl.dsp.exec_cmd("qs ipc -p " .. os.getenv("HOME") .. "/.config/quickshell call drawer toggle"), { repeating = false })

-- Security
hl.bind(kbSandboxTerminal, hl.dsp.exec_cmd("kitty --title='Sandbox' $HOME/.config/quickshell/processes/terminal-sandbox.sh"))
