hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
	vrr = 2,
})

-- Virtual output for Sunshine/Moonlight when no physical monitor is plugged in
-- (created in autostart.lua). TV panel is ~1366x768; 1344x756 is the nearest size that
-- scale 4/3 divides into whole pixels (desktop 1008x567); Hyprland rejects scales that
-- don't, and 1366x768 only allows 1 or 2. Sunshine rescales to what the TV asks for.
-- No HDR: the RX 570 can't encode 10-bit, so Sunshine would only tonemap it back to SDR.
hl.monitor({
	output = "SUNSHINE",
	mode = "1280x720@60",
	position = "auto",
	scale = 1,
})
