hl.window_rule({
	name = "Center floating tui",
	match = {
		title = "floating-tui",
	},
	float = true,
	center = true,
})

hl.window_rule({
	name = "Screensaver Overlay",
	match = {
		title = "custom-screensaver",
	},
	float = true,
	fullscreen = 1,
	center = true,
})

hl.window_rule({
	name = "Picture in picture",
	match = {
		title = "Picture-in-Picture|Picture in picture",
	},
	opaque = 1,
	float = true,
	pin = true,
})

hl.layer_rule({
	name = "BlurNC",
	match = {
		namespace = "swaync-control-center|swaync-notification-window",
	},
	blur = true,
	ignore_alpha = false,
	animation = "slide right",
})
