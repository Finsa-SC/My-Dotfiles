-- Programs
_G.terminal    = "kitty"
_G.browser     = "zen-browser"
_G.fileManager = "dolphin"
_G.editor      = "code"

-- Modifier
_G.mainMod = "SUPER"

-- Gaps & Borders
_G.gapsIn     = 8
_G.gapsOut    = 19
_G.borderSize = 2
_G.rounding   = 15

-- Decoration
_G.activeOpacity     = 0.9
_G.inactiveOpacity   = 0.8
_G.roundingPower     = 2.0

-- Shadow
_G.shadowEnabled     = true
_G.shadowRange       = 4
_G.shadowRenderPower = 3
_G.shadowColor       = 0xee1a1a1a

-- Blur
_G.blurEnabled       = true
_G.blurSize          = 3
_G.blurPasses        = 1
_G.blurVibrancy      = 0.17

-- Directions
_G.dirs = {
  { key = "left",  dir = "l" },
  { key = "right", dir = "r" },
  { key = "up",    dir = "u" },
  { key = "down",  dir = "d" },
}

-- Keybinds: App
_G.kbTerminal    = _G.mainMod .. " + Return"
_G.kbMenu        = _G.mainMod .. " + R"
_G.kbBrowser     = _G.mainMod .. " + B"
_G.kbFileManager = _G.mainMod .. " + E"
_G.kbEditor      = _G.mainMod .. " + C"

-- keybinds: window actions
_G.kbCloseWindow         = _G.mainMod .. " + Q"
_G.kbToggleFloat         = _G.mainMod .. " + Space"
_G.kbFullScreen          = _G.mainMod .. " + F"
_G.kbBorderedFullScreen  = _G.mainMod .. " + ALT + F"
_G.kbPinWindow           = _G.mainMod .. " + P"
--Special Workspace
_G.kbToggleSpecialWs     = _G.mainMod .. " + S"

-- Keybinds: Hardware (Volume & Brightness)
_G.kbVolumeUp   = "XF86AudioRaiseVolume"
_G.kbVolumeDown = "XF86AudioLowerVolume"
_G.kbVolumeMute = "XF86AudioMute"

_G.kbBrightUp   = "XF86MonBrightnessUp"
_G.kbBrightDown = "XF86MonBrightnessDown"

-- Keybinds: Quickshell
_G.kbLauncher = _G.mainMod .. " + D"

_G.wsGrid  = { cols = 5, rows = 5 }
_G.wsStart = 13

-- Keybinds: Utilities
_G.kbScreenshot      = _G.mainMod .. " + SHIFT + S "
_G.kbSaveScreenshot  = _G.mainMod .. " + CTRL + S "
_G.kbChangeWallpaper = _G.mainMod .. " + W "
_G.kbCopiedHistory   = _G.mainMod .. " + V "

-- Keybinds: Security
_G.kbSandboxTerminal = _G.mainMod .. " + SHIFT + Return"
