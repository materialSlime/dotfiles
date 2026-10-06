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

hl.window_rule({
	name = "Float modal dialogs",
	match = { modal = true },
	float = true,
	center = true,
})

hl.window_rule({
	name = "Float file pickers",
	match = { title = "^(Open|Save|Select|Choose).*|.*(Open File|Save As|File Upload).*" },
	float = true,
	center = true,
	size = "900 600",
})

hl.window_rule({
	name = "Portal file chooser",
	match = { class = "xdg-desktop-portal-gtk" },
	float = true,
	center = true,
	size = "900 600",
})

hl.window_rule({
	name = "Polkit prompt",
	match = { class = "polkit-gnome-authentication-agent-1" },
	float = true,
	center = true,
	pin = true,
})

hl.window_rule({
	name = "Float Utilities",
	match = {
		class = "org.gnome.Calculator|org.gnome.FileRoller|nwg-look|Bitwarder|imv",
	},
	float = true,
})

hl.window_rule({
	name = "Opaque Media",
	match = {
		class = "zen|chromium|blender|mpv|imv",
	},
	opaque = true,
})

hl.window_rule({})
