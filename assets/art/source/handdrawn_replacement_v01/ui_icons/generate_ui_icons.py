from __future__ import annotations

import hashlib
import json
import math
import random
from pathlib import Path
from typing import Callable

from PIL import Image, ImageDraw


SCALE = 4

INK = (18, 14, 10, 255)
INK_SOFT = (43, 31, 22, 255)
WHITE = (255, 247, 220, 255)
PARCHMENT = (238, 203, 130, 255)
PARCHMENT_DARK = (176, 111, 48, 255)
WOOD = (151, 81, 35, 255)
WOOD_DARK = (92, 51, 28, 255)
WOOD_LIGHT = (204, 124, 54, 255)
LEAF = (117, 183, 45, 255)
LEAF_DARK = (58, 113, 33, 255)
LEAF_LIGHT = (190, 227, 68, 255)
POTATO = (224, 152, 55, 255)
POTATO_DARK = (142, 80, 35, 255)
GOLD = (244, 173, 31, 255)
GOLD_LIGHT = (255, 223, 76, 255)
RED = (219, 55, 30, 255)
RED_DARK = (139, 28, 25, 255)
BLUE = (55, 131, 212, 255)
BLUE_LIGHT = (112, 203, 255, 255)
TEAL = (38, 137, 129, 255)
PURPLE = (116, 43, 150, 255)
PURPLE_DARK = (59, 25, 78, 255)
MAGIC = (86, 210, 83, 255)
GRAY = (111, 104, 91, 255)
GRAY_DARK = (61, 58, 54, 255)


REPO = Path(__file__).resolve().parents[5]
ART = REPO / "assets" / "art"
SOURCE_DIR = Path(__file__).resolve().parent
MASTER_DIR = SOURCE_DIR / "masters"
STYLE_DIR = ART / "style_preview" / "handdrawn_cel_v01"


def sx(value: float) -> int:
    return int(round(value * SCALE))


