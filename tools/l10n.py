#!/usr/bin/env python3
"""Builds the string catalogs from Localization/<lang>.json and checks that every string is translated.

  python3 tools/l10n.py build              write App/, Widgets/ and TidemarkCore catalogs
  python3 tools/l10n.py check KEYS_FILE    fail if a key from the app export or the core sources is missing
  python3 tools/l10n.py lint               fail if a translation changes the placeholders of its key
  python3 tools/l10n.py keys XLIFF         print the source keys of an Xcode .xliff export, one JSON string per line

Localization/<lang>.json holds {"strings": {key: value}, "infoplist": {plist key: value}}.
A value is a string, or {"one": ..., "few": ..., "many": ..., "other": ...} for plurals.
Keys are the English text as SwiftUI writes it (%lld for Int, %@ for String). "en.json" lists every key.
"""
import json, os, re, sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOC = os.path.join(ROOT, "Localization")
LANGS = ["en", "de", "fr", "es", "it", "nl", "pt-BR", "sv", "nb", "da", "fi", "pl", "ja", "ko", "zh-Hans", "tr", "ru"]
CORE_SRC = os.path.join(ROOT, "Packages/TidemarkCore/Sources/TidemarkCore")
TARGETS = [
    "App/Localizable.xcstrings",
    "Widgets/Localizable.xcstrings",
    "Packages/TidemarkCore/Sources/TidemarkCore/Resources/Localizable.xcstrings",
]


def load(lang):
    path = os.path.join(LOC, f"{lang}.json")
    if not os.path.exists(path):
        return {"strings": {}, "infoplist": {}}
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def unit(value):
    if isinstance(value, dict):
        return {"variations": {"plural": {k: {"stringUnit": {"state": "translated", "value": v}} for k, v in value.items()}}}
    return {"stringUnit": {"state": "translated", "value": value}}


def catalog(section):
    data = {lang: load(lang).get(section, {}) for lang in LANGS}
    strings = {}
    for key in sorted(data["en"]):
        locs = {lang: unit(data[lang][key]) for lang in LANGS if key in data[lang]}
        strings[key] = {"extractionState": "manual", "localizations": locs}
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


def write(path, obj):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")


def core_keys():
    """Keys the core package looks up at runtime (not extracted by the compiler)."""
    keys = set()
    for name in os.listdir(CORE_SRC):
        if not name.endswith(".swift"):
            continue
        src = open(os.path.join(CORE_SRC, name), encoding="utf-8").read()
        keys |= set(re.findall(r'L10n\.(?:text|format)\("((?:[^"\\]|\\.)*)"', src))
        keys |= set(re.findall(r'\blabel: "((?:[^"\\]|\\.)*)"', src))
        keys |= set(re.findall(r'\bgroup: "((?:[^"\\]|\\.)*)"', src))
        keys |= set(re.findall(r'\btitle: "((?:[^"\\]|\\.)*)", hint: "((?:[^"\\]|\\.)*)"', src) and
                    [k for pair in re.findall(r'\btitle: "((?:[^"\\]|\\.)*)", hint: "((?:[^"\\]|\\.)*)"', src) for k in pair])
        for arr in re.findall(r'(?:groups|answerLabels)[^=\n]*[=:{]\s*\[([^\]]*)\]', src):
            keys |= set(re.findall(r'"((?:[^"\\]|\\.)*)"', arr))
        keys |= set(re.findall(r'case \w+ = "((?:[^"\\]|\\.)*)"', src)) if "enum Trend" in src else set()
        keys |= set(re.findall(r'L10n\.text\(self == \.\w+ \? "([^"]*)" : "([^"]*)"\)', src) and
                    [k for pair in re.findall(r'L10n\.text\(self == \.\w+ \? "([^"]*)" : "([^"]*)"\)', src) for k in pair])
    return {k.replace('\\"', '"') for k in keys if re.search(r"[A-Za-z]", k)}


