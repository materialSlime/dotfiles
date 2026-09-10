hl.config({
	general = {
		gaps_in = 1,
		gaps_out = 1,

		border_size = 2,

		col = {
			active_border = { colors = { "rgba(247, 80, 72, 1)", "rgba(241, 181, 55, 1)" }, angle = 90 },
			inactive_border = "rgba(14, 15, 24, 0.67)",
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
			color = "rgba(14, 15, 24, 0.93)",
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
