#!/usr/bin/env python3
"""Put before/after screenshots side by side: compare.py <before-dir> <after-dir> <out-dir>

For every PNG present in both dirs writes <out-dir>/<name>.png: before | after, scaled to half
size, with a label strip on top. Needs Pillow (pip install pillow).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

before, after, out = map(Path, sys.argv[1:4])
out.mkdir(parents=True, exist_ok=True)
try:
    font = ImageFont.truetype("Arial.ttf", 28)
except OSError:
    font = ImageFont.load_default()

for b in sorted(before.glob("*.png")):
    a = after / b.name
    if not a.exists():
        continue
    ib, ia = (Image.open(p).convert("RGB") for p in (b, a))
    w, h = ib.width // 2, ib.height // 2
    ib, ia = ib.resize((w, h)), ia.resize((w, h))
    gap, top = 16, 48
    canvas = Image.new("RGB", (2 * w + gap, h + top), "white")
    canvas.paste(ib, (0, top))
    canvas.paste(ia, (w + gap, top))
    draw = ImageDraw.Draw(canvas)
    draw.text((10, 10), "before", fill="black", font=font)
    draw.text((w + gap + 10, 10), "after", fill="black", font=font)
    draw.line([(w + gap // 2, top), (w + gap // 2, top + h)], fill="black", width=2)
    canvas.save(out / b.name, optimize=True)
    print(out / b.name)
