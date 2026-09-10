-- Ultra-Fast "Instant" Animations
-- In Lua API, LOWER speed = FASTER duration (deciseconds)
hl.curve("instant", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Global speed boost (Lower = Faster)
hl.animation({ leaf = "global", enabled = true, speed = 1.0, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 0.5, bezier = "easeOutQuint" })

-- Windows: Near-instant snap
hl.animation({ leaf = "windows", enabled = true, speed = 0.8, bezier = "instant" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 0.8, bezier = "instant", style = "popin 70%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 0.8, bezier = "instant", style = "popin 70%" })

-- Fades: Extremely fast
hl.animation({ leaf = "fadeIn", enabled = true, speed = 0.5, bezier = "instant" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 0.5, bezier = "instant" })
hl.animation({ leaf = "fade", enabled = true, speed = 0.5, bezier = "quick" })

-- Layers: Snappy overlays
hl.animation({ leaf = "layers", enabled = true, speed = 1.0, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.0, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.0, bezier = "easeOutQuint", style = "fade" })

-- Workspaces: Maximum speed
hl.animation({ leaf = "workspaces", enabled = true, speed = 0.8, bezier = "instant", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 0.8, bezier = "instant", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 0.8, bezier = "instant", style = "fade" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 0.5, bezier = "quick" })
