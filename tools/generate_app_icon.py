from __future__ import annotations

import json
import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "CETWords" / "Assets.xcassets" / "AppIcon.appiconset"


def clamp(value: float) -> int:
    return max(0, min(255, int(round(value))))


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(clamp(a[i] * (1 - t) + b[i] * t) for i in range(3))


def rounded_rect_alpha(x: float, y: float, w: float, h: float, r: float) -> float:
    px = abs(x - w / 2) - w / 2 + r
    py = abs(y - h / 2) - h / 2 + r
    outside = math.hypot(max(px, 0), max(py, 0))
    inside = min(max(px, py), 0)
    distance = outside + inside - r
    return max(0.0, min(1.0, 0.5 - distance))


def circle_alpha(x: float, y: float, cx: float, cy: float, radius: float) -> float:
    distance = math.hypot(x - cx, y - cy) - radius
    return max(0.0, min(1.0, 0.5 - distance))


def write_png(path: Path, width: int, height: int, rgba: bytearray) -> None:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
        )

    rows = bytearray()
    stride = width * 4
    for y in range(height):
        rows.append(0)
        rows.extend(rgba[y * stride : (y + 1) * stride])

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(rows), 9))
        + chunk(b"IEND", b"")
    )


def draw_icon(size: int) -> bytearray:
    scale = 4
    canvas_size = size * scale
    rgba = bytearray(canvas_size * canvas_size * 4)
    top = (76, 93, 255)
    bottom = (37, 56, 140)
    accent = (20, 198, 170)

    for y in range(canvas_size):
        for x in range(canvas_size):
            nx = x / (canvas_size - 1)
            ny = y / (canvas_size - 1)
            base = mix(top, bottom, ny)
            glow = circle_alpha(x, y, canvas_size * 0.78, canvas_size * 0.2, canvas_size * 0.32)
            color = mix(base, accent, glow * 0.28)
            i = (y * canvas_size + x) * 4
            rgba[i : i + 4] = bytes((*color, 255))

    card_w = canvas_size * 0.68
    card_h = canvas_size * 0.5
    card_x = (canvas_size - card_w) / 2
    card_y = canvas_size * 0.24
    radius = canvas_size * 0.09

    for y in range(canvas_size):
        for x in range(canvas_size):
            alpha = rounded_rect_alpha(x - card_x, y - card_y, card_w, card_h, radius)
            if alpha <= 0:
                continue
            shadow = rounded_rect_alpha(x - card_x, y - card_y + canvas_size * 0.035, card_w, card_h, radius)
            i = (y * canvas_size + x) * 4
            if shadow > 0:
                rgba[i : i + 3] = bytes(mix(tuple(rgba[i : i + 3]), (0, 0, 0), shadow * 0.16))
            rgba[i : i + 3] = bytes(mix(tuple(rgba[i : i + 3]), (255, 255, 255), alpha * 0.94))

    # Three clean "word lines" on the card.
    line_specs = [
        (0.28, 0.62, 0.08, (49, 62, 151)),
        (0.44, 0.46, 0.052, (118, 128, 176)),
        (0.56, 0.34, 0.052, (118, 128, 176)),
    ]
    for rel_y, rel_w, rel_h, color in line_specs:
        w = card_w * rel_w
        h = card_h * rel_h
        x0 = card_x + card_w * 0.19
        y0 = card_y + card_h * rel_y
        for y in range(int(y0 - h / 2), int(y0 + h / 2)):
            for x in range(int(x0), int(x0 + w)):
                if 0 <= x < canvas_size and 0 <= y < canvas_size:
                    alpha = rounded_rect_alpha(x - x0, y - (y0 - h / 2), w, h, h / 2)
                    if alpha > 0:
                        i = (y * canvas_size + x) * 4
                        rgba[i : i + 3] = bytes(mix(tuple(rgba[i : i + 3]), color, alpha))

    # A small check mark for "remembered".
    check_color = (23, 176, 132)
    points = [
        (canvas_size * 0.61, canvas_size * 0.55),
        (canvas_size * 0.68, canvas_size * 0.62),
        (canvas_size * 0.79, canvas_size * 0.45),
    ]
    thickness = canvas_size * 0.035
    for y in range(canvas_size):
        for x in range(canvas_size):
            best = 10**9
            for a, b in zip(points, points[1:]):
                ax, ay = a
                bx, by = b
                dx, dy = bx - ax, by - ay
                t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
                best = min(best, math.hypot(x - (ax + t * dx), y - (ay + t * dy)))
            alpha = max(0.0, min(1.0, 1 - best / thickness))
            if alpha > 0:
                i = (y * canvas_size + x) * 4
                rgba[i : i + 3] = bytes(mix(tuple(rgba[i : i + 3]), check_color, alpha))

    # Downsample for smooth edges.
    out = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            sums = [0, 0, 0, 0]
            for sy in range(scale):
                for sx in range(scale):
                    i = (((y * scale + sy) * canvas_size) + (x * scale + sx)) * 4
                    for c in range(4):
                        sums[c] += rgba[i + c]
            j = (y * size + x) * 4
            out[j : j + 4] = bytes(clamp(v / (scale * scale)) for v in sums)
    return out


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    sizes = {
        "Icon-20@2x.png": 40,
        "Icon-20@3x.png": 60,
        "Icon-29@2x.png": 58,
        "Icon-29@3x.png": 87,
        "Icon-40@2x.png": 80,
        "Icon-40@3x.png": 120,
        "Icon-60@2x.png": 120,
        "Icon-60@3x.png": 180,
        "Icon-1024.png": 1024,
    }

    for name, size in sizes.items():
        write_png(ICON_DIR / name, size, size, draw_icon(size))

    contents = {
        "images": [
            {"idiom": "iphone", "size": "20x20", "scale": "2x", "filename": "Icon-20@2x.png"},
            {"idiom": "iphone", "size": "20x20", "scale": "3x", "filename": "Icon-20@3x.png"},
            {"idiom": "iphone", "size": "29x29", "scale": "2x", "filename": "Icon-29@2x.png"},
            {"idiom": "iphone", "size": "29x29", "scale": "3x", "filename": "Icon-29@3x.png"},
            {"idiom": "iphone", "size": "40x40", "scale": "2x", "filename": "Icon-40@2x.png"},
            {"idiom": "iphone", "size": "40x40", "scale": "3x", "filename": "Icon-40@3x.png"},
            {"idiom": "iphone", "size": "60x60", "scale": "2x", "filename": "Icon-60@2x.png"},
            {"idiom": "iphone", "size": "60x60", "scale": "3x", "filename": "Icon-60@3x.png"},
            {"idiom": "ios-marketing", "size": "1024x1024", "scale": "1x", "filename": "Icon-1024.png"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (ICON_DIR / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
