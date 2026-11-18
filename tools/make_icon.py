# Draws App/Assets.xcassets/AppIcon.appiconset/AppIcon.png: python3 tools/make_icon.py <out.png>
import math, sys
from PIL import Image, ImageDraw
S = 4096  # draw large, downscale for smooth edges
out = sys.argv[1]
img = Image.new("RGB", (S, S))
d = ImageDraw.Draw(img)
top, bottom = (0x14, 0x86, 0x82), (0x0A, 0x4F, 0x4D)
for y in range(S):
    t = y / S
    d.line([(0, y), (S, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))

def wave(y0, amp, length, phase):
    return [(x, y0 + amp * math.sin(2 * math.pi * x / length + phase)) for x in range(-50, S + 51, 8)]

# water: filled bands below the tide line, lighter to darker
bands = [(0.60, (0x5F, 0xA9, 0xA3)), (0.72, (0x3E, 0x85, 0x80)), (0.82, (0x0E, 0x6E, 0x6B))]
for i, (frac, color) in enumerate(bands):
    pts = wave(S * frac, S * 0.022, S * 0.55, i * 1.3)
    d.polygon(pts + [(S + 50, S + 50), (-50, S + 50)], fill=color)

# the tide mark: a cream line above the water
w = S * 0.034
upper = wave(S * 0.53 - w / 2, S * 0.022, S * 0.55, 0)
lower = wave(S * 0.53 + w / 2, S * 0.022, S * 0.55, 0)
d.polygon(upper + lower[::-1], fill=(0xF6, 0xF1, 0xE6))
# moon
r = S * 0.11
cx, cy = S * 0.66, S * 0.28
d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(0xF6, 0xF1, 0xE6))
img.resize((1024, 1024), Image.LANCZOS).save(out, optimize=True)