def box(values: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    return tuple(sx(v) for v in values)


def pts(values: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [(sx(x), sx(y)) for x, y in values]


def lw(width: float) -> int:
    return max(1, sx(width))


def draw_line(
    draw: ImageDraw.ImageDraw,
    values: list[tuple[float, float]],
    fill=INK,
    width: float = 2.0,
    closed: bool = False,
) -> None:
    scaled = pts(values + ([values[0]] if closed else []))
    try:
        draw.line(scaled, fill=fill, width=lw(width), joint="curve")
    except TypeError:
        draw.line(scaled, fill=fill, width=lw(width))


def poly(
    draw: ImageDraw.ImageDraw,
    values: list[tuple[float, float]],
    fill,
    outline=INK,
    width: float = 2.0,
) -> None:
    draw.polygon(pts(values), fill=fill)
    draw_line(draw, values, fill=outline, width=width, closed=True)


def ellipse(
    draw: ImageDraw.ImageDraw,
    values: tuple[float, float, float, float],
    fill,
    outline=INK,
    width: float = 2.0,
) -> None:
    draw.ellipse(box(values), fill=fill, outline=outline, width=lw(width))


def rounded(
    draw: ImageDraw.ImageDraw,
    values: tuple[float, float, float, float],
    radius: float,
    fill,
    outline=INK,
    width: float = 2.0,
) -> None:
    draw.rounded_rectangle(box(values), radius=sx(radius), fill=fill, outline=outline, width=lw(width))


def clear_rounded(img: Image.Image, values: tuple[float, float, float, float], radius: float) -> None:
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle(box(values), radius=sx(radius), fill=255)
    alpha = img.getchannel("A")
    alpha.paste(0, mask=mask)
    img.putalpha(alpha)


def clear_ellipse(img: Image.Image, values: tuple[float, float, float, float]) -> None:
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.ellipse(box(values), fill=255)
    alpha = img.getchannel("A")
    alpha.paste(0, mask=mask)
    img.putalpha(alpha)


def make_canvas(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (w * SCALE, h * SCALE), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img, "RGBA")


def blob_points(
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    seed: str,
    n: int = 44,
    wobble: float = 0.08,
) -> list[tuple[float, float]]:
    rng = random.Random(seed)
    values: list[tuple[float, float]] = []
    for i in range(n):
        a = math.tau * i / n
        m = 1.0 + rng.uniform(-wobble, wobble)
        values.append((cx + math.cos(a) * rx * m, cy + math.sin(a) * ry * m))
    return values


def draw_blob(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    fill,
    seed: str,
    outline=INK,
    width: float = 3.5,
    wobble: float = 0.08,
) -> None:
    poly(draw, blob_points(cx, cy, rx, ry, seed, wobble=wobble), fill=fill, outline=outline, width=width)


def draw_leaf(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    angle: float,
    length: float,
    width: float,
    fill=LEAF,
    outline=INK,
    line_width: float = 2.0,
) -> None:
    dx = math.cos(angle)
    dy = math.sin(angle)
    px = -dy
    py = dx
    base = (cx - dx * length * 0.45, cy - dy * length * 0.45)
    tip = (cx + dx * length * 0.55, cy + dy * length * 0.55)
    left = (cx + px * width * 0.48, cy + py * width * 0.48)
    right = (cx - px * width * 0.48, cy - py * width * 0.48)
    poly(draw, [base, left, tip, right], fill=fill, outline=outline, width=line_width)
    draw_line(draw, [base, tip], fill=LEAF_DARK, width=max(1.0, line_width * 0.45))


def draw_sprout(draw: ImageDraw.ImageDraw, cx: float, cy: float, size: float) -> None:
    draw_line(draw, [(cx, cy + size * 0.32), (cx, cy - size * 0.28)], fill=INK, width=size * 0.12)
    draw_line(draw, [(cx, cy + size * 0.25), (cx, cy - size * 0.25)], fill=LEAF_DARK, width=size * 0.06)
    draw_leaf(draw, cx - size * 0.18, cy - size * 0.19, -2.55, size * 0.52, size * 0.26, fill=LEAF_LIGHT, line_width=size * 0.08)
    draw_leaf(draw, cx + size * 0.2, cy - size * 0.21, -0.55, size * 0.56, size * 0.28, fill=LEAF, line_width=size * 0.08)


def draw_star(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    outer: float,
    inner: float,
    fill=GOLD_LIGHT,
    outline=INK,
    points_count: int = 5,
    width: float = 1.7,
) -> None:
    values = []
    for i in range(points_count * 2):
        r = outer if i % 2 == 0 else inner
        a = -math.pi / 2 + i * math.pi / points_count
        values.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    poly(draw, values, fill=fill, outline=outline, width=width)


def draw_heart(draw: ImageDraw.ImageDraw, cx: float, cy: float, size: float, fill=RED) -> None:
    values = []
    for i in range(80):
        t = math.tau * i / 80
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        values.append((cx + x * size / 34.0, cy + y * size / 34.0))
    poly(draw, values, fill=fill, outline=INK, width=size * 0.08)
    ellipse(draw, (cx - size * 0.22, cy - size * 0.2, cx - size * 0.04, cy - size * 0.05), (255, 133, 88, 150), outline=(0, 0, 0, 0), width=0.1)


def draw_coin(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, tilt: float = 0.0) -> None:
    ellipse(draw, (cx - r * 0.92, cy - r, cx + r * 0.92, cy + r), fill=GOLD, outline=INK, width=r * 0.15)
    ellipse(draw, (cx - r * 0.58, cy - r * 0.64, cx + r * 0.58, cy + r * 0.64), fill=(232, 134, 24, 255), outline=INK_SOFT, width=r * 0.06)
    draw.arc(box((cx - r * 0.5, cy - r * 0.58, cx + r * 0.46, cy + r * 0.55)), start=205, end=335, fill=GOLD_LIGHT, width=lw(r * 0.1))
    if tilt:
        draw_line(draw, [(cx - r * 0.25, cy - r * 0.2), (cx + r * 0.25, cy + r * 0.15)], fill=(255, 221, 76, 180), width=r * 0.08)


def draw_crystal(draw: ImageDraw.ImageDraw, cx: float, cy: float, w: float, h: float, fill=GOLD_LIGHT, accent=GOLD) -> None:
    values = [
        (cx, cy - h * 0.5),
        (cx + w * 0.45, cy - h * 0.08),
        (cx + w * 0.24, cy + h * 0.48),
        (cx - w * 0.25, cy + h * 0.48),
        (cx - w * 0.46, cy - h * 0.08),
    ]
    poly(draw, values, fill=fill, outline=INK, width=max(1.6, w * 0.06))
    poly(draw, [(cx, cy - h * 0.5), (cx + w * 0.45, cy - h * 0.08), (cx, cy + h * 0.12)], fill=accent, outline=(0, 0, 0, 0), width=0.1)
    draw_line(draw, [(cx, cy - h * 0.45), (cx, cy + h * 0.42)], fill=(255, 245, 160, 185), width=max(1.0, w * 0.035))


def draw_potato(draw: ImageDraw.ImageDraw, w: int, h: int, cx: float, cy: float, rx: float, ry: float, seed: str, face: bool = False) -> None:
    draw_blob(draw, cx, cy, rx, ry, POTATO, seed=seed, width=max(2.4, min(w, h) * 0.045), wobble=0.07)
    draw_blob(draw, cx + rx * 0.17, cy + ry * 0.2, rx * 0.86, ry * 0.72, (174, 95, 37, 110), seed=seed + "-shade", outline=(0, 0, 0, 0), width=0.1, wobble=0.08)
    ellipse(draw, (cx - rx * 0.5, cy - ry * 0.45, cx - rx * 0.28, cy - ry * 0.24), (255, 202, 87, 140), outline=(0, 0, 0, 0), width=0.1)
    rng = random.Random(seed + "-spots")
    for _ in range(8):
        px = cx + rng.uniform(-rx * 0.58, rx * 0.58)
        py = cy + rng.uniform(-ry * 0.48, ry * 0.48)
        pr = rng.uniform(max(1.0, rx * 0.04), max(1.5, rx * 0.085))
        ellipse(draw, (px - pr, py - pr * 0.8, px + pr, py + pr * 0.8), fill=POTATO_DARK, outline=(0, 0, 0, 0), width=0.1)
    if face:
        ellipse(draw, (cx - rx * 0.37, cy - ry * 0.06, cx - rx * 0.24, cy + ry * 0.14), INK, outline=INK, width=0.2)
        ellipse(draw, (cx + rx * 0.2, cy - ry * 0.06, cx + rx * 0.33, cy + ry * 0.14), INK, outline=INK, width=0.2)
        draw.arc(box((cx - rx * 0.22, cy + ry * 0.1, cx + rx * 0.24, cy + ry * 0.42)), start=15, end=165, fill=INK, width=lw(rx * 0.06))


def draw_banner(draw: ImageDraw.ImageDraw, cx: float, cy: float, w: float, h: float, fill=WOOD) -> None:
    rounded(draw, (cx - w * 0.5, cy - h * 0.5, cx + w * 0.5, cy + h * 0.5), h * 0.18, fill=fill, outline=INK, width=h * 0.12)
    draw_line(draw, [(cx - w * 0.42, cy - h * 0.12), (cx + w * 0.42, cy - h * 0.12)], fill=WOOD_LIGHT, width=h * 0.06)
    draw_line(draw, [(cx - w * 0.42, cy + h * 0.17), (cx + w * 0.42, cy + h * 0.17)], fill=WOOD_DARK, width=h * 0.055)
    for nx in (-0.37, 0.37):
        ellipse(draw, (cx + w * nx - h * 0.06, cy - h * 0.08, cx + w * nx + h * 0.06, cy + h * 0.08), fill=INK_SOFT, outline=INK, width=h * 0.035)


def draw_panel_wood(draw: ImageDraw.ImageDraw, w: int, h: int, kind: str) -> None:
    if kind == "wide":
        values = (8, h * 0.33, w - 8, h * 0.67)
        radius = h * 0.09
    elif kind == "small":
        values = (35, h * 0.37, w - 35, h * 0.64)
        radius = h * 0.07
    else:
        values = (8, h * 0.31, w - 8, h * 0.69)
        radius = h * 0.08
    rounded(draw, values, radius, fill=WOOD, outline=INK, width=max(3.0, h * 0.045))
    x0, y0, x1, y1 = values
    draw_line(draw, [(x0 + 9, y0 + (y1 - y0) * 0.34), (x1 - 9, y0 + (y1 - y0) * 0.31)], fill=WOOD_LIGHT, width=1.8)
    draw_line(draw, [(x0 + 8, y0 + (y1 - y0) * 0.68), (x1 - 8, y0 + (y1 - y0) * 0.71)], fill=WOOD_DARK, width=1.8)
    for nx in (x0 + 13, x1 - 13):
        ellipse(draw, (nx - 3, (y0 + y1) / 2 - 3, nx + 3, (y0 + y1) / 2 + 3), fill=INK_SOFT, outline=INK, width=1.0)
    draw_leaf(draw, x0 + 12, y0 + 4, -2.45, 15, 8, fill=LEAF, line_width=1.3)
    draw_leaf(draw, x1 - 12, y1 - 3, 0.65, 15, 8, fill=LEAF_LIGHT, line_width=1.3)


def draw_square_frame(draw: ImageDraw.ImageDraw, img: Image.Image, w: int, h: int, rarity: str) -> None:
    if rarity == "legendary":
        fill, accent = GOLD, RED
    elif rarity == "rare":
        fill, accent = BLUE_LIGHT, BLUE
    else:
        fill, accent = (128, 170, 96, 255), LEAF
    rounded(draw, (32, 32, w - 32, h - 32), 8, fill=fill, outline=INK, width=4.0)
    clear_rounded(img, (43, 43, w - 43, h - 43), 3)
    rounded(draw, (43, 43, w - 43, h - 43), 3, fill=(0, 0, 0, 0), outline=INK, width=2.2)
    if rarity == "legendary":
        for x, y in [(40, 35), (w - 40, 35), (40, h - 35), (w - 40, h - 35)]:
            draw_star(draw, x, y, 6, 3, fill=GOLD_LIGHT, outline=INK, width=1.0)
    elif rarity == "rare":
        for x, y in [(43, 38), (w - 43, 38), (43, h - 38), (w - 43, h - 38)]:
            draw_crystal(draw, x, y, 9, 12, fill=BLUE_LIGHT, accent=BLUE)
    else:
        for x, y, a in [(40, 38, -2.3), (w - 40, h - 38, 0.8)]:
            draw_leaf(draw, x, y, a, 15, 8, fill=accent, line_width=1.2)


def draw_cursor(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    values = [(46, 35), (82, 61), (68, 67), (78, 91), (65, 95), (56, 71), (43, 83)]
    poly(draw, values, fill=(255, 249, 215, 255), outline=INK, width=4.0)
    draw_line(draw, [(51, 45), (68, 59)], fill=WHITE, width=2.0)


def draw_slot(draw: ImageDraw.ImageDraw, img: Image.Image, w: int, h: int, kind: str) -> None:
    fill = WOOD if kind == "weapon" else (58, 132, 118, 255) if kind == "magic" else GRAY
    inner = (70, 45, 29, 200) if kind == "weapon" else (32, 56, 65, 205) if kind == "magic" else (53, 50, 47, 210)
    rounded(draw, (25, 24, w - 25, h - 24), 9, fill=fill, outline=INK, width=4.5)
    rounded(draw, (36, 35, w - 36, h - 35), 5, fill=inner, outline=INK_SOFT, width=2.0)
    if kind == "magic":
        for x, y in [(33, 29), (w - 33, 29), (33, h - 29), (w - 33, h - 29)]:
            draw_crystal(draw, x, y, 10, 14, fill=(76, 229, 96, 255), accent=(26, 148, 89, 255))
    elif kind == "weapon":
        for x, y in [(34, 31), (w - 34, 31), (34, h - 31), (w - 34, h - 31)]:
            ellipse(draw, (x - 3, y - 3, x + 3, y + 3), fill=GOLD, outline=INK, width=1.1)
    else:
        draw_line(draw, [(39, 39), (w - 39, h - 39)], fill=(33, 31, 30, 160), width=5.0)
        draw_line(draw, [(w - 39, 39), (39, h - 39)], fill=(33, 31, 30, 160), width=5.0)


def draw_bar_frame(draw: ImageDraw.ImageDraw, img: Image.Image, w: int, h: int, kind: str) -> None:
    if kind == "boss":
        rounded(draw, (0, 4, w - 1, h - 5), 10, fill=(88, 48, 38, 255), outline=INK, width=3.8)
        rounded(draw, (61, 13, w - 10, h - 12), 5, fill=(44, 30, 24, 180), outline=INK_SOFT, width=1.6)
        clear_rounded(img, (65, 16, w - 13, h - 15), 3)
        draw_blob(draw, 28, h / 2 + 1, 23, 16, (122, 37, 34, 255), seed="boss-cap", width=2.8)
        draw_star(draw, 28, h / 2, 10, 5, fill=RED, outline=INK, width=1.4)
        for x in (74, w - 19):
            draw_crystal(draw, x, h / 2, 9, 14, fill=GOLD_LIGHT, accent=GOLD)
    else:
        accent = LEAF if kind == "hp" else BLUE_LIGHT
        cap_fill = (101, 155, 55, 255) if kind == "hp" else (53, 116, 172, 255)
        rounded(draw, (0, 5, w - 1, h - 5), 9, fill=WOOD_DARK, outline=INK, width=3.4)
        rounded(draw, (23, 13, w - 9, h - 12), 5, fill=(41, 30, 22, 175), outline=INK_SOFT, width=1.4)
        clear_rounded(img, (27, 16, w - 12, h - 15), 3)
        if kind == "hp":
            draw_heart(draw, 15, h / 2 + 1, 19, fill=(151, 205, 64, 255))
        else:
            draw_crystal(draw, 15, h / 2 + 1, 19, 27, fill=BLUE_LIGHT, accent=BLUE)
        draw_leaf(draw, w - 13, h / 2, 0.05, 20, 9, fill=accent, line_width=1.4)


def draw_magic_slot(draw: ImageDraw.ImageDraw, img: Image.Image, w: int, h: int, disabled: bool) -> None:
    fill = GRAY if disabled else TEAL
    rounded(draw, (2, 5, w - 3, h - 4), 8, fill=fill, outline=INK, width=3.8)
    rounded(draw, (17, 19, w - 18, min(h - 15, 70)), 5, fill=(36, 50, 55, 210), outline=INK_SOFT, width=1.7)
    if disabled:
        draw_line(draw, [(21, 24), (w - 21, min(h - 21, 68))], fill=(25, 23, 22, 150), width=4.0)
    else:
        draw_crystal(draw, w / 2, 15, 12, 18, fill=BLUE_LIGHT, accent=BLUE)
        draw_leaf(draw, w - 16, h - 20, 0.3, 17, 8, fill=LEAF, line_width=1.2)


def draw_health_badge(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_heart(draw, w / 2, h / 2 + 8, 70, fill=(214, 138, 54, 255))
    draw_sprout(draw, w / 2, 30, 24)
    ellipse(draw, (45, 49, 58, 64), fill=(255, 202, 87, 140), outline=(0, 0, 0, 0), width=0.1)


def draw_mana_badge(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    values = [(w / 2, 19), (88, 55), (71, 103), (w / 2, 115), (57, 103), (39, 55)]
    poly(draw, values, fill=(76, 169, 83, 255), outline=INK, width=4.0)
    draw_leaf(draw, w / 2, 63, -1.52, 71, 32, fill=(127, 205, 73, 255), line_width=2.6)
    draw_line(draw, [(w / 2, 34), (w / 2, 96)], fill=LEAF_DARK, width=2.0)


def draw_pollution(draw: ImageDraw.ImageDraw, w: int, h: int, warning: bool = False) -> None:
    draw_blob(draw, w * 0.5, h * 0.55, w * 0.36, h * 0.32, PURPLE_DARK, seed=f"pollution-{w}-{warning}", width=max(3.0, w * 0.04), wobble=0.14)
    draw_blob(draw, w * 0.5, h * 0.54, w * 0.23, h * 0.2, PURPLE, seed=f"pollution-core-{w}", width=max(2.1, w * 0.026), wobble=0.09)
    ellipse(draw, (w * 0.38, h * 0.43, w * 0.62, h * 0.65), fill=(230, 55, 219, 255), outline=INK, width=max(1.8, w * 0.02))
    ellipse(draw, (w * 0.45, h * 0.49, w * 0.55, h * 0.59), fill=(255, 233, 249, 255), outline=(0, 0, 0, 0), width=0.1)
    for i, a in enumerate([0.1, 1.15, 2.6, 3.8, 5.2]):
        x = w * 0.5 + math.cos(a) * w * 0.36
        y = h * 0.5 + math.sin(a) * h * 0.32
        ellipse(draw, (x - w * 0.035, y - w * 0.035, x + w * 0.035, y + w * 0.035), fill=(122, 238, 47, 255), outline=INK, width=1.1)
    if warning:
        draw_line(draw, [(w * 0.5, h * 0.18), (w * 0.5, h * 0.38)], fill=GOLD_LIGHT, width=w * 0.055)
        ellipse(draw, (w * 0.47, h * 0.43, w * 0.53, h * 0.49), fill=GOLD_LIGHT, outline=INK, width=1.0)


def draw_flame_icon(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    outer = [(w * 0.48, h * 0.09), (w * 0.68, h * 0.36), (w * 0.61, h * 0.76), (w * 0.38, h * 0.88), (w * 0.21, h * 0.57)]
    poly(draw, outer, fill=(238, 70, 24, 255), outline=INK, width=w * 0.035)
    inner = [(w * 0.49, h * 0.26), (w * 0.58, h * 0.49), (w * 0.53, h * 0.72), (w * 0.37, h * 0.74), (w * 0.39, h * 0.49)]
    poly(draw, inner, fill=(255, 203, 54, 255), outline=(0, 0, 0, 0), width=0.1)
    draw_potato(draw, w, h, w * 0.47, h * 0.56, w * 0.19, h * 0.24, "burning")


def draw_vortex(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    for i, color in enumerate([(39, 126, 34, 255), (84, 216, 57, 255), (224, 243, 79, 255)]):
        radius = w * (0.32 - i * 0.055)
        bbox = (w * 0.5 - radius, h * 0.5 - radius, w * 0.5 + radius, h * 0.5 + radius)
        draw.arc(box(bbox), start=25 + i * 45, end=325 + i * 45, fill=color, width=lw(w * 0.085))
    ellipse(draw, (w * 0.38, h * 0.38, w * 0.62, h * 0.62), fill=(58, 163, 42, 255), outline=INK, width=w * 0.025)
    for a in [0.35, 1.9, 3.6, 5.1]:
        draw_leaf(draw, w * 0.5 + math.cos(a) * w * 0.33, h * 0.5 + math.sin(a) * h * 0.33, a, w * 0.16, w * 0.075, fill=LEAF_LIGHT, line_width=1.1)


def draw_frost(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    cx, cy = w / 2, h / 2
    for a in [0, math.pi / 3, 2 * math.pi / 3]:
        dx, dy = math.cos(a), math.sin(a)
        draw_line(draw, [(cx - dx * w * 0.34, cy - dy * h * 0.34), (cx + dx * w * 0.34, cy + dy * h * 0.34)], fill=INK, width=w * 0.06)
        draw_line(draw, [(cx - dx * w * 0.31, cy - dy * h * 0.31), (cx + dx * w * 0.31, cy + dy * h * 0.31)], fill=BLUE_LIGHT, width=w * 0.037)
    draw_crystal(draw, cx, cy, w * 0.44, h * 0.62, fill=(160, 232, 255, 255), accent=BLUE_LIGHT)


def draw_poison(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    values = [(w * 0.5, h * 0.08), (w * 0.76, h * 0.48), (w * 0.63, h * 0.86), (w * 0.37, h * 0.86), (w * 0.24, h * 0.48)]
    poly(draw, values, fill=(92, 205, 43, 255), outline=INK, width=w * 0.04)
    ellipse(draw, (w * 0.34, h * 0.41, w * 0.66, h * 0.68), fill=(34, 96, 31, 255), outline=INK, width=w * 0.025)
    ellipse(draw, (w * 0.39, h * 0.48, w * 0.47, h * 0.58), fill=INK, outline=INK, width=0.1)
    ellipse(draw, (w * 0.53, h * 0.48, w * 0.61, h * 0.58), fill=INK, outline=INK, width=0.1)
    draw_line(draw, [(w * 0.44, h * 0.65), (w * 0.56, h * 0.65)], fill=INK, width=w * 0.025)


def draw_shield(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    values = [(w * 0.5, h * 0.08), (w * 0.82, h * 0.22), (w * 0.74, h * 0.7), (w * 0.5, h * 0.9), (w * 0.26, h * 0.7), (w * 0.18, h * 0.22)]
    poly(draw, values, fill=GOLD, outline=INK, width=w * 0.04)
    inner = [(w * 0.5, h * 0.17), (w * 0.71, h * 0.28), (w * 0.65, h * 0.64), (w * 0.5, h * 0.78), (w * 0.35, h * 0.64), (w * 0.29, h * 0.28)]
    poly(draw, inner, fill=BLUE_LIGHT, outline=BLUE, width=w * 0.025)


def draw_haste(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_leaf(draw, w * 0.47, h * 0.5, -0.75, w * 0.62, w * 0.25, fill=(111, 205, 81, 255), line_width=w * 0.035)
    for y in [0.35, 0.5, 0.65]:
        draw_line(draw, [(w * 0.12, h * y), (w * 0.36, h * (y - 0.06))], fill=BLUE_LIGHT, width=w * 0.025)
    draw_sprout(draw, w * 0.56, h * 0.28, w * 0.26)


def draw_healing(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_heart(draw, w * 0.5, h * 0.38, w * 0.48, fill=RED)
    draw_leaf(draw, w * 0.35, h * 0.72, 2.65, w * 0.43, w * 0.16, fill=LEAF_LIGHT, line_width=w * 0.026)
    draw_leaf(draw, w * 0.65, h * 0.72, 0.5, w * 0.43, w * 0.16, fill=LEAF, line_width=w * 0.026)


def draw_bruise(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_blob(draw, w * 0.5, h * 0.53, w * 0.31, h * 0.27, PURPLE, seed="bruise", width=w * 0.04, wobble=0.16)
    draw_blob(draw, w * 0.52, h * 0.55, w * 0.18, h * 0.16, (83, 32, 101, 255), seed="bruise-core", outline=(0, 0, 0, 0), width=0.1, wobble=0.12)
    draw_line(draw, [(w * 0.43, h * 0.42), (w * 0.5, h * 0.5), (w * 0.46, h * 0.58), (w * 0.57, h * 0.68)], fill=INK, width=w * 0.025)


def draw_stun(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    for cx, cy, a in [(w * 0.35, h * 0.56, 2.55), (w * 0.65, h * 0.56, 0.6)]:
        draw_leaf(draw, cx, cy, a, w * 0.42, w * 0.16, fill=(104, 178, 54, 255), line_width=w * 0.03)
    draw_line(draw, [(w * 0.34, h * 0.74), (w * 0.66, h * 0.74)], fill=INK_SOFT, width=w * 0.045)
    for cx, cy in [(w * 0.38, h * 0.25), (w * 0.58, h * 0.2), (w * 0.67, h * 0.36)]:
        draw_star(draw, cx, cy, w * 0.09, w * 0.04, fill=GOLD_LIGHT, outline=INK, width=w * 0.012)


def draw_bamboo(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    for angle in [0.72, -0.72]:
        cx, cy = w * 0.5, h * 0.52
        dx, dy = math.cos(angle), math.sin(angle)
        px, py = -dy, dx
        length = w * 0.78
        width = w * 0.11
        points = [
            (cx - dx * length / 2 + px * width / 2, cy - dy * length / 2 + py * width / 2),
            (cx + dx * length / 2 + px * width / 2, cy + dy * length / 2 + py * width / 2),
            (cx + dx * length / 2 - px * width / 2, cy + dy * length / 2 - py * width / 2),
            (cx - dx * length / 2 - px * width / 2, cy - dy * length / 2 - py * width / 2),
        ]
        poly(draw, points, fill=(111, 191, 47, 255), outline=INK, width=w * 0.027)
        for t in [-0.25, 0.0, 0.25]:
            x = cx + dx * length * t
            y = cy + dy * length * t
            draw_line(draw, [(x - px * width * 0.52, y - py * width * 0.52), (x + px * width * 0.52, y + py * width * 0.52)], fill=LEAF_DARK, width=w * 0.018)


def draw_garlic(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_blob(draw, w * 0.5, h * 0.54, w * 0.32, h * 0.32, (239, 207, 205, 255), seed="garlic", width=w * 0.04, wobble=0.1)
    draw_blob(draw, w * 0.5, h * 0.65, w * 0.35, h * 0.14, PURPLE_DARK, seed="garlic-mask", width=w * 0.025, wobble=0.08)
    draw_line(draw, [(w * 0.39, h * 0.26), (w * 0.32, h * 0.15)], fill=INK, width=w * 0.036)
    draw_line(draw, [(w * 0.57, h * 0.25), (w * 0.66, h * 0.14)], fill=INK, width=w * 0.036)
    ellipse(draw, (w * 0.41, h * 0.54, w * 0.48, h * 0.61), fill=INK, outline=INK, width=0.1)
    ellipse(draw, (w * 0.54, h * 0.54, w * 0.61, h * 0.61), fill=INK, outline=INK, width=0.1)


def draw_alchemy_flower(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    ellipse(draw, (w * 0.3, h * 0.58, w * 0.7, h * 0.86), fill=(41, 174, 141, 255), outline=INK, width=w * 0.03)
    draw_line(draw, [(w * 0.5, h * 0.68), (w * 0.5, h * 0.38)], fill=LEAF_DARK, width=w * 0.04)
    for a in [0, math.tau / 5, 2 * math.tau / 5, 3 * math.tau / 5, 4 * math.tau / 5]:
        draw_leaf(draw, w * 0.5 + math.cos(a) * w * 0.1, h * 0.33 + math.sin(a) * h * 0.08, a, w * 0.25, w * 0.11, fill=(174, 90, 224, 255), line_width=w * 0.022)
    ellipse(draw, (w * 0.44, h * 0.28, w * 0.56, h * 0.4), fill=GOLD_LIGHT, outline=INK, width=w * 0.015)


def draw_potato_enhancement(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_potato(draw, w, h, w * 0.5, h * 0.54, w * 0.29, h * 0.36, "enhance")
    ellipse(draw, (w * 0.36, h * 0.39, w * 0.64, h * 0.66), fill=GOLD, outline=INK, width=w * 0.03)
    draw_sprout(draw, w * 0.5, h * 0.51, w * 0.22)


def draw_thorn_charm(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_potato(draw, w, h, w * 0.52, h * 0.56, w * 0.22, h * 0.29, "thorn")
    draw_line(draw, [(w * 0.42, h * 0.24), (w * 0.6, h * 0.12), (w * 0.74, h * 0.21)], fill=BLUE, width=w * 0.04)
    for a in [0.15, 2.7, -1.4]:
        draw_leaf(draw, w * 0.5 + math.cos(a) * w * 0.23, h * 0.55 + math.sin(a) * h * 0.22, a, w * 0.17, w * 0.08, fill=LEAF, line_width=w * 0.017)


def draw_fusion(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_crystal(draw, w * 0.5, h * 0.6, w * 0.26, h * 0.34, fill=(214, 65, 255, 255), accent=(95, 220, 255, 255))
    draw_leaf(draw, w * 0.32, h * 0.34, -2.18, w * 0.45, w * 0.16, fill=(255, 91, 38, 255), line_width=w * 0.028)
    draw_leaf(draw, w * 0.68, h * 0.34, -0.95, w * 0.45, w * 0.16, fill=(79, 213, 255, 255), line_width=w * 0.028)
    draw.arc(box((w * 0.19, h * 0.22, w * 0.81, h * 0.88)), start=205, end=340, fill=BLUE_LIGHT, width=lw(w * 0.025))


def draw_upgrade(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    rounded(draw, (w * 0.22, h * 0.64, w * 0.72, h * 0.84), w * 0.04, fill=GRAY_DARK, outline=INK, width=w * 0.035)
    poly(draw, [(w * 0.28, h * 0.61), (w * 0.68, h * 0.61), (w * 0.58, h * 0.73), (w * 0.36, h * 0.73)], fill=GRAY, outline=INK, width=w * 0.03)
    draw_line(draw, [(w * 0.55, h * 0.25), (w * 0.76, h * 0.51)], fill=(119, 66, 37, 255), width=w * 0.075)
    rounded(draw, (w * 0.31, h * 0.14, w * 0.6, h * 0.35), w * 0.05, fill=(83, 79, 78, 255), outline=INK, width=w * 0.035)
    for cx, cy in [(w * 0.2, h * 0.48), (w * 0.78, h * 0.68)]:
        draw_star(draw, cx, cy, w * 0.055, w * 0.025, fill=GOLD_LIGHT, outline=(0, 0, 0, 0), width=0.1)


def draw_gold_stack(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_coin(draw, w * 0.35, h * 0.63, w * 0.19, tilt=0.3)
    draw_coin(draw, w * 0.52, h * 0.52, w * 0.2, tilt=0.2)
    draw_coin(draw, w * 0.65, h * 0.66, w * 0.19, tilt=-0.2)
    draw_star(draw, w * 0.75, h * 0.28, w * 0.055, w * 0.025, fill=GOLD_LIGHT, outline=(0, 0, 0, 0), width=0.1)


def draw_clover(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    for cx, cy in [(0.41, 0.39), (0.59, 0.39), (0.4, 0.58), (0.58, 0.58)]:
        draw_heart(draw, w * cx, h * cy, w * 0.23, fill=(120, 190, 50, 255))
    draw_line(draw, [(w * 0.51, h * 0.58), (w * 0.67, h * 0.83)], fill=LEAF_DARK, width=w * 0.035)
    ellipse(draw, (w * 0.45, h * 0.47, w * 0.57, h * 0.59), fill=LEAF_DARK, outline=INK, width=w * 0.012)


def draw_legendary(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    for dx, dy, ww, hh in [(-0.18, 0.07, 0.26, 0.53), (0.13, 0.06, 0.28, 0.58), (0.0, -0.06, 0.28, 0.7)]:
        draw_crystal(draw, w * (0.5 + dx), h * (0.52 + dy), w * ww, h * hh, fill=GOLD_LIGHT, accent=GOLD)
    draw_line(draw, [(w * 0.2, h * 0.84), (w * 0.8, h * 0.84)], fill=PURPLE_DARK, width=w * 0.035)


def draw_reroll(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_potato(draw, w, h, w * 0.39, h * 0.52, w * 0.17, h * 0.28, "reroll-a")
    draw_blob(draw, w * 0.62, h * 0.55, w * 0.17, h * 0.28, (112, 196, 76, 255), seed="reroll-b", width=w * 0.03, wobble=0.08)
    draw.arc(box((w * 0.19, h * 0.2, w * 0.82, h * 0.84)), start=205, end=325, fill=INK, width=lw(w * 0.04))
    draw.arc(box((w * 0.19, h * 0.2, w * 0.82, h * 0.84)), start=25, end=145, fill=RED, width=lw(w * 0.03))
    poly(draw, [(w * 0.78, h * 0.3), (w * 0.87, h * 0.29), (w * 0.81, h * 0.4)], fill=RED, outline=INK, width=w * 0.015)


def draw_fries(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    rounded(draw, (w * 0.43, h * 0.08, w * 0.57, h * 0.87), w * 0.06, fill=GOLD_LIGHT, outline=INK, width=w * 0.035)
    draw_line(draw, [(w * 0.49, h * 0.15), (w * 0.43, h * 0.68)], fill=(255, 245, 148, 180), width=w * 0.02)
    for y in [0.23, 0.5, 0.73]:
        draw_line(draw, [(w * 0.45, h * y), (w * 0.55, h * (y + 0.02))], fill=(189, 105, 26, 150), width=w * 0.012)


def draw_fries_slash(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    values = [(w * 0.14, h * 0.67), (w * 0.35, h * 0.42), (w * 0.72, h * 0.21), (w * 0.58, h * 0.42), (w * 0.85, h * 0.36), (w * 0.48, h * 0.58), (w * 0.22, h * 0.8)]
    poly(draw, values, fill=(255, 167, 25, 255), outline=INK, width=w * 0.024)
    draw_line(draw, [(w * 0.24, h * 0.63), (w * 0.67, h * 0.36)], fill=(255, 237, 79, 220), width=w * 0.04)


def draw_heavy_slam(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_upgrade(draw, w, h)
    draw_line(draw, [(w * 0.22, h * 0.86), (w * 0.78, h * 0.86)], fill=(255, 94, 28, 210), width=w * 0.04)
    for cx in [0.28, 0.5, 0.72]:
        draw_line(draw, [(w * cx, h * 0.91), (w * (cx + 0.06), h * 0.98)], fill=GOLD_LIGHT, width=w * 0.018)


def draw_forbidden(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    ellipse(draw, (w * 0.12, h * 0.12, w * 0.88, h * 0.88), fill=(52, 45, 55, 230), outline=INK, width=w * 0.055)
    draw_line(draw, [(w * 0.24, h * 0.23), (w * 0.77, h * 0.78)], fill=RED, width=w * 0.12)
    draw_line(draw, [(w * 0.24, h * 0.23), (w * 0.77, h * 0.78)], fill=INK, width=w * 0.035)


def draw_burst(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    values = []
    for i in range(20):
        r = (w * 0.42 if i % 2 == 0 else w * 0.18) * (1.0 + (0.12 if i in (3, 9, 14) else 0.0))
        a = -math.pi / 2 + i * math.tau / 20
        values.append((w * 0.5 + math.cos(a) * r, h * 0.48 + math.sin(a) * r))
    poly(draw, values, fill=(255, 236, 101, 210), outline=INK, width=w * 0.022)
    draw_blob(draw, w * 0.5, h * 0.48, w * 0.18, h * 0.12, (255, 91, 67, 230), seed="burst", width=w * 0.015, wobble=0.12)


def draw_loss_glow(draw: ImageDraw.ImageDraw, w: int, h: int, boss: bool) -> None:
    color = (255, 78, 30, 170) if boss else (74, 255, 96, 165)
    accent = GOLD_LIGHT if boss else (134, 255, 120, 220)
    draw_line(draw, [(3, h * 0.55), (w * 0.25, h * 0.42), (w * 0.75, h * 0.43), (w - 3, h * 0.56)], fill=INK, width=h * 0.22)
    draw_line(draw, [(4, h * 0.55), (w * 0.25, h * 0.42), (w * 0.75, h * 0.43), (w - 4, h * 0.56)], fill=color, width=h * 0.16)
    draw_line(draw, [(w * 0.1, h * 0.52), (w * 0.88, h * 0.48)], fill=accent, width=h * 0.07)


def draw_shop_item(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    rounded(draw, (w * 0.23, h * 0.3, w * 0.72, h * 0.76), w * 0.08, fill=(130, 77, 37, 255), outline=INK, width=w * 0.035)
    rounded(draw, (w * 0.35, h * 0.18, w * 0.59, h * 0.38), w * 0.08, fill=(106, 60, 34, 255), outline=INK, width=w * 0.025)
    draw_sprout(draw, w * 0.45, h * 0.43, w * 0.18)
    ellipse(draw, (w * 0.66, h * 0.54, w * 0.82, h * 0.76), fill=(199, 214, 164, 255), outline=INK, width=w * 0.02)


def draw_shop_magic(draw: ImageDraw.ImageDraw, w: int, h: int, master: bool = False) -> None:
    if master:
        draw_crystal(draw, w * 0.5, h * 0.45, w * 0.35, h * 0.5, fill=(94, 255, 90, 255), accent=(47, 135, 67, 255))
        draw_leaf(draw, w * 0.31, h * 0.66, 2.4, w * 0.35, w * 0.14, fill=LEAF, line_width=w * 0.022)
        draw_leaf(draw, w * 0.7, h * 0.66, 0.7, w * 0.35, w * 0.14, fill=LEAF_LIGHT, line_width=w * 0.022)
    else:
        rounded(draw, (w * 0.22, h * 0.24, w * 0.78, h * 0.8), w * 0.06, fill=(119, 75, 37, 255), outline=INK, width=w * 0.035)
        draw_crystal(draw, w * 0.5, h * 0.5, w * 0.26, h * 0.36, fill=(94, 255, 90, 255), accent=(47, 135, 67, 255))
        draw_line(draw, [(w * 0.28, h * 0.24), (w * 0.72, h * 0.24)], fill=GOLD_LIGHT, width=w * 0.03)


def draw_shop_weapon(draw: ImageDraw.ImageDraw, w: int, h: int, master: bool = False) -> None:
    if master:
        draw_heavy_slam(draw, w, h)
    else:
        rounded(draw, (w * 0.19, h * 0.3, w * 0.78, h * 0.75), w * 0.06, fill=WOOD, outline=INK, width=w * 0.035)
        draw_fries(draw, w, h)
        draw_line(draw, [(w * 0.32, h * 0.42), (w * 0.66, h * 0.64)], fill=INK_SOFT, width=w * 0.035)


def draw_button_refresh(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    draw_reroll(draw, w, h)


def draw_button_panel(draw: ImageDraw.ImageDraw, w: int, h: int, kind: str) -> None:
    draw_panel_wood(draw, w, h, "wide" if kind == "center" else "button")
    if kind == "left":
        poly(draw, [(w * 0.4, h * 0.5), (w * 0.58, h * 0.38), (w * 0.58, h * 0.62)], fill=PARCHMENT, outline=INK, width=2.2)
    elif kind == "right":
        poly(draw, [(w * 0.6, h * 0.5), (w * 0.42, h * 0.38), (w * 0.42, h * 0.62)], fill=PARCHMENT, outline=INK, width=2.2)


def draw_source_crop(stem: str, w: int, h: int) -> Image.Image | None:
    source_map = {
        "character_potato_hero": "potato_hero_idle.png",
        "monster_sprouting_potato": "sprouting_potato.png",
        "monster_mushroom_spore": "mushroom_spore.png",
        "monster_bomb_fruitling": "bomb_fruitling.png",
    }
    name = source_map.get(stem)
    if not name:
        return None
    source = Image.open(STYLE_DIR / name).convert("RGBA")
    frame_w = source.width // 2
    frame_h = source.height // 2
    crop = source.crop((0, 0, frame_w, frame_h))
    bbox = crop.getchannel("A").getbbox()
    if bbox:
        crop = crop.crop(bbox)
    max_w, max_h = int(w * SCALE * 0.9), int(h * SCALE * 0.9)
    scale = min(max_w / crop.width, max_h / crop.height)
    resized = crop.resize((max(1, int(crop.width * scale)), max(1, int(crop.height * scale))), Image.Resampling.LANCZOS)
    img = Image.new("RGBA", (w * SCALE, h * SCALE), (0, 0, 0, 0))
    img.alpha_composite(resized, ((img.width - resized.width) // 2, (img.height - resized.height) // 2))
    return img


def draw_asset(stem: str, w: int, h: int) -> tuple[Image.Image, str]:
    crop = draw_source_crop(stem, w, h)
    if crop is not None:
        return crop, "style-preview-crop"

    img, draw = make_canvas(w, h)
    key = stem[3:] if stem.startswith("ui_") else stem

    if key == "boss_demo_pollution_source":
        draw_pollution(draw, w, h, warning=False)
    elif key == "boss_pollution_source_warning":
        draw_pollution(draw, w, h, warning=True)
    elif key == "buff_bruise":
        draw_bruise(draw, w, h)
    elif key == "buff_burning":
        draw_flame_icon(draw, w, h)
    elif key in {"buff_comprehensive_development", "magic_comprehensive_development"}:
        draw_vortex(draw, w, h)
    elif key == "buff_frost":
        draw_frost(draw, w, h)
    elif key == "buff_haste":
        draw_haste(draw, w, h)
    elif key == "buff_healing_sprout":
        draw_healing(draw, w, h)
    elif key == "buff_poison":
        draw_poison(draw, w, h)
    elif key in {"buff_potato_enhancement", "item_potato_enhancement"}:
        draw_potato_enhancement(draw, w, h)
    elif key == "buff_shield":
        draw_shield(draw, w, h)
    elif key == "buff_stun":
        draw_stun(draw, w, h)
    elif key == "item_alchemy_flower":
        draw_alchemy_flower(draw, w, h)
    elif key == "item_assassin_garlic":
        draw_garlic(draw, w, h)
    elif key == "item_battle_bamboo":
        draw_bamboo(draw, w, h)
    elif key == "item_thorn_potato_charm":
        draw_thorn_charm(draw, w, h)
    elif key == "reward_free_fusion":
        draw_fusion(draw, w, h)
    elif key == "reward_free_upgrade":
        draw_upgrade(draw, w, h)
    elif key in {"reward_gold_bonus", "currency_gold"}:
        draw_gold_stack(draw, w, h)
    elif key == "reward_legendary_choice":
        draw_legendary(draw, w, h)
    elif key == "reward_luck_clover":
        draw_clover(draw, w, h)
    elif key == "reward_reroll":
        draw_reroll(draw, w, h)
    elif key == "card_common_frame":
        draw_square_frame(draw, img, w, h, "common")
    elif key == "card_legendary_frame":
        draw_square_frame(draw, img, w, h, "legendary")
    elif key == "card_rare_frame":
        draw_square_frame(draw, img, w, h, "rare")
    elif key == "cursor_select":
        draw_cursor(draw, w, h)
    elif key == "panel_wood_small":
        draw_panel_wood(draw, w, h, "small")
    elif key == "panel_wood_wide":
        draw_panel_wood(draw, w, h, "wide")
    elif key == "weapon_fries":
        draw_fries(draw, w, h)
    elif key == "weapon_fries_slash":
        draw_fries_slash(draw, w, h)
    elif key == "weapon_skill_heavy_fries_slam":
        draw_heavy_slam(draw, w, h)
    elif key == "button_center":
        draw_button_panel(draw, w, h, "center")
    elif key == "button_left":
        draw_button_panel(draw, w, h, "left")
    elif key == "button_right":
        draw_button_panel(draw, w, h, "right")
    elif key == "button_fusion":
        draw_fusion(draw, w, h)
    elif key == "button_refresh":
        draw_button_refresh(draw, w, h)
    elif key == "button_upgrade":
        draw_upgrade(draw, w, h)
    elif key == "combat_boss_hp_frame":
        draw_bar_frame(draw, img, w, h, "boss")
    elif key == "combat_boss_loss_glow":
        draw_loss_glow(draw, w, h, boss=True)
    elif key == "combat_cast_forbidden":
        draw_forbidden(draw, w, h)
    elif key == "combat_damage_burst":
        draw_burst(draw, w, h)
    elif key == "combat_hp_frame":
        draw_slot(draw, img, w, h, "weapon")
        draw_heart(draw, w * 0.5, h * 0.47, min(w, h) * 0.32, fill=(141, 206, 61, 255))
    elif key == "combat_hp_frame_slim":
        draw_bar_frame(draw, img, w, h, "hp")
    elif key == "combat_magic_slot":
        draw_magic_slot(draw, img, w, h, disabled=False)
    elif key == "combat_magic_slot_disabled":
        draw_magic_slot(draw, img, w, h, disabled=True)
    elif key == "combat_mana_frame":
        draw_bar_frame(draw, img, w, h, "mana")
    elif key == "combat_player_loss_glow":
        draw_loss_glow(draw, w, h, boss=False)
    elif key == "health_badge":
        draw_health_badge(draw, w, h)
    elif key == "mana_badge":
        draw_mana_badge(draw, w, h)
    elif key == "shop_item":
        draw_shop_item(draw, w, h)
    elif key == "shop_magic":
        draw_shop_magic(draw, w, h, master=False)
    elif key == "shop_magic_master":
        draw_shop_magic(draw, w, h, master=True)
    elif key == "shop_weapon":
        draw_shop_weapon(draw, w, h, master=False)
    elif key == "shop_weapon_master":
        draw_shop_weapon(draw, w, h, master=True)
    elif key == "slot_disabled":
        draw_slot(draw, img, w, h, "disabled")
    elif key == "slot_magic":
        draw_slot(draw, img, w, h, "magic")
    elif key == "slot_weapon":
        draw_slot(draw, img, w, h, "weapon")
    else:
        draw_banner(draw, w / 2, h / 2, w * 0.7, h * 0.36)
        draw_sprout(draw, w / 2, h * 0.48, min(w, h) * 0.22)
        return img, "fallback-procedural"

    return img, "procedural-cel-redraw"


def asset_prompt(stem: str, method: str) -> str:
    base = (
        "Handdrawn cel game UI/icon replacement, thick black ink outline, smooth simple shapes, "
        "warm potato-game palette, sparse cel highlights, transparent background, no text, no watermark. "
        "Style anchor: assets/art/style_preview/handdrawn_cel_v01 with simple Cuphead-like animation energy "
        "and Potato-Brother-simple subjects."
    )
    if method == "style-preview-crop":
        return base + f" Source-crop the matching handdrawn preview frame for {stem}, keeping the transparent alpha."
    return base + f" Redraw {stem} as a readable prop-like UI asset, avoiding modern flat UI and avoiding complex humanoid detail."


def checksum(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:16]


def alpha_stats(img: Image.Image) -> dict:
    alpha = img.getchannel("A")
    data = alpha.getdata()
    total = img.width * img.height
    opaque = sum(1 for v in data if v == 255)
    transparent = sum(1 for v in data if v == 0)
    return {
        "alpha_extrema": list(alpha.getextrema()),
        "bbox": list(alpha.getbbox() or []),
        "opaque_pixels": opaque,
        "transparent_pixels": transparent,
        "partial_alpha_pixels": total - opaque - transparent,
        "corner_alpha": [
            alpha.getpixel((0, 0)),
            alpha.getpixel((img.width - 1, 0)),
            alpha.getpixel((0, img.height - 1)),
            alpha.getpixel((img.width - 1, img.height - 1)),
        ],
    }


def make_sheet(files: list[Path], out_path: Path, cell: int = 150, label_h: int = 36) -> None:
    cols = 5
    rows = (len(files) + cols - 1) // cols
    out = Image.new("RGB", (cols * cell, rows * (cell + label_h)), (235, 230, 220))
    d = ImageDraw.Draw(out)
    for i, path in enumerate(files):
        x = (i % cols) * cell
        y = (i // cols) * (cell + label_h)
        tile = 12
        for yy in range(y, y + cell, tile):
            for xx in range(x, x + cell, tile):
                color = (214, 214, 214) if ((xx - x) // tile + (yy - y) // tile) % 2 == 0 else (242, 242, 242)
                d.rectangle([xx, yy, min(xx + tile - 1, x + cell - 1), min(yy + tile - 1, y + cell - 1)], fill=color)
        src = Image.open(path).convert("RGBA")
        max_side = cell - 18
        scale = min(max_side / src.width, max_side / src.height)
        disp = src.resize((max(1, int(src.width * scale)), max(1, int(src.height * scale))), Image.Resampling.NEAREST)
        px = x + (cell - disp.width) // 2
        py = y + (cell - disp.height) // 2
        out.paste(disp.convert("RGB"), (px, py), disp.getchannel("A"))
        d.text((x + 4, y + cell + 4), path.stem[:22], fill=(30, 30, 30))
        d.text((x + 4, y + cell + 18), f"{src.width}x{src.height}", fill=(70, 70, 70))
    out.save(out_path)


def collect_targets() -> list[Path]:
    return sorted((ART / "icons").glob("*.png")) + sorted((ART / "ui").glob("*.png"))


def main() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    MASTER_DIR.mkdir(parents=True, exist_ok=True)
    (MASTER_DIR / "icons").mkdir(parents=True, exist_ok=True)
    (MASTER_DIR / "ui").mkdir(parents=True, exist_ok=True)

    before: dict[str, dict] = {}
    for path in collect_targets():
        img = Image.open(path).convert("RGBA")
        before[path.as_posix()] = {
            "size": [img.width, img.height],
            "mode": img.mode,
            **alpha_stats(img),
        }

    changed = []
    prompts = []
    for path in collect_targets():
        folder = path.parent.name
        original = Image.open(path).convert("RGBA")
        w, h = original.size
        hi, method = draw_asset(path.stem, w, h)
        final = hi.resize((w, h), Image.Resampling.LANCZOS).convert("RGBA")
        master_path = MASTER_DIR / folder / path.name
        hi.save(master_path)
        final.save(path)
        prompt = asset_prompt(path.stem, method)
        prompts.append(
            {
                "path": path.relative_to(REPO).as_posix(),
                "master": master_path.relative_to(REPO).as_posix(),
                "method": method,
                "prompt": prompt,
            }
        )
        changed.append(path)

    after = {}
    failures = []
    for path in collect_targets():
        img = Image.open(path).convert("RGBA")
        key = path.as_posix()
        stats = {
            "size": [img.width, img.height],
            "mode": img.mode,
            **alpha_stats(img),
            "sha256_16": checksum(path),
        }
        after[key] = stats
        if stats["size"] != before[key]["size"]:
            failures.append({"path": path.relative_to(REPO).as_posix(), "reason": "size changed"})
        if stats["mode"] != "RGBA":
            failures.append({"path": path.relative_to(REPO).as_posix(), "reason": "not RGBA"})
        if stats["alpha_extrema"][0] != 0 or stats["alpha_extrema"][1] != 255:
            failures.append({"path": path.relative_to(REPO).as_posix(), "reason": "alpha does not contain both transparent and opaque pixels"})

    make_sheet(sorted((ART / "icons").glob("*.png")), SOURCE_DIR / "audit_after_icons.png")
    make_sheet(sorted((ART / "ui").glob("*.png")), SOURCE_DIR / "audit_after_ui.png")

    (SOURCE_DIR / "prompt_manifest.json").write_text(json.dumps(prompts, indent=2), encoding="utf-8")
    (SOURCE_DIR / "validation_report.json").write_text(
        json.dumps(
            {
                "style_anchor": "assets/art/style_preview/handdrawn_cel_v01",
                "changed_count": len(changed),
                "skipped": [],
                "failures": failures,
                "before": before,
                "after": after,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (SOURCE_DIR / "changed_files.txt").write_text(
        "\n".join(path.relative_to(REPO).as_posix() for path in changed) + "\n",
        encoding="utf-8",
    )

    print(json.dumps({"changed_count": len(changed), "failures": failures}, indent=2))


if __name__ == "__main__":
    main()
