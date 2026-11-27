#!/usr/bin/env python3
"""Builds the public support and privacy pages for GitHub Pages (repo BaturinIgor/tidemark-legal).

  python3 tools/legal/build_pages.py [out_dir]      (needs: pip install markdown)

Sources: docs/support.md and docs/privacy-policy.md. The privacy page is skipped while the policy
still has [placeholders] to fill in, so a draft is never published.
Published at https://baturinigor.github.io/tidemark-legal/{privacy,support}.html
"""
import os, re, sys
import markdown

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build/legal")

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
body {{ font-family: -apple-system, system-ui, sans-serif; max-width: 720px; margin: 0 auto; padding: 24px 16px;
       line-height: 1.55; color: #1d2b29; background: #f5f4f0; }}
h1 {{ font-size: 26px; color: #16675f; }} h2 {{ font-size: 19px; margin-top: 28px; }}
a {{ color: #16675f; }}
@media (prefers-color-scheme: dark) {{ body {{ color: #e6ecea; background: #141a19; }} h1, a {{ color: #6cc4b8; }} }}
</style>
</head>
<body>
{body}
</body>
</html>
"""


def render(src, title, drop_draft_note=False):
    text = open(os.path.join(ROOT, src), encoding="utf-8").read()
    if drop_draft_note:
        text = re.sub(r"^>.*\n+", "", text, flags=re.M)          # "Draft for legal review" note
        text = text.replace(" (draft)", "")
    body = markdown.markdown(text, extensions=["extra"])
    body = re.sub(r"\b([\w.+-]+@[\w-]+\.[\w.]+)\b(?![^<]*</a>)", r'<a href="mailto:\1">\1</a>', body)
    return PAGE.format(title=title, body=body), text


def main():
    os.makedirs(OUT, exist_ok=True)
    support, _ = render("docs/support.md", "Tidemark Support")
    open(os.path.join(OUT, "support.html"), "w", encoding="utf-8").write(support)
    print("support.html")

    privacy, text = render("docs/privacy-policy.md", "Tidemark Privacy Policy", drop_draft_note=True)
    # "[your name]" is the iOS Settings row, not a blank to fill in.
    left = [p for p in re.findall(r"\[[^\]]+\](?!\()", text) if p != "[your name]"]
    if left:
        print("privacy.html skipped, fill in first: " + "; ".join(left))
    else:
        open(os.path.join(OUT, "privacy.html"), "w", encoding="utf-8").write(privacy)
        print("privacy.html")

    open(os.path.join(OUT, "index.html"), "w", encoding="utf-8").write(PAGE.format(
        title="Tidemark", body='<h1>Tidemark</h1>\n<p><a href="support.html">Support</a> · '
                               '<a href="privacy.html">Privacy Policy</a></p>'))
    open(os.path.join(OUT, ".nojekyll"), "w").close()


if __name__ == "__main__":
    main()
