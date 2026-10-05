#!/bin/bash
# Try the whole buyer journey on this Mac without touching your real pairing:
# the website on http://localhost:3000 and a Debug OurNotch running as a separate test identity.
#
#   scripts/try-local.sh            # profile "test"
#   scripts/try-local.sh fresh2     # another fresh profile
#
# Quit your real OurNotch first, so "Open OurNotch" on the thank-you page reaches the test copy.
set -euo pipefail
cd "$(dirname "$0")/.."
PROFILE=${1:-test}

if ! lsof -iTCP:3000 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "▸ Starting the website (log: build/website.log)"
  mkdir -p build
  nohup npm --prefix website run dev >build/website.log 2>&1 &
fi

echo "▸ Building OurNotch (Debug)"
xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData -allowProvisioningUpdates -quiet build

pkill -f "Debug/OurNotch.app/Contents/MacOS/OurNotch" && sleep 1 || true   # an older test copy (never your real one)
echo "▸ Opening OurNotch as profile \"$PROFILE\""
open -n --env OURNOTCH_PROFILE="$PROFILE" build/DerivedData/Build/Products/Debug/OurNotch.app
echo "✓ Website: http://localhost:3000   ·   Partner Simulator: ♡ menu → Partner Simulator…"
