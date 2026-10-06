-- Colors come from ~/.config/theme/palette (run ~/.config/theme/build after editing)
package.path = os.getenv("HOME") .. "/.config/theme/gen/?.lua;" .. package.path
local c = require("colors")

hl.config({
	general = {
		gaps_in = 1,
		gaps_out = 1,

		border_size = 2,

		col = {
			active_border = { colors = { c.primary, c.accent }, angle = 90 },
			inactive_border = c.rgba("bg", 0.67),
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},
	decoration = {
		rounding = 10,
		rounding_power = 1.0,
		active_opacity = 0.95,
		inactive_opacity = 0.87,
		dim_inactive = true,
		dim_strength = 0.2,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = c.rgba("bg", 0.93),
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.15,
			special = true,
		},
	},
	animations = {
		enabled = true,
	},
})
