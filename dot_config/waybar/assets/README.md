# Waybar assets

Backgrounds used by `../style.css`. Edit them in Inkscape, run `~/.config/theme/build`, then restart waybar
(`pkill -x waybar; setsid -f uwsm app -- waybar`), since it only reloads on CSS changes.

| File | Used by | Notes |
|---|---|---|
| `panels/control.svg` | `#custom-control` (far left) | Left-end cap: chamfer bottom-left, notch on the right edge |
| `panels/power.svg` | `#custom-powermenu` | Sits right of control |
| `panels/cpu.svg` | `#cpu` | Outline panel, paired with memory |
| `panels/memory.svg` | `#memory` | Filled variant of the cpu panel |
| `frames/tooltip.svg` | `tooltip` (border-image) | 9-slice frame; `border-image-slice` in style.css depends on its geometry |
| `archive/` | nothing | Old versions kept for reference |

## Rules that keep them rendering correctly

- **Page shape should match the module's shape.** Waybar stretches each SVG to its
  module (`background-size: 100% 85%`). A page much wider than the module gets squeezed
  unevenly, and the top/bottom outline comes out thicker than the sides. The
  square-ish buttons (control, power) use a 120×120 page.
- **Keep comments inside `<svg>`.** GTK recognises an SVG by finding `<svg` in the first
  few hundred bytes; a long comment before it makes the image silently not load.
- **Colors follow the palette.** style.css loads recolored copies from
  `~/.config/theme/gen/waybar/`, which `~/.config/theme/build` writes from these files.
  Draw with the existing colors (`#0e0f18` fill, `#c7373e` outline, `#682628` / `#522226`
  inner fills); `SVG_COLORS` in `build` maps each to a palette role. A new color needs a
  line there, or build warns and leaves it as is. After editing an SVG: run `build`, then
  restart waybar.
