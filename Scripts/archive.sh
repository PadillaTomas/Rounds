#!/usr/bin/env bash
# Archive Rounds for the App Store and (optionally) upload to App Store Connect.
#
# The everyday path is Xcode: Product > Archive > Distribute App. This script is
# for a repeatable / CI upload.
#
#   APPLE_TEAM_ID=XXXXXXXXXX ./Scripts/archive.sh                # archive + export only
#   APPLE_TEAM_ID=XXXXXXXXXX \
#     ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxx-xxxx-xxxx \
#     ASC_KEY_PATH=~/AuthKey_XXXXXXXXXX.p8 \
#     ./Scripts/archive.sh --upload                              # ... and upload
#
# The team ID is never stored in the repo — pass it in. It's on
# developer.apple.com > Membership.
set -euo pipefail

cd "$(dirname "$0")/.."
: "${APPLE_TEAM_ID:?set APPLE_TEAM_ID (developer.apple.com > Membership)}"

command -v xcodegen >/dev/null && xcodegen generate
BUILD="${BUILD_DIR:-build}"
ARCHIVE="$BUILD/Rounds.xcarchive"
EXPORT="$BUILD/export"
OPTS="$BUILD/ExportOptions.plist"

mkdir -p "$BUILD"
cat > "$OPTS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>teamID</key><string>${APPLE_TEAM_ID}</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST

echo "==> Archiving"
xcodebuild archive \
  -scheme Rounds \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID"

echo "==> Exporting .ipa"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$OPTS" \
  -exportPath "$EXPORT" \
  -allowProvisioningUpdates
echo "    $EXPORT/Rounds.ipa"

if [[ "${1:-}" == "--upload" ]]; then
  : "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}" "${ASC_KEY_PATH:?}"
  # altool looks for AuthKey_<id>.p8 in ~/private_keys
  mkdir -p ~/private_keys
  cp "$ASC_KEY_PATH" ~/private_keys/"AuthKey_${ASC_KEY_ID}.p8"
  echo "==> Uploading to App Store Connect"
  xcrun altool --upload-app -f "$EXPORT/Rounds.ipa" -t ios \
    --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
fi
