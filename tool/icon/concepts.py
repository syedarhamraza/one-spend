"""Draws the One Spend icon concepts as SVGs on the Android adaptive-icon grid.

The canvas is 108 x 108 (the adaptive icon). Launchers crop it to a mask, and only the
central 66-unit circle is guaranteed to show, so every mark stays inside it.

Usage: python tool/icon/concepts.py   (writes tool/icon/concepts/*.svg)
"""

import math
import pathlib

OUT = pathlib.Path(__file__).parent / "concepts"
C = 54.0  # centre

WHITE = "#FFFFFF"
LIGHT = "#BFDBFE"   # light blue accent


def pt(r, deg):
    a = math.radians(deg)
    return C + r * math.cos(a), C + r * math.sin(a)


def arc(r, start, end):
    """Clockwise arc path (SVG y-down) from start to end degrees."""
    x1, y1 = pt(r, start)
    x2, y2 = pt(r, end)
    large = 1 if (end - start) % 360 > 180 else 0
    return f"M{x1:.2f} {y1:.2f} A{r} {r} 0 {large} 1 {x2:.2f} {y2:.2f}"


def arrowhead(r, deg, clockwise, colour, length=10.0, half=10.5):
    """A rounded triangle at angle `deg` on the circle, pointing along the ring."""
    x, y = pt(r, deg)
    a = math.radians(deg)
    t = (-math.sin(a), math.cos(a)) if clockwise else (math.sin(a), -math.cos(a))
    n = (math.cos(a), math.sin(a))
    tip = (x + t[0] * length, y + t[1] * length)
    b1 = (x + n[0] * half, y + n[1] * half)
    b2 = (x - n[0] * half, y - n[1] * half)
    return (f'<path d="M{tip[0]:.2f} {tip[1]:.2f} L{b1[0]:.2f} {b1[1]:.2f} L{b2[0]:.2f} {b2[1]:.2f} Z" '
            f'fill="{colour}" stroke="{colour}" stroke-width="2.5" stroke-linejoin="round"/>')


def ring_segment(r, start, end, colour, width, opacity=1.0):
    op = "" if opacity == 1 else f' stroke-opacity="{opacity}"'
    return (f'<path d="{arc(r, start, end)}" fill="none" stroke="{colour}"{op} '
            f'stroke-width="{width}" stroke-linecap="round"/>')


def background():
    return """<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#5BA2FF"/>
    <stop offset="1" stop-color="#0060E6"/>
  </linearGradient>
  <radialGradient id="sheen" cx="0.3" cy="0.2" r="0.8">
    <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/>
    <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
  </radialGradient>
</defs>
<rect width="108" height="108" fill="url(#bg)"/>
<rect width="108" height="108" fill="url(#sheen)"/>"""


# --- Concepts -----------------------------------------------------------------------

def renewal_loop(colour=WHITE, accent=WHITE):
    """A thick circular arrow around a dot: it renews."""
    r, w = 19.0, 8.5
    return "\n".join([
        ring_segment(r, -40, 250, colour, w),
        arrowhead(r, -40, clockwise=False, colour=colour, length=9.5, half=9),
        f'<circle cx="{C}" cy="{C}" r="6.5" fill="{accent}"/>',
    ])


def card_stack(colour=WHITE, accent=LIGHT, mono=False):
    """Three cards stacked: all in one place."""
    return f"""<rect x="36" y="31" width="44" height="30" rx="7" fill="{colour}" fill-opacity="0.35"/>
<rect x="32" y="39" width="48" height="31" rx="7.5" fill="{colour}" fill-opacity="0.6"/>
<rect x="27" y="47" width="54" height="33" rx="8" fill="{colour}"/>
<rect x="34" y="68" width="17" height="5" rx="2.5" fill="{accent}"/>"""


def spend_ring(colour=WHITE):
    """One ring in four shares; the biggest solid, the rest stepping down in opacity."""
    r, w, gap = 19.5, 10, 22.0
    shares = [(140, 1.0), (90, 0.62), (60, 0.4), (70, 0.78)]
    parts, angle = [], -90.0
    for share, op in shares:
        parts.append(ring_segment(r, angle + gap / 2, angle + share - gap / 2, colour, w, op))
        angle += share
    return "\n".join(parts)


def monogram(colour=WHITE, accent=LIGHT):
    """A bold geometric "1" (One Spend) inside an open ring."""
    return "\n".join([
        ring_segment(24, -60, 240, accent, 5, 0.55),
        f'<path d="M47.5 42 L57 36 L57 71" fill="none" stroke="{colour}" stroke-width="9.5" '
        f'stroke-linecap="round" stroke-linejoin="round"/>',
    ])


def renewing_ring(colour=WHITE):
    """The spend ring whose lead share ends in an arrow: where it goes, and it renews."""
    r, w = 19.5, 10
    return "\n".join([
        ring_segment(r, -76, 140, colour, w),
        arrowhead(r, 140, clockwise=True, colour=colour),
        ring_segment(r, 182, 226, colour, w, 0.7),
        ring_segment(r, 250, 266, colour, w, 0.42),
    ])


CONCEPTS = {
    "1-renewal-loop": renewal_loop,
    "2-card-stack": card_stack,
    "3-spend-ring": spend_ring,
    "4-monogram": monogram,
    "5-renewing-ring": renewing_ring,
}


def svg(body, with_bg=True):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" width="108" height="108">\n'
            f'{background() if with_bg else ""}\n{body}\n</svg>\n')


def main():
    OUT.mkdir(exist_ok=True)
    for name, draw in CONCEPTS.items():
        (OUT / f"{name}.svg").write_text(svg(draw()), encoding="utf-8")
        # Monochrome (themed icon / notification): the mark alone, one colour.
        mono = draw("#000") if name in ("3-spend-ring", "5-renewing-ring") else draw("#000", "#000")
        (OUT / f"{name}-mono.svg").write_text(svg(mono, with_bg=False), encoding="utf-8")
    print(f"Wrote {len(CONCEPTS)} concepts to {OUT}")


if __name__ == "__main__":
    main()
