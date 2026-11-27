#!/usr/bin/env python3
"""Uploads Tidemark's App Store listing to App Store Connect. Safe to run again: it updates what exists.

  ASC_KEY_ID=… ASC_ISSUER_ID=… python3 tools/asc/upload.py <step> [<step> …]

Steps: metadata, settings, subscriptions, screenshots (or none for all).
Sources: docs/app-store*.md (listing.py), tools/asc/subscriptions.json,
build/store-screenshots/final/<locale>/*.png (tools/store_screenshots.sh + tools/frame_screenshots.py).
"""
import hashlib, json, os, sys
import requests
from client import ASC, ASCError
from listing import LOCALES, listing, lint, ROOT

BUNDLE_ID = "app.tidemark.ios"
VERSION = "1.0"
HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(ROOT, "build/store-screenshots/final")
PRIVACY_URL = "https://baturinigor.github.io/tidemark-legal/privacy.html"   # tools/legal/build_pages.py
SUPPORT_URL = "https://baturinigor.github.io/tidemark-legal/support.html"
SAMPLE = os.path.join(ROOT, "build/Tidemark-review-sample.zip")    # .json is not accepted as an attachment   # ReviewSampleTests, made on the day

a = ASC()


def rel(type_, id_):
    return {"data": {"type": type_, "id": id_}}


