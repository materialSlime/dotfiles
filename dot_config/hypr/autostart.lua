hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm app -- waybar")
	hl.exec_cmd("uwsm app -- hypridle")
	hl.exec_cmd("uwsm app -- /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("uwsm app -- swaync")
	hl.exec_cmd("uwsm app -- swayosd-server")
	hl.exec_cmd("uwsm app -- awww-daemon")
	hl.exec_cmd("uwsm app -- /home/neo/.config/auto-script/cycly-wallpaper-awww.sh")
	-- Watch for text copies and store them in cliphist
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	-- Watch for image copies and store them in cliphist
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	hl.exec_cmd("uwsm app -- /usr/bin/sunshine")
end)
