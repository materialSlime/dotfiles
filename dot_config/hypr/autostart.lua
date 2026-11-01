hl.on("hyprland.start", function()
	-- SDDM autologins without a password, so lock before anything else starts
	hl.exec_cmd("uwsm app -- hyprlock")
	hl.exec_cmd("uwsm app -- waybar")
	hl.exec_cmd("uwsm app -- hypridle")
	hl.exec_cmd("uwsm app -- /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("uwsm app -- swaync")
	hl.exec_cmd("uwsm app -- swayosd-server")
	hl.exec_cmd("uwsm app -- awww-daemon")
	hl.exec_cmd("uwsm app -- /home/neo/.config/wofi/wallpaper/wallpaper.sh")
	-- Watch for text copies and store them in cliphist
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	-- Watch for image copies and store them in cliphist
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Gamepad: Back+Start opens control-menu.sh, D-pad/A/B drive it (Hyprland can't bind pads)
	hl.exec_cmd("uwsm app -- /home/neo/.config/wofi/gamepad/gamepad-menu.py")

	-- No physical monitor connected → create the SUNSHINE virtual output first,
	-- because Sunshine only enumerates outputs at startup. Rule in monitors.lua.
	-- Loop: Sunshine segfaults if a stream is open across suspend/resume, so respawn it.
	-- The stream lock (see sunshine.conf / hypridle.conf) is cleared on each start.
	hl.exec_cmd(
		"sh -c 'grep -qx connected /sys/class/drm/card*-*/status || hyprctl output create headless SUNSHINE; while :; do rm -f /tmp/sunshine-stream.lock; uwsm app -- /usr/bin/sunshine; sleep 3; done'"
	)
end)
