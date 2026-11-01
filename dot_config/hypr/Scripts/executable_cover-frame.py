#!/usr/bin/env python3
"""Images for the hyprlock media dock, always 480x270 (16:9) so the layout
never shifts.

  cover-frame.py frame SRC OUT   fit SRC into the frame: 16:9 covers fill it,
                                 square/portrait ones sit in the middle over a
                                 blurred, darkened copy of themselves
  cover-frame.py host OUT        tile shown when nothing is playing
  cover-frame.py initial OUT X   avatar placeholder: the letter X
  cover-frame.py square SRC OUT  user avatar for the SDDM login: SRC center-cropped
                                 to a 512x512 square
"""

import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps

W, H = 480, 270
FONT = "/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf"


def palette():
    colors = {}
    try:
        for line in open(Path.home() / ".config/theme/palette"):
            m = re.match(r"\s*(\w+)\s*=\s*#([0-9A-Fa-f]{6})", line)
            if m:
                h = m.group(2)
                colors[m.group(1)] = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    except OSError:
        pass
    return colors


def frame(src, out):
    im = Image.open(src).convert("RGB")
    canvas = ImageOps.fit(im, (W, H), Image.LANCZOS)
    if abs(im.width / im.height - W / H) > 0.05:
        # not 16:9: blurred backdrop + the whole image on top
        canvas = canvas.filter(ImageFilter.GaussianBlur(18))
        canvas = ImageEnhance.Brightness(canvas).enhance(0.45)
        fg = ImageOps.contain(im, (W, H), Image.LANCZOS)
        canvas.paste(fg, ((W - fg.width) // 2, (H - fg.height) // 2))
    canvas.save(out, "PNG")


def host(out):
    p = palette()
    bg = p.get("surface", (26, 27, 46))
    fg = p.get("primary", (247, 80, 73))
    im = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(im)
    for y in range(0, H, 6):  # faint scanlines
        d.line([(0, y), (W, y)], fill=tuple(max(0, c - 6) for c in bg))
    font = ImageFont.truetype(FONT, 150)
    d.text((W // 2, H // 2), "\U000f0379", font=font, fill=fg, anchor="mm")  # nf-md-monitor
    im.save(out, "PNG")


def initial(out, letter):
    p = palette()
    bg = p.get("surface", (26, 27, 46))
    im = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(im)
    for y in range(0, H, 6):  # faint scanlines
        d.line([(0, y), (W, y)], fill=tuple(max(0, c - 6) for c in bg))
    font = ImageFont.truetype("/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Bold.ttf", 190)
    glow = Image.new("RGB", (W, H))
    ImageDraw.Draw(glow).text((W // 2, H // 2), letter.upper()[:1], font=font, fill=p.get("secondary", (94, 246, 255)), anchor="mm")
    im = Image.fromarray(np.clip(np.asarray(im, np.float32) + np.asarray(glow.filter(ImageFilter.GaussianBlur(14)), np.float32) * .8, 0, 255).astype(np.uint8))
    ImageDraw.Draw(im).text((W // 2, H // 2), letter.upper()[:1], font=font, fill=p.get("accent", (243, 233, 0)), anchor="mm")
    im.save(out, "PNG")


def square(src, out, size=512):
    im = Image.open(src).convert("RGB")
    ImageOps.fit(im, (size, size), Image.LANCZOS).save(out, "PNG")


if __name__ == "__main__":
    if sys.argv[1] == "frame":
        frame(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "host":
        host(sys.argv[2])
    elif sys.argv[1] == "square":
        square(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "initial":
        initial(sys.argv[2], sys.argv[3])
