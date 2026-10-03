"""Removes Samsung's Edge panel handle from phone captures.

One UI draws a thin handle on the right edge of the screen (in the band between
y = 420 and 790 on a 1080 x 2340 capture). It isn't part of the app, so it's
painted out by copying the column just left of it across the strip. Run once after
capturing; safe to run again.

Usage: python clean_captures.py [captures folder]
"""

import pathlib
import sys

from PIL import Image

folder = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).parent / "captures")
STRIP = 34          # px from the right edge covered by the handle
TOP, BOTTOM = 400, 820

for path in sorted(folder.glob("[0-9]*.png")):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    if (w, h) != (1080, 2340):
        print(f"  skip {path.name} ({w}x{h})")
        continue
    px = im.load()
    src = w - STRIP - 2
    for y in range(TOP, BOTTOM):
        colour = px[src, y]
        for x in range(w - STRIP, w):
            px[x, y] = colour
    im.save(path)
    print(f"  cleaned {path.name}")
