"""Makes the rendered graphics Play-ready and checks them.

- Screenshots and the feature graphic: flattened to opaque RGB PNG (Play rejects alpha
  on the feature graphic) and checked for their exact size.
- Icon: the app logo at 512 x 512, 32-bit PNG.

Usage: python finish.py <store/play folder> <logo.png>
"""

import pathlib
import sys

from PIL import Image

out = pathlib.Path(sys.argv[1])
logo = pathlib.Path(sys.argv[2])

expected = {p: (1080, 1920) for p in sorted((out / "screenshots").glob("*.png"))}
expected[out / "feature-graphic.png"] = (1024, 500)

for path, size in expected.items():
    im = Image.open(path)
    if im.size != size:
        sys.exit(f"{path.name} is {im.size}, expected {size}")
    im.convert("RGB").save(path, optimize=True)
    print(f"  ok  {path.relative_to(out)}  {size[0]}x{size[1]}  {path.stat().st_size // 1024} KB")

icon = Image.open(logo).convert("RGBA").resize((512, 512), Image.LANCZOS)
icon.save(out / "icon-512.png", optimize=True)
print("  ok  icon-512.png  512x512")