def find_app():
    app = a.get("/v1/apps", **{"filter[bundleId]": BUNDLE_ID})["data"][0]
    info = next(i for i in a.get_all(f"/v1/apps/{app['id']}/appInfos")
                if i["attributes"]["state"] in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"))
    version = next(v for v in a.get_all(f"/v1/apps/{app['id']}/appStoreVersions")
                   if v["attributes"]["versionString"] == VERSION)
    return app["id"], info["id"], version["id"]


def upsert_localizations(list_path, create_type, parent_key, parent_type, parent_id, wanted):
    """wanted: {locale: attributes}. Creates missing locales and patches existing ones."""
    existing = {l["attributes"]["locale"]: l for l in a.get_all(list_path)}
    out = {}
    for locale, attrs in wanted.items():
        if locale in existing:
            lid = existing[locale]["id"]
            a.patch(f"/v1/{create_type}/{lid}", {"data": {"type": create_type, "id": lid, "attributes": attrs}})
        else:
            lid = a.post(f"/v1/{create_type}", {"data": {"type": create_type, "attributes": {"locale": locale, **attrs},
                                                         "relationships": {parent_key: rel(parent_type, parent_id)}}})["data"]["id"]
        out[locale] = lid
    return out


# ---- steps ---------------------------------------------------------------------------------------

def metadata(app, info, version):
    problems = lint()
    if problems:
        sys.exit("Listing has problems:\n" + "\n".join(problems))
    items = {loc: listing(loc, PRIVACY_URL) for loc in LOCALES}
    info_attrs = {loc: {"name": x["name"], "subtitle": x["subtitle"],
                        **({"privacyPolicyUrl": PRIVACY_URL} if PRIVACY_URL else {})}
                  for loc, x in items.items()}
    upsert_localizations(f"/v1/appInfos/{info}/appInfoLocalizations", "appInfoLocalizations",
                         "appInfo", "appInfos", info, info_attrs)
    print(f"app info: name and subtitle in {len(info_attrs)} locales")
    ver_attrs = {loc: {"description": x["description"], "keywords": x["keywords"], "promotionalText": x["promotionalText"],
                       "supportUrl": SUPPORT_URL}
                 for loc, x in items.items()}
    upsert_localizations(f"/v1/appStoreVersions/{version}/appStoreVersionLocalizations", "appStoreVersionLocalizations",
                         "appStoreVersion", "appStoreVersions", version, ver_attrs)
    print(f"version {VERSION}: description, keywords, promotional text in {len(ver_attrs)} locales")


AGE_RATING = {
    # Frequency questions
    "alcoholTobaccoOrDrugUseOrReferences": "NONE", "contests": "NONE", "gamblingSimulated": "NONE",
    "gunsOrOtherWeapons": "NONE", "horrorOrFearThemes": "NONE", "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "INFREQUENT_OR_MILD", "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE", "sexualContentOrNudity": "NONE", "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE", "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    # Yes/no questions
    "advertising": False, "gambling": False, "healthOrWellnessTopics": True, "lootBox": False,
    "messagingAndChat": False, "parentalControls": False, "ageAssurance": False, "userGeneratedContent": False,
    "unrestrictedWebAccess": False, "socialMedia": False, "sharedLocation": False,
}


def settings(app, info, version):
    a.patch(f"/v1/appInfos/{info}", {"data": {"type": "appInfos", "id": info, "relationships": {
        "primaryCategory": rel("appCategories", "HEALTH_AND_FITNESS")}}})
    print("category: Health & Fitness")
    rating = a.get(f"/v1/appInfos/{info}/ageRatingDeclaration")["data"]["id"]
    a.patch(f"/v1/ageRatingDeclarations/{rating}", {"data": {"type": "ageRatingDeclarations", "id": rating,
                                                             "attributes": AGE_RATING}})
    print("age rating questionnaire answered")
    # The Menopause Rating Scale is third-party content, used under licence.
    a.patch(f"/v1/apps/{app}", {"data": {"type": "apps", "id": app,
                                         "attributes": {"contentRightsDeclaration": "USES_THIRD_PARTY_CONTENT"}}})
    print("content rights: uses third-party content (MRS, licensed)")


def subscriptions(app, info, version):
    cfg = json.load(open(os.path.join(HERE, "subscriptions.json"), encoding="utf-8"))
    groups = {g["attributes"]["referenceName"]: g["id"] for g in a.get_all(f"/v1/apps/{app}/subscriptionGroups")}
    group = groups.get(cfg["group"]) or a.post("/v1/subscriptionGroups", {"data": {
        "type": "subscriptionGroups", "attributes": {"referenceName": cfg["group"]},
        "relationships": {"app": rel("apps", app)}}})["data"]["id"]
    upsert_localizations(f"/v1/subscriptionGroups/{group}/subscriptionGroupLocalizations", "subscriptionGroupLocalizations",
                         "subscriptionGroup", "subscriptionGroups", group,
                         {loc: {"name": x["group"]} for loc, x in cfg["localizations"].items()})
    print(f"group '{cfg['group']}' with {len(cfg['localizations'])} localizations")

    existing = {s["attributes"]["productId"]: s["id"] for s in a.get_all(f"/v1/subscriptionGroups/{group}/subscriptions")}
    territories = [t["id"] for t in a.get_all("/v1/territories")]
    for p in cfg["products"]:
        kind = "yearly" if p["period"] == "ONE_YEAR" else "monthly"
        sid = existing.get(p["productId"]) or a.post("/v1/subscriptions", {"data": {
            "type": "subscriptions",
            "attributes": {"name": p["referenceName"], "productId": p["productId"], "subscriptionPeriod": p["period"],
                           "groupLevel": p["level"], "familySharable": False},
            "relationships": {"group": rel("subscriptionGroups", group)}}})["data"]["id"]
        upsert_localizations(f"/v1/subscriptions/{sid}/subscriptionLocalizations", "subscriptionLocalizations",
                             "subscription", "subscriptions", sid,
                             {loc: {"name": x[kind], "description": x["description"]}
                              for loc, x in cfg["localizations"].items()})
        # Availability: every territory, and new ones as Apple adds them.
        try:
            a.post("/v1/subscriptionAvailabilities", {"data": {
                "type": "subscriptionAvailabilities", "attributes": {"availableInNewTerritories": True},
                "relationships": {"subscription": rel("subscriptions", sid),
                                  "availableTerritories": {"data": [{"type": "territories", "id": t} for t in territories]}}}})
        except ASCError as e:
            if "409" not in str(e):
                raise
        set_subscription_price(sid, p["usd"])
        if p.get("freeTrial"):
            set_free_trial(sid, p["freeTrial"], territories)
        print(f"{p['productId']}: ${p['usd']} {p['period']}, {len(cfg['localizations'])} localizations")


def set_free_trial(sid, duration, territories):
    """Introductory offer: a free trial for new subscribers, in every territory."""
    have = {o["relationships"]["territory"]["data"]["id"]
            for o in a.get_all(f"/v1/subscriptions/{sid}/introductoryOffers", include="territory")}
    added = 0
    for t in territories:
        if t in have:
            continue
        a.post("/v1/subscriptionIntroductoryOffers", {"data": {
            "type": "subscriptionIntroductoryOffers",
            "attributes": {"duration": duration, "offerMode": "FREE_TRIAL", "numberOfPeriods": 1},
            "relationships": {"subscription": rel("subscriptions", sid), "territory": rel("territories", t)}}})
        added += 1
    print(f"  free trial {duration}: added in {added} territories, {len(have)} already had it")


def set_subscription_price(sid, usd):
    if a.get_all(f"/v1/subscriptions/{sid}/prices", **{"filter[territory]": "USA"}):
        print("  prices already set, left as they are")
        return
    points = a.get_all(f"/v1/subscriptions/{sid}/pricePoints", **{"filter[territory]": "USA"})
    base = next(p for p in points if p["attributes"]["customerPrice"] == usd)
    # Apple's equalized prices for every other territory, as the App Store Connect UI fills them in.
    equal = a.get_all(f"/v1/subscriptionPricePoints/{base['id']}/equalizations", include="territory")
    count = 0
    for point, territory in [(base, "USA")] + [(p, p["relationships"]["territory"]["data"]["id"]) for p in equal]:
        a.post("/v1/subscriptionPrices", {"data": {
            "type": "subscriptionPrices", "attributes": {"preserveCurrentPrice": False},
            "relationships": {"subscription": rel("subscriptions", sid), "territory": rel("territories", territory),
                              "subscriptionPricePoint": rel("subscriptionPricePoints", point["id"])}}})
        count += 1
    print(f"  prices set in {count} territories")


def upload_file(create_type, parent_key, parent_type, parent_id, path):
    data = open(path, "rb").read()
    item = a.post(f"/v1/{create_type}", {"data": {
        "type": create_type, "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
        "relationships": {parent_key: rel(parent_type, parent_id)}}})["data"]
    for op in item["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        requests.request(op["method"], op["url"], data=chunk, headers=headers).raise_for_status()
    a.patch(f"/v1/{create_type}/{item['id']}", {"data": {"type": create_type, "id": item["id"], "attributes": {
        "uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return item["id"]


def screenshots(app, info, version, display="APP_IPHONE_67"):
    locs = {l["attributes"]["locale"]: l["id"]
            for l in a.get_all(f"/v1/appStoreVersions/{version}/appStoreVersionLocalizations")}
    for locale in LOCALES:
        folder = os.path.join(SHOTS, locale)
        files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
        sets = {s["attributes"]["screenshotDisplayType"]: s["id"]
                for s in a.get_all(f"/v1/appStoreVersionLocalizations/{locs[locale]}/appScreenshotSets")}
        sid = sets.get(display) or a.post("/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display},
            "relationships": {"appStoreVersionLocalization": rel("appStoreVersionLocalizations", locs[locale])}}})["data"]["id"]
        # Replace what was uploaded before with the current set, in caption order.
        for old in a.get_all(f"/v1/appScreenshotSets/{sid}/appScreenshots"):
            a.delete(f"/v1/appScreenshots/{old['id']}")
        for f in files:
            upload_file("appScreenshots", "appScreenshotSet", "appScreenshotSets", sid, os.path.join(folder, f))
        print(f"{locale}: {len(files)} screenshots")


def review(app, info, version):
    detail = a.get(f"/v1/appStoreVersions/{version}/appStoreReviewDetail")["data"]["id"]
    notes = open(os.path.join(HERE, "review-notes.txt"), encoding="utf-8").read().strip()
    a.patch(f"/v1/appStoreReviewDetails/{detail}", {"data": {"type": "appStoreReviewDetails", "id": detail,
             "attributes": {"notes": notes, "demoAccountRequired": False}}})
    for old in a.get_all(f"/v1/appStoreReviewDetails/{detail}/appStoreReviewAttachments"):
        a.delete(f"/v1/appStoreReviewAttachments/{old['id']}")
    upload_file("appStoreReviewAttachments", "appStoreReviewDetail", "appStoreReviewDetails", detail, SAMPLE)
    print(f"review notes ({len(notes)} chars) and {os.path.basename(SAMPLE)} attached")


STEPS = {"review": review, "metadata": metadata, "settings": settings, "subscriptions": subscriptions, "screenshots": screenshots}

if __name__ == "__main__":
    ids = find_app()
    for s in sys.argv[1:] or list(STEPS):
        STEPS[s](*ids)
