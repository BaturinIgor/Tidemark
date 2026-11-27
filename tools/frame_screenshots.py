#!/usr/bin/env python3
"""Puts the localized caption above each raw App Store screenshot.

  python3 tools/frame_screenshots.py      (needs Pillow: pip install pillow; macOS system fonts)

Reads build/store-screenshots/raw/<locale>/N-name.png (tools/store_screenshots.sh) and the
"Screenshot captions" list in docs/app-store.md or docs/app-store/<lang>.md, and writes
1320 x 2868 PNGs to build/store-screenshots/final/<locale>/.
"""
import os, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "build/store-screenshots/raw")
OUT = os.path.join(ROOT, "build/store-screenshots/final")
W, H = 1320, 2868
BACKGROUND = (22, 103, 95)       # Theme accent teal
CAPTION = (255, 255, 255)
FONTS = "/System/Library/Fonts"

# App Store Connect locale -> listing file language
LISTING = {"en-US": "en", "en-GB": "en", "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "it": "it", "nl-NL": "nl",
           "pt-BR": "pt-BR", "sv": "sv", "no": "nb", "da": "da", "fi": "fi", "pl": "pl", "ja": "ja", "ko": "ko",
           "zh-Hans": "zh-Hans", "tr": "tr", "ru": "ru"}


def captions(locale):
    lang = LISTING[locale]
    path = os.path.join(ROOT, "docs/app-store.md" if lang == "en" else f"docs/app-store/{lang}.md")
    text = open(path, encoding="utf-8").read()
    section = re.split(r"^##+ Screenshot captions.*$", text, flags=re.M)[1]
    items = re.findall(r"^\d+\.\s+(.+)$", section.split("\n## ")[0], flags=re.M)
    if locale == "en-US":
        items = [re.sub(r"hot flush", "hot flash", c) for c in items]
    return items


def font(locale, size):
    if locale == "ja":
        return ImageFont.truetype(f"{FONTS}/ヒラギノ角ゴシック W7.ttc", size)
    if locale == "zh-Hans":
        return ImageFont.truetype(f"{FONTS}/Hiragino Sans GB.ttc", size, index=1)
    if locale == "ko":
        return ImageFont.truetype(f"{FONTS}/AppleSDGothicNeo.ttc", size, index=6)
    f = ImageFont.truetype(f"{FONTS}/SFNS.ttf", size)
    try:
        f.set_variation_by_name("Bold")
    except Exception:
        pass
    return f


def wrap(draw, text, f, width):
    """Greedy wrap by words, or by characters for CJK text without spaces."""
    sep = " " if " " in text else ""
    if sep:
        tokens = text.split(" ")
    else:
        # CJK: keep phrases whole (break after 、，。), split a phrase into characters only if it can't fit.
        tokens = []
        for phrase in re.findall(r"[^、，。]+[、，。]?", text):
            tokens += [phrase] if draw.textlength(phrase, font=f) <= width else list(phrase)
    lines, line = [], ""
    for t in tokens:
        test = (line + sep + t) if line else t
        if draw.textlength(test, font=f) <= width:
            line = test
        else:
            lines.append(line)
            line = t
    lines.append(line)
    return lines


def frame(raw_path, caption, locale, out_path):
    canvas = Image.new("RGB", (W, H), BACKGROUND)
    draw = ImageDraw.Draw(canvas)
    size = 92
    while True:
        f = font(locale, size)
        lines = wrap(draw, caption, f, W - 200)
        if len(lines) <= 3 or size <= 60:
            break
        size -= 4
    line_h = int(size * 1.22)
    top = 170 + (3 - len(lines)) * line_h // 2
    for i, line in enumerate(lines):
        draw.text((W // 2, top + i * line_h), line, font=f, fill=CAPTION, anchor="mt")

    shot = Image.open(raw_path).convert("RGB")
    scale = 0.84
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=96, fill=255)
    x, y = (W - sw) // 2, 640
    # Thin light border so light screens stand out from the background.
    border = Image.new("L", (sw + 12, sh + 12), 0)
    ImageDraw.Draw(border).rounded_rectangle((0, 0, sw + 11, sh + 11), radius=102, fill=255)
    canvas.paste((235, 242, 240), (x - 6, y - 6), border)
    canvas.paste(shot, (x, y), mask)
    canvas.save(out_path, optimize=True)


def main():
    locales = sys.argv[1:] or sorted(os.listdir(RAW))
    for locale in locales:
        caps = captions(locale)
        shots = sorted(p for p in os.listdir(os.path.join(RAW, locale)) if p.endswith(".png"))
        if len(caps) != len(shots):
            print(f"{locale}: {len(caps)} captions for {len(shots)} screenshots, skipped")
            continue
        os.makedirs(os.path.join(OUT, locale), exist_ok=True)
        for caption, name in zip(caps, shots):
            frame(os.path.join(RAW, locale, name), caption, locale, os.path.join(OUT, locale, name))
        print(f"{locale}: {len(shots)} framed")


if __name__ == "__main__":
    main()
