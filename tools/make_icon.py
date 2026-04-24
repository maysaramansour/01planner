"""Generate launcher icons for 01Planner.

Renders a fog-themed badge with the text "01" centered on a soft gradient,
into the standard mipmap-* density buckets used by the Flutter Android app.
"""
from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# Fog palette (matches lib/theme/app_theme.dart)
BG_TOP = (35, 39, 45)        # surface
BG_BOTTOM = (26, 29, 33)     # background
ACCENT = (122, 156, 184)     # primary fog blue
HIGHLIGHT = (201, 168, 138)  # tertiary warm sand
TEXT = (226, 229, 234)       # onSurface

DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/SFNSRounded.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
]


def find_font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def render(size: int) -> Image.Image:
    # Render at 4x then downscale for crisp anti-aliasing.
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Vertical gradient background, rounded square.
    radius = int(s * 0.22)
    bg = Image.new("RGBA", (s, s), BG_BOTTOM + (255,))
    grad = Image.new("RGBA", (s, s))
    for y in range(s):
        t = y / (s - 1)
        r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
        for x in range(s):
            grad.putpixel((x, y), (r, g, b, 255))
    bg = grad

    mask = Image.new("L", (s, s), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle((0, 0, s, s), radius=radius, fill=255)
    img.paste(bg, (0, 0), mask)

    # Soft fog glow circle behind text.
    glow_size = int(s * 0.7)
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    cx = s // 2
    cy = s // 2
    gdraw.ellipse(
        (cx - glow_size // 2, cy - glow_size // 2,
         cx + glow_size // 2, cy + glow_size // 2),
        fill=ACCENT + (60,),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=int(s * 0.06)))
    img = Image.alpha_composite(img, glow)

    # "01" text — bold, slightly tracked.
    draw = ImageDraw.Draw(img)
    font = find_font(int(s * 0.5))
    text = "01"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (s - tw) // 2 - bbox[0]
    ty = (s - th) // 2 - bbox[1] - int(s * 0.02)
    # Subtle shadow.
    shadow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.text((tx + int(s * 0.012), ty + int(s * 0.018)), text,
               fill=(0, 0, 0, 160), font=font)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=int(s * 0.012)))
    img = Image.alpha_composite(img, shadow)
    draw = ImageDraw.Draw(img)
    draw.text((tx, ty), text, fill=TEXT + (255,), font=font)

    # Accent underline.
    bar_w = int(s * 0.34)
    bar_h = max(2, int(s * 0.018))
    bar_y = ty + th + int(s * 0.04)
    bar_x = (s - bar_w) // 2
    draw.rounded_rectangle(
        (bar_x, bar_y, bar_x + bar_w, bar_y + bar_h),
        radius=bar_h // 2, fill=HIGHLIGHT + (255,),
    )

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    base = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "android", "app", "src", "main", "res",
    )
    for folder, size in DENSITIES.items():
        out_dir = os.path.join(base, folder)
        os.makedirs(out_dir, exist_ok=True)
        img = render(size)
        img.save(os.path.join(out_dir, "ic_launcher.png"), format="PNG")
    # Also write a 512px version for the in-app branding / play listing.
    big = render(512)
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "assets", "logo.png",
    )
    os.makedirs(os.path.dirname(out), exist_ok=True)
    big.save(out, format="PNG")
    print("OK")


if __name__ == "__main__":
    main()
