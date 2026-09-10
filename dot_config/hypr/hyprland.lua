-- Debug: Confirm Lua modules are loading
print("[HYPR] Loading Lua modules...")

require("input")
require("autostart")
require("monitors")
require("animations")
require("environment-variable")
require("looknfeel")
require("bindings") -- Load keybindings
require("windowrules")

print("[HYPR] All Lua modules loaded successfully.")
