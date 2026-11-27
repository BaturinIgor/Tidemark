"""Reads the store listing for each App Store Connect locale from docs/app-store.md and docs/app-store/<lang>.md."""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# App Store Connect locale -> listing file language
LOCALES = {"en-US": "en", "en-GB": "en", "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "it": "it", "nl-NL": "nl",
           "pt-BR": "pt-BR", "sv": "sv", "no": "nb", "da": "da", "fi": "fi", "pl": "pl", "ja": "ja", "ko": "ko",
           "zh-Hans": "zh-Hans", "tr": "tr", "ru": "ru"}

LIMITS = {"name": 30, "subtitle": 30, "promotionalText": 170, "keywords": 100, "description": 4000}
SECTIONS = {"name": "Name", "subtitle": "Subtitle", "promotionalText": "Promotional text",
            "keywords": "Keywords", "description": "Description", "captions": "Screenshot captions"}
PLACEHOLDER = r"[\[［][^\]］]+[\]］]"   # [link …] or the full-width ［…］ used in Japanese


def _sections(text):
    out, current = {}, None
    for line in text.splitlines():
        m = re.match(r"^##\s+(.+?)\s*(\(.*\))?\s*$", line)
        if m:
            current = m.group(1).strip()
            out[current] = []
        elif current:
            out[current].append(line)
    return {k: "\n".join(v).strip() for k, v in out.items()}


def _us(s):
    return s.replace("hot flush", "hot flash").replace("Hot flush", "Hot flash")


def listing(locale, privacy_url=None):
    lang = LOCALES[locale]
    path = os.path.join(ROOT, "docs/app-store.md" if lang == "en" else f"docs/app-store/{lang}.md")
    secs = _sections(open(path, encoding="utf-8").read())
    item = {key: secs[title] for key, title in SECTIONS.items()}
    item["captions"] = re.findall(r"^\d+\.\s+(.+)$", item["captions"], flags=re.M)
    # The privacy policy line holds a [placeholder] until the policy is published.
    lines = []
    for line in item["description"].splitlines():
        if re.search(PLACEHOLDER, line):
            if not privacy_url:
                continue
            line = re.sub(PLACEHOLDER, privacy_url, line)
        lines.append(line)
    item["description"] = "\n".join(lines).strip()
    if locale == "en-US":
        item["promotionalText"] = _us(item["promotionalText"])
        item["description"] = _us(item["description"])
        item["captions"] = [_us(c) for c in item["captions"]]
    return item


def lint():
    problems = []
    for locale in LOCALES:
        item = listing(locale)
        for key, limit in LIMITS.items():
            if not item[key]:
                problems.append(f"{locale}: {key} empty")
            elif len(item[key]) > limit:
                problems.append(f"{locale}: {key} {len(item[key])} > {limit}")
        if re.search(r"[\[［]", item["description"]):
            problems.append(f"{locale}: placeholder left in description")
        if len(item["captions"]) != 6:
            problems.append(f"{locale}: {len(item['captions'])} captions")
    return problems


if __name__ == "__main__":
    for p in lint() or ["listing OK for %d locales" % len(LOCALES)]:
        print(p)
