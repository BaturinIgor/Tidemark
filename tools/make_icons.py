#!/usr/bin/env python3
"""Makes the alternate app icons (Pro: Settings › Appearance) by recoloring the main icon.

  python3 tools/make_icons.py      (needs Pillow)

Reads App/Assets.xcassets/AppIcon.appiconset/AppIcon.png. The cream sun and wave keep their color;
every teal pixel gets the variant's hue, with its lightness kept so the waves stay distinct.
Writes AppIcon-<Name>.appiconset (1024 px) and IconPreview-<Name>.imageset (180 px, shown in the picker).
"""
import colorsys, json, os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "App/Assets.xcassets")
SOURCE = os.path.join(ASSETS, "AppIcon.appiconset/AppIcon.png")

# name: (hue 0-1, saturation factor, lightness factor)
VARIANTS = {
    "Plum": (0.90, 0.75, 1.0),
    "Ocean": (0.58, 1.05, 1.0),
    "Forest": (0.30, 0.65, 0.95),
    "Night": (0.62, 0.55, 0.55),
}


def recolor(img, hue, sat_k, light_k):
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, *a = px[x, y]
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if l > 0.85:                  # cream sun and wave
                continue
            r2, g2, b2 = colorsys.hls_to_rgb(hue, min(1, l * light_k), min(1, s * sat_k))
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), *a)
    return out


def write_set(folder, filename, image, contents):
    os.makedirs(folder, exist_ok=True)
    image.save(os.path.join(folder, filename), optimize=True)
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
        f.write("\n")


def main():
    base = Image.open(SOURCE).convert("RGB")
    previews = {"Teal": base}
    for name, (hue, sat_k, light_k) in VARIANTS.items():
        icon = recolor(base, hue, sat_k, light_k)
        previews[name] = icon
        write_set(os.path.join(ASSETS, f"AppIcon-{name}.appiconset"), f"AppIcon-{name}.png", icon, {
            "images": [{"filename": f"AppIcon-{name}.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
            "info": {"author": "xcode", "version": 1}})
    for name, icon in previews.items():
        small = icon.resize((180, 180), Image.LANCZOS)
        write_set(os.path.join(ASSETS, f"IconPreview-{name}.imageset"), f"IconPreview-{name}.png", small, {
            "images": [{"filename": f"IconPreview-{name}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1}})
        print(name)


if __name__ == "__main__":
    main()
