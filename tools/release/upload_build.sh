#!/bin/bash
# Archives Tidemark and uploads it to App Store Connect with the API key (no Xcode login needed).
#   ASC_KEY_ID=… ASC_ISSUER_ID=… tools/release/upload_build.sh
# Puts GoogleService-Info.plist in place first (tools/analytics/add_firebase_config.sh).
set -euo pipefail
cd "$(dirname "$0")/../.."
KEY="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
tools/analytics/add_firebase_config.sh app.tidemark.ios
xcodegen generate
ARCHIVE=build/Tidemark.xcarchive
rm -rf "$ARCHIVE" build/export
xcodebuild archive -scheme Tidemark -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" -derivedDataPath build/DerivedData-release "${AUTH[@]}"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath build/export \
  -exportOptionsPlist tools/release/ExportOptions.plist "${AUTH[@]}"
echo "Uploaded. App Store Connect processes the build in 10-30 minutes."
