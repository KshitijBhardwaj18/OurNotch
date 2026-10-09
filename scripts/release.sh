#!/bin/bash
# Builds OurNotch for people outside the App Store (devpost/spec-m2.md > Packaging and Updates):
# archive → Developer ID signing + notarization + staple → DMG → Sparkle appcast → upload to R2.
#
#   scripts/release.sh            # the sold build (Release: live Dodo, no diagnostics)
#   scripts/release.sh Beta       # for test couples (test-mode Dodo, diagnostics on)
#
# Needs Xcode signed into the team's Apple account (Xcode > Settings > Accounts): Xcode signs with the
# team's cloud-managed Developer ID certificate and sends the app to Apple's notary service with that login.
# Also Sparkle's EdDSA key in your keychain under the account "ournotch" (its public half in
# SPARKLE_PUBLIC_KEY), and `npx wrangler login` for the upload to R2. Any failing step stops the script
# before the upload, so nothing half-signed is ever published.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG=${1:-Release}
TEAM_ID=${TEAM_ID:-HDFVQX8ZDA}
OUT=build/release/$CONFIG
SPARKLE_BIN=build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin
BUCKET=ournotch-downloads
FEED_DIR=$([ "$CONFIG" = Beta ] && echo beta/ || echo "")
VERSION=$(xcodebuild -project OurNotch.xcodeproj -target OurNotch -configuration "$CONFIG" -showBuildSettings 2>/dev/null | awk -F' = ' '/ MARKETING_VERSION/{print $2}')
DMG=$OUT/OurNotch-$VERSION.dmg

rm -rf "$OUT" && mkdir -p "$OUT/updates"
echo "▸ Archiving OurNotch $VERSION ($CONFIG)"
xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -configuration "$CONFIG" \
  -derivedDataPath build/DerivedData -archivePath "$OUT/OurNotch.xcarchive" -allowProvisioningUpdates -quiet archive

echo "▸ Signing with Developer ID and sending to Apple's notary service"
sed "s/TEAM_ID/$TEAM_ID/" scripts/ExportOptions.plist > "$OUT/ExportOptions.plist"
xcodebuild -exportArchive -archivePath "$OUT/OurNotch.xcarchive" -exportOptionsPlist "$OUT/ExportOptions.plist" \
  -exportPath "$OUT/upload" -allowProvisioningUpdates -quiet
echo "▸ Waiting for notarization (a few minutes)"
until xcodebuild -exportNotarizedApp -archivePath "$OUT/OurNotch.xcarchive" -exportPath "$OUT/export" > "$OUT/notarize.log" 2>&1; do
  grep -q "processing" "$OUT/notarize.log" || { cat "$OUT/notarize.log"; exit 1; }   # rejected: stop
  sleep 30
done
APP=$OUT/export/OurNotch.app
xcrun stapler validate "$APP"
spctl --assess -vv "$APP"

echo "▸ Making $DMG"
mkdir -p "$OUT/dmg" && cp -R "$APP" "$OUT/dmg/" && ln -s /Applications "$OUT/dmg/Applications"
hdiutil create -volname OurNotch -srcfolder "$OUT/dmg" -fs HFS+ -format UDZO -quiet "$DMG"

echo "▸ Writing the Sparkle appcast"
cp "$DMG" "$OUT/updates/"
"$SPARKLE_BIN/generate_appcast" --account ournotch --download-url-prefix "https://downloads.ournotch.app/$FEED_DIR" "$OUT/updates"

echo "▸ Uploading to R2"
npx --yes wrangler r2 object put "$BUCKET/${FEED_DIR}OurNotch-$VERSION.dmg" --file "$DMG" --remote
npx --yes wrangler r2 object put "$BUCKET/${FEED_DIR}OurNotch.dmg" --file "$DMG" --remote   # what /download points at
npx --yes wrangler r2 object put "$BUCKET/${FEED_DIR}appcast.xml" --file "$OUT/updates/appcast.xml" --content-type application/xml --remote
echo "✓ Released OurNotch $VERSION ($CONFIG)"
