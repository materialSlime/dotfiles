-- Keybindings in proper Lua format for Hyprland
-- See: /usr/share/hypr/hyprland.lua for the correct API

local mainMod = "SUPER"
local terminal = "xdg-terminal-exec"
local browser = "zen-browser"
local fileManager = "nemo"
local topBar = "waybar"

-- Terminal
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("uwsm-app  -- " .. terminal))

-- Launch browser
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("uwsm-app  -- " .. browser))

-- Launch file manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm-app  -- " .. fileManager))

-- Launch launcher
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pkill -x wofi || wofi --show drun"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("pkill -x wofi || wofi --show run"))

-- Control menu: every common action by click/touch (also the waybar 󰍜 button)
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("~/.config/wofi/control-menu.sh"))

-- Power Menu
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("~/.config/wofi/power-menu.sh"))

-- Inhibit Sleep
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/.config/waybar/scripts/caffeine.sh toggle"))

-- Close window
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

-- Toggle topBar
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill " .. topBar .. " || setsid " .. topBar))

-- Toggle swaync control panel
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
-- Cliphist History
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.config/wofi/clipboard.sh"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/wofi/clipboard.sh delete"))

-- Access TUI
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("uwsm app -- xdg-terminal-exec --title=floating-tui bluetui"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("uwsm app -- xdg-terminal-exec --title=floating-tui impala"))
hl.bind(mainMod .. " + CTRL + A", hl.dsp.exec_cmd("uwsm app -- xdg-terminal-exec --title=floating-tui wiremix"))

-- Move focus (vim-style: HJKL)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Cycle Window Focus
hl.bind(mainMod .. " + TAB", hl.dsp.window.cycle_next({ prev = false }))
hl.bind(mainMod .. " + ALT + TAB", hl.dsp.window.cycle_next({ prev = true }))

-- Move window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces 1-10 (key 0 maps to workspace 10)
for i = 1, 9 do
	local key = tostring(i)
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end
-- Workspace 10 uses key 0
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = true }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

--Special Workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))

--Fullscreen and Maximize
hl.bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))

-- Toggle current window between Floating and Tiling mode
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))

-- Pin a floating window (makes it visible across all workspaces)
hl.bind(mainMod .. " + P", hl.dsp.window.pin())

-- Swap the current active window with another master/slave window
-- hl.bind(mainMod .. " + RETURN", hl.dsp.window.swap_next())

-- Physical PowerButton
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("~/.config/wofi/power-menu.sh"))

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume raise"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Reload Hyprland
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Screenshots (hyprshot)
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -m active -o ~/Pictures/Screenshots"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/Screenshots"))
hl.bind(mainMod .. " + ALT + Print", hl.dsp.exec_cmd("hyprshot -m window -m active -o ~/Pictures/Screenshots"))

-- Lock Screen
hl.bind(mainMod .. "+ ALT + L", hl.dsp.exec_cmd("hyprlock"))

-- Submap "menu": active only while a control-menu.sh wofi is open (the script enters
-- and leaves it). Right-click anywhere (long-press in Moonlight) closes the menu,
-- since phone keyboards have no Esc and wofi keeps the keyboard while open.
hl.define_submap("menu", function()
	hl.bind("mouse:273", hl.dsp.exec_cmd("pkill -x wofi"))
end)
