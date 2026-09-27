"""Draw the MouseOverTooltip icon in WoW's painted-icon style.

A bevelled gold tooltip frame with glass inside, tilted slightly, and a
metallic cursor with a hover glow where it touches. Drawn at 8x, then
downscaled. Writes Icon.png, Icon.tga (32-bit, bottom-left, no RLE) and
Icon_preview.png (64px at 6x, 36px at 3x, 18px at 6x).
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
FINAL = 64
W = FINAL * 8
YY, XX = np.mgrid[0:W, 0:W].astype(float)


def hexrgb(h):
    return [int(h[i : i + 2], 16) for i in (1, 3, 5)]


def ramp(t, stops):
    """Multi-stop color ramp over t in [0, 1]; stops are (pos, '#rrggbb')."""
    pos = [p for p, _ in stops]
    cols = np.array([hexrgb(c) for _, c in stops], float)
    rgb = np.stack([np.interp(t, pos, cols[:, i]) for i in range(3)], -1)
    alpha = np.full(t.shape + (1,), 255.0)
    return Image.fromarray(np.concatenate([rgb, alpha], -1).astype(np.uint8), "RGBA")


def linear(stops, dx, dy, box=(0, 0, W, W)):
    x0, y0, x1, y1 = box
    t = ((XX - x0) / (x1 - x0)) * dx + ((YY - y0) / (y1 - y0)) * dy
    return ramp(np.clip(t / (abs(dx) + abs(dy)), 0, 1), stops)


def radial(stops, cx, cy, r):
    return ramp(np.clip(np.hypot(XX - cx, YY - cy) / r, 0, 1), stops)


def mask(draw_fn):
    m = Image.new("L", (W, W))
    draw_fn(ImageDraw.Draw(m))
    return m


def rrect(box, r):
    return mask(lambda d: d.rounded_rectangle(box, radius=r, fill=255))


def inset(box, n):
    return (box[0] + n, box[1] + n, box[2] - n, box[3] - n)


def paint(base, fill, m, opacity=1.0):
    """Composite fill onto base through mask m."""
    layer = fill.copy() if isinstance(fill, Image.Image) else Image.new("RGBA", (W, W), fill)
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), m.point(lambda v: int(v * opacity))))
    base.alpha_composite(layer)


# --- background: arcane blue, lit from the upper left, painterly noise ----
img = radial([(0, "#5aa0f0"), (0.45, "#2350a8"), (0.8, "#0f1f5c"), (1, "#050a22")], 190, 150, 460)
noise = Image.effect_noise((W, W), 60).filter(ImageFilter.GaussianBlur(2)).convert("RGBA")
img = Image.blend(img, noise, 0.07)
paint(img, "#9fd8ff", mask(lambda d: d.ellipse((60, 40, 440, 400))).filter(ImageFilter.GaussianBlur(70)), 0.45)

# --- tooltip card, on its own layer so it can be tilted -----------------
card = (52, 66, 420, 346)
layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
shadow = rrect((card[0] + 14, card[1] + 22, card[2] + 14, card[3] + 22), 48)
paint(layer, "#02040c", shadow.filter(ImageFilter.GaussianBlur(16)), 0.75)

gold = linear([(0, "#fff6c2"), (0.3, "#f0c44e"), (0.65, "#c48a26"), (1, "#7a5212")], 0.55, 1, card)
paint(layer, gold, rrect(card, 50))
paint(layer, "#3a2406", rrect(inset(card, 17), 34))  # groove between gold and glass
glass_box = inset(card, 23)
glass_mask = rrect(glass_box, 29)
paint(layer, linear([(0, "#2c3c6c"), (1, "#070b1c")], 0, 1, glass_box), glass_mask)
gloss = ImageChops.multiply(glass_mask, mask(lambda d: d.ellipse((card[0] - 80, card[1] - 170, card[2] + 40, card[1] + 120))))
paint(layer, "#ffffff", gloss, 0.10)

LINES = (  # (y, width, top color, bottom color): name, guild, level
    (112, 250, "#fff09a", "#e0a200"),
    (178, 190, "#9dff8a", "#16a800"),
    (244, 220, "#ffffff", "#8e98ae"),
)
for y, width, top, bottom in LINES:
    box = (98, y, 98 + width, y + 36)
    paint(layer, linear([(0, top), (1, bottom)], 0, 1, box), rrect(box, 18))
    paint(layer, "#ffffff", rrect((110, y + 5, 86 + width, y + 13), 4), 0.45)

img.alpha_composite(layer.rotate(4, resample=Image.BICUBIC, center=(236, 206)))

# --- sparkle: light catching the frame's lit corner ------------------------
spark = (card[0] + 30, card[1] + 26)
star = mask(
    lambda d: (
        d.polygon([(spark[0], spark[1] - 46), (spark[0] + 7, spark[1]), (spark[0], spark[1] + 46), (spark[0] - 7, spark[1])], fill=255),
        d.polygon([(spark[0] - 46, spark[1]), (spark[0], spark[1] - 7), (spark[0] + 46, spark[1]), (spark[0], spark[1] + 7)], fill=255),
    )
)
paint(img, "#fff8dc", star.filter(ImageFilter.GaussianBlur(10)), 0.9)
paint(img, "#ffffff", star)

# --- cursor: WoW's steel gauntlet in its blue hover state ---------------
# Built pointing left in unit coords (claw tip at 0,0), then tilted up-left.
HAND_SCALE, HAND_TILT = 2.6, -36
tip = (258, 186)
fx, fy = 120, 200  # claw tip on the unrotated layer


def hand(x, y):
    return (fx + x * HAND_SCALE, fy + y * HAND_SCALE)


def part_poly(*pts):
    return mask(lambda d: d.polygon([hand(x, y) for x, y in pts], fill=255))


def part_ellipse(x0, y0, x1, y1):
    return mask(lambda d: d.ellipse(hand(x0, y0) + hand(x1, y1), fill=255))


STEEL = [(0, "#ffffff"), (0.3, "#c4cad2"), (0.7, "#6e747e"), (1, "#26292e")]
WRIST = [(0, "#dfe2e6"), (0.45, "#8e8a86"), (1, "#3a302a")]
PARTS = (  # back to front: hand mass, wrist, then claws bottom to top
    (part_ellipse(22, -11, 64, 33), STEEL),
    (part_ellipse(46, 10, 68, 34), WRIST),
    (part_poly((13, 24), (22, 19.5), (31, 18.5), (31, 26), (22, 26.5)), STEEL),
    (part_poly((5, 13), (18, 8), (30, 7), (30, 15.5), (18, 16)), STEEL),
    (part_poly((-4, 0), (12, -5), (30, -7.5), (31, 3.5), (14, 4), (2, 2.5)), STEEL),
)
hand_box = hand(0, -10) + hand(68, 34)
glove = Image.new("RGBA", (W, W), (0, 0, 0, 0))
silhouette = Image.new("L", (W, W))
for part, _ in PARTS:
    silhouette = ImageChops.lighter(silhouette, part)
outline = silhouette.filter(ImageFilter.MaxFilter(13))
paint(glove, "#000000", outline.transform((W, W), Image.AFFINE, (1, 0, -8, 0, 1, -12)).filter(ImageFilter.GaussianBlur(10)), 0.6)
paint(glove, "#1ea8ff", outline.filter(ImageFilter.MaxFilter(21)).filter(ImageFilter.GaussianBlur(8)), 0.8)  # hover glow
paint(glove, "#18a4ff", outline.filter(ImageFilter.MaxFilter(15)))  # hover outline
grain = Image.effect_noise((W, W), 90).filter(ImageFilter.GaussianBlur(1.5)).convert("RGBA")
for part, stops in PARTS:
    paint(glove, "#0c0d10", part.filter(ImageFilter.MaxFilter(11)))
    box = part.getbbox()  # own highlight per part, so claws read as separate
    paint(glove, Image.blend(linear(stops, 0.35, 1, box), grain, 0.12), part)
img.alpha_composite(glove.rotate(HAND_TILT, resample=Image.BICUBIC, center=(fx, fy), translate=(tip[0] - fx, tip[1] - fy)))

# --- vignette, like Blizzard icons ----------------------------------------
vignette = ramp(np.clip(np.hypot(XX - W / 2, YY - W / 2) / (W * 0.72), 0, 1) ** 2.6, [(0, "#ffffff"), (1, "#707070")])
img = ImageChops.multiply(img, vignette)

icon = img.resize((FINAL, FINAL), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=0.8, percent=50, threshold=0))
icon.putalpha(255)
OUT.mkdir(parents=True, exist_ok=True)
icon.save(OUT / "Icon.png")
icon.save(OUT / "Icon.tga", orientation=-1)  # Pillow: -1 = bottom-left origin; no RLE

preview = Image.new("RGBA", (384 + 20 + 108 + 20 + 108, 384), (24, 24, 28, 255))
preview.paste(icon.resize((384, 384), Image.NEAREST), (0, 0))
preview.paste(icon.resize((36, 36), Image.LANCZOS).resize((108, 108), Image.NEAREST), (404, 0))
preview.paste(icon.resize((18, 18), Image.LANCZOS).resize((108, 108), Image.NEAREST), (532, 0))
preview.save(OUT / "Icon_preview.png")
