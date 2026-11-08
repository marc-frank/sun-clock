"""Draws the Sun Clock app icon (run: python tool/make_icon.py)."""
import math
from PIL import Image, ImageDraw

BG = (28, 27, 23)
DAY = (255, 193, 77)
NIGHT = (63, 81, 160)
RING = (240, 230, 210)
HAND = (255, 179, 0)
S = 4096  # supersampled, scaled down at the end


def dial(img, cx, cy, r):
    d = ImageDraw.Draw(img)
    box = [cx - r, cy - r, cx + r, cy + r]
    d.pieslice(box, 180, 360, fill=DAY)    # upper half: day
    d.pieslice(box, 0, 180, fill=NIGHT)    # lower half: night
    d.line([cx - r, cy, cx + r, cy], fill=BG, width=int(r * 0.035))  # horizon
    d.ellipse(box, outline=RING, width=int(r * 0.07))
    # 24 ticks, majors at 0/6/12/18.
    for h in range(24):
        a = math.pi / 2 + h / 24 * 2 * math.pi
        major = h % 6 == 0
        r0 = r * (0.78 if major else 0.86)
        r1 = r * 0.93
        d.line([cx + math.cos(a) * r0, cy + math.sin(a) * r0,
                cx + math.cos(a) * r1, cy + math.sin(a) * r1],
               fill=BG,
               width=int(r * (0.05 if major else 0.025)))
    # Hand at about 08:00 sun time: morning, just after sunrise.
    a = math.pi / 2 + 8 / 24 * 2 * math.pi
    tip = (cx + math.cos(a) * r * 0.62, cy + math.sin(a) * r * 0.62)
    d.line([cx, cy, *tip], fill=BG, width=int(r * 0.09))
    k = r * 0.15
    d.ellipse([tip[0] - k, tip[1] - k, tip[0] + k, tip[1] + k], fill=BG)
    k2 = r * 0.105
    d.ellipse([tip[0] - k2, tip[1] - k2, tip[0] + k2, tip[1] + k2], fill=(255, 245, 220))
    c = r * 0.07
    d.ellipse([cx - c, cy - c, cx + c, cy + c], fill=BG)


def save(img, path, size=1024):
    img.resize((size, size), Image.LANCZOS).save(path)


# Full icon (iOS, legacy Android, store): dial on a dark square.
full = Image.new("RGB", (S, S), BG)
dial(full, S / 2, S / 2, S * 0.36)
save(full, "assets/icon/icon.png")

# Adaptive-icon foreground: transparent, dial inside the 66% safe zone.
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
dial(fg, S / 2, S / 2, S * 0.30)
save(fg, "assets/icon/icon_foreground.png")

# Splash mark (Android 12+ shows it inside a circle of 2/3 the size).
splash = Image.new("RGBA", (S, S), (0, 0, 0, 0))
dial(splash, S / 2, S / 2, S * 0.30)
save(splash, "assets/icon/splash.png", 768)

# Play Store hi-res icon.
save(full, "assets/icon/play_store_512.png", 512)
print("ok")

# Monochrome (themed) icon: Android uses only the alpha channel.
mono = Image.new("RGBA", (S, S), (0, 0, 0, 0))
dial_mono = ImageDraw.Draw(mono)
cx = cy = S / 2
r = S * 0.30
W = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
dial_mono.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=W)
dial_mono.ellipse([cx - r, cy - r, cx + r, cy + r], outline=W, width=int(r * 0.09))
a = math.pi / 2 + 8 / 24 * 2 * math.pi
tip = (cx + math.cos(a) * r * 0.62, cy + math.sin(a) * r * 0.62)
dial_mono.line([cx, cy, *tip], fill=CLEAR, width=int(r * 0.09))
k = r * 0.15
dial_mono.ellipse([tip[0] - k, tip[1] - k, tip[0] + k, tip[1] + k], fill=CLEAR)
k2 = r * 0.09
dial_mono.ellipse([tip[0] - k2, tip[1] - k2, tip[0] + k2, tip[1] + k2], fill=W)
save(mono, "assets/icon/icon_monochrome.png")
