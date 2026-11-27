#!/bin/bash
# App Store screenshots, 6.9" (1320 x 2868), in every App Store Connect localization.
#
#   tools/store_screenshots.sh            all localizations
#   tools/store_screenshots.sh de-DE ja   only these
#
# Raw shots go to build/store-screenshots/raw/<locale>/, captioned ones (tools/frame_screenshots.py)
# to build/store-screenshots/final/<locale>/. Made-up data in memory; the real store is never touched.
set -euo pipefail
cd "$(dirname "$0")/.."

# App Store Connect locale | app language | iOS locale | Region in the app
LOCALES="
en-US en en_US US
en-GB en en_GB UK
de-DE de de_DE EU
fr-FR fr fr_FR EU
es-ES es es_ES EU
it it it_IT EU
nl-NL nl nl_NL EU
pt-BR pt-BR pt_BR OTHER
sv sv sv_SE EU
no nb nb_NO OTHER
da da da_DK EU
fi fi fi_FI EU
pl pl pl_PL EU
ja ja ja_JP OTHER
ko ko ko_KR OTHER
zh-Hans zh-Hans zh_CN OTHER
tr tr tr_TR OTHER
ru ru ru_RU OTHER
"
OUT="$PWD/build/store-screenshots"
DEVICE_NAME="Tidemark Store 6.9"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"

udid=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
d = json.load(sys.stdin)['devices']
print(next((x['udid'] for k in d if 'iOS' in k for x in d[k] if x['name'] == '$DEVICE_NAME'), ''))")
if [ -z "$udid" ]; then
  udid=$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE")
fi
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 --operatorName ""

xcodegen generate >/dev/null
mkdir -p "$OUT"
echo "Building..."
xcodebuild build-for-testing -project Tidemark.xcodeproj -scheme Design -destination "id=$udid" \
  -derivedDataPath build/dd CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=- \
  STRING_CATALOG_GENERATE_SYMBOLS=NO \
  > "$OUT/build.log" 2>&1 || { grep -E "error:" "$OUT/build.log" | sort -u | head -40; exit 1; }

echo "$LOCALES" | while read -r asc lang locale region; do
  [ -z "$asc" ] && continue
  if [ $# -gt 0 ] && [[ ! " $* " == *" $asc "* ]]; then continue; fi
  dir="$OUT/raw/$asc"
  rm -rf "$dir" && mkdir -p "$dir"
  echo "== $asc"
  TEST_RUNNER_STORE_DIR="$dir" TEST_RUNNER_STORE_LANG="$lang" TEST_RUNNER_STORE_LOCALE="$locale" \
  TEST_RUNNER_STORE_REGION="$region" \
  xcodebuild test-without-building -project Tidemark.xcodeproj -scheme Design -destination "id=$udid" \
    -derivedDataPath build/dd -only-testing:TidemarkUITests/StoreScreenshotsUITests \
    > "$OUT/test-$asc.log" 2>&1 || echo "   FAILED, see $OUT/test-$asc.log"
  ls "$dir" | wc -l | xargs echo "   shots:"
done
