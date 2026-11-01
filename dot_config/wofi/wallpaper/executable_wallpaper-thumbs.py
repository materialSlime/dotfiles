#!/usr/bin/env python3
"""Thumbnails for the wallpaper picker: center-cropped to the monitor's aspect
ratio (wallpapers are set with --resize crop, so this is what lands on screen).
Only missing or outdated thumbnails are regenerated."""

import argparse
import hashlib
import json
import os
import subprocess
from pathlib import Path

from PIL import Image, ImageOps

FOLDER = Path.home() / "Pictures/Wallpapers"
CACHE = Path.home() / ".cache/wallpaper-picker"
WIDTH = 384
EXTS = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"}


def monitor_ratio() -> float:
    try:
        mons = json.loads(subprocess.run(["hyprctl", "-j", "monitors"],
                                         capture_output=True, text=True).stdout)
        m = next((m for m in mons if m.get("focused")), mons[0])
        w, h = m["width"], m["height"]
        if m.get("transform", 0) % 2:
            w, h = h, w
        return w / h
    except Exception:
        return 16 / 9


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--width", type=int, default=WIDTH)
    ap.add_argument("--out", type=Path, default=CACHE)
    args = ap.parse_args()
    cache, width = args.out, args.width
    cache.mkdir(parents=True, exist_ok=True)
    size = (width, round(width / monitor_ratio()))
    for root, _, files in os.walk(FOLDER):
        for name in files:
            path = Path(root, name)
            if path.suffix.lower() not in EXTS:
                continue
            key = hashlib.md5(os.path.realpath(path).encode()).hexdigest()
            out = cache / f"{key}.png"
            try:
                if out.exists() and out.stat().st_mtime >= path.stat().st_mtime:
                    with Image.open(out) as t:
                        if t.size == size:
                            continue
                with Image.open(path) as img:
                    img.seek(getattr(img, "n_frames", 1) // 4)
                    thumb = ImageOps.fit(img.convert("RGB"), size, Image.LANCZOS)
                    thumb.save(out, "PNG")
            except Exception as e:
                print(f"skip {path.name}: {e}")


if __name__ == "__main__":
    main()
