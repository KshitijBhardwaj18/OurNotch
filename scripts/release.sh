#!/bin/bash
# Builds OurNotch for people outside the App Store (devpost/spec-m2.md > Packaging and Updates):
# archive → Developer ID export → DMG → notarize + staple → Sparkle appcast → upload to R2.
#
#   scripts/release.sh            # the sold build (Release: live Dodo, no diagnostics)
#   scripts/release.sh Beta       # for test couples (test-mode Dodo, diagnostics on)
#
# Needs, once (slice 11, your own Apple account):
#   - a "Developer ID Application" certificate in your keychain (Xcode > Settings > Accounts > Manage Certificates)
#   - xcrun notarytool store-credentials ournotch      (saves your notarization login in the keychain)
#   - Sparkle's EdDSA key in your keychain under the account "ournotch" (generate_keys --account ournotch),
#     its public half in SPARKLE_PUBLIC_KEY
#   - npx wrangler login                               (for the upload to R2)
# Without a Developer ID certificate it stops after building an unsigned local DMG, so nothing
# half-signed can ever be uploaded. Any failing step stops the script before the upload.
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

if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  echo "▸ Exporting with Developer ID"
  sed "s/TEAM_ID/$TEAM_ID/" scripts/ExportOptions.plist > "$OUT/ExportOptions.plist"
  xcodebuild -exportArchive -archivePath "$OUT/OurNotch.xcarchive" -exportOptionsPlist "$OUT/ExportOptions.plist" \
    -exportPath "$OUT/export" -allowProvisioningUpdates -quiet
  APP=$OUT/export/OurNotch.app
  SIGNED=1
else
  echo "▸ No Developer ID certificate yet: building a local, unsigned DMG only (no notarization, no upload)"
  APP=$OUT/OurNotch.xcarchive/Products/Applications/OurNotch.app
  SIGNED=0
fi

echo "▸ Making $DMG"
mkdir -p "$OUT/dmg" && cp -R "$APP" "$OUT/dmg/" && ln -s /Applications "$OUT/dmg/Applications"
hdiutil create -volname OurNotch -srcfolder "$OUT/dmg" -fs HFS+ -format UDZO -quiet "$DMG"
[ "$SIGNED" = 1 ] || { echo "✓ Local DMG ready: $DMG"; exit 0; }

codesign --sign "Developer ID Application" --timestamp "$DMG"
echo "▸ Notarizing (a few minutes)"
xcrun notarytool submit "$DMG" --keychain-profile ournotch --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"

echo "▸ Writing the Sparkle appcast"
cp "$DMG" "$OUT/updates/"
"$SPARKLE_BIN/generate_appcast" --account ournotch --download-url-prefix "https://downloads.ournotch.app/$FEED_DIR" "$OUT/updates"

echo "▸ Uploading to R2"
npx --yes wrangler r2 object put "$BUCKET/${FEED_DIR}OurNotch-$VERSION.dmg" --file "$DMG" --remote
npx --yes wrangler r2 object put "$BUCKET/${FEED_DIR}OurNotch.dmg" --file "$DMG" --remote   # what /download points at
npx --yes wrangler r2 object put "$BUCKET/${FEED_DIR}appcast.xml" --file "$OUT/updates/appcast.xml" --content-type application/xml --remote
echo "✓ Released OurNotch $VERSION ($CONFIG)"