def xliff_keys(path):
    ns = {"x": "urn:oasis:names:tc:xliff:document:1.2"}
    tree = ET.parse(path)
    keys = set()
    for f in tree.getroot().findall("x:file", ns):
        original = f.get("original", "")
        if "InfoPlist" in original:
            continue
        for tu in f.iter("{urn:oasis:names:tc:xliff:document:1.2}trans-unit"):
            src = tu.find("x:source", ns)
            key = tu.get("id")
            if key and "|==|" in key:  # plural sub-units of a key
                key = key.split("|==|")[0]
            if key:
                keys.add(key)
    return keys


def translatable(key):
    return re.search(r"[A-Za-z]", re.sub(r"%(\d\$)?(lld|ld|d|@|lf|f)", "", key)) is not None


# Strings that may drop the doctor-term %@ and spell the word out in the right grammatical form.
MAY_DROP_ARG = {
    "A week of check-ins shows your %@ a pattern, not one bad day. Missed a day? You can fill in the last 3 days from Today.",
    "For your %@",
    "Save the one-page PDF to print, email or upload to your %@'s portal.",
    "Symptom summary for my %@",
    "You can ask for a second opinion. Keep checking in and take an updated report to another %@ or a menopause clinic.",
}
# Plural forms whose "one" category means exactly 1, so the number may be left out.
ONE_IS_ONE = {"en", "de", "es", "it", "nl", "sv", "nb", "da", "fi"}


def specs(text):
    """Placeholders of a format string as sorted (position, type) pairs, plus the count of stray % signs."""
    text = text.replace("%%", "")
    found = []
    for n, m in enumerate(re.finditer(r"%(?:(\d)\$)?(lld|@)", text), start=1):
        found.append((int(m.group(1)) if m.group(1) else n, m.group(2)))
    return sorted(found), text.count("%") - len(found)


def lint():
    """Every translation keeps the placeholders of its English key."""
    ok = True
    for lang in LANGS:
        for key, value in load(lang)["strings"].items():
            want, _ = specs(key)
            forms = value.items() if isinstance(value, dict) else [("", value)]
            for cat, form in forms:
                got, stray = specs(form)
                fine = got == want or (key in MAY_DROP_ARG and not got) or \
                    (cat == "one" and lang in ONE_IS_ONE and want == [(1, "lld")] and not got)
                if not fine or stray or not form.strip():
                    ok = False
                    print(f"::error::{lang}: placeholders differ in {json.dumps(key, ensure_ascii=False)}: {json.dumps(form, ensure_ascii=False)}")
    return ok


def check(keys_file):
    with open(keys_file, encoding="utf-8") as f:
        app = {json.loads(line) for line in f if line.strip()}
    wanted = {k for k in app | core_keys() if translatable(k)}
    ok = True
    for lang in LANGS:
        have = load(lang)
        missing = sorted(wanted - set(have["strings"]))
        missing_plist = sorted(set(load("en")["infoplist"]) - set(have["infoplist"]))
        if missing or missing_plist:
            ok = False
            print(f"::error::{lang}: {len(missing) + len(missing_plist)} strings not translated")
            for k in missing + missing_plist:
                print(f"  {lang}\t{json.dumps(k, ensure_ascii=False)}")
    ok = lint() and ok
    unused = sorted(set(load("en")["strings"]) - wanted)
    if unused:
        print(f"note: {len(unused)} keys in en.json are no longer used in code")
        for k in unused:
            print(f"  unused\t{json.dumps(k, ensure_ascii=False)}")
    return ok


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "build":
        strings = catalog("strings")
        for path in TARGETS:
            write(path, strings)
        write("App/InfoPlist.xcstrings", catalog("infoplist"))
        print(f"{len(strings['strings'])} keys, {len(LANGS)} languages")
    elif cmd == "keys":
        for k in sorted(xliff_keys(sys.argv[2])):
            print(json.dumps(k, ensure_ascii=False))
    elif cmd == "check":
        sys.exit(0 if check(sys.argv[2]) else 1)
    elif cmd == "lint":
        sys.exit(0 if lint() else 1)
    elif cmd == "core-keys":
        for k in sorted(core_keys()):
            print(json.dumps(k, ensure_ascii=False))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
