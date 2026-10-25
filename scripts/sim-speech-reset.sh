#!/usr/bin/env bash
# Re-enable live speech-to-text (speech_to_text) on an iOS simulator. Takes ~15 s.
#
# Why: the simulator cannot load iOS's on-device speech models (*_Cryptex.dmg assets).
# Live text works while recognition goes to Apple's ONLINE dictation, but after the first
# session that recognizes real speech, iOS subscribes that language's on-device model and
# every later request fails with `error_unknown (300)`. Deleting those subscriptions (with
# the simulator shut down - iOS caches the choice in memory) restores online dictation.
#
# Effect: ONE working live-text session per language; run again before the next one.
# Real iPhones load the on-device model normally and do not need this.
#
# Usage: scripts/sim-speech-reset.sh [UDID|booted] [BUNDLE_ID]
set -euo pipefail
UDID="${1:-booted}"
BUNDLE="${2:-vn.edu.rmit.capstone.medVoice}"
if [ "$UDID" = "booted" ]; then
  UDID=$(xcrun simctl list devices booted -j | python3 -c '
import sys, json
devs = [d for v in json.load(sys.stdin)["devices"].values() for d in v if d.get("state") == "Booted"]
print(devs[0]["udid"] if devs else "")')
  [ -n "$UDID" ] || { echo "no booted simulator - pass a UDID"; exit 1; }
fi
DB=~/Library/Developer/CoreSimulator/Devices/$UDID/data/private/var/db/assetsubscriptiond/UAFAssetSubscriptions.db
[ -f "$DB" ] || { echo "no asset subscription db for $UDID"; exit 1; }

xcrun simctl shutdown "$UDID" 2>/dev/null || true
n=$(sqlite3 "$DB" "delete from Subscriptions where (k1 like 'assistant.%' or k1 like 'hammer.%'); select changes();")
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
open -a Simulator
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
echo "$UDID: cleared $n speech-model subscription(s), rebooted, relaunched $BUNDLE"
echo "Live text works for one session per language; log in again, then record."
