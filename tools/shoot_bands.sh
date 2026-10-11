#!/usr/bin/env bash
# Screenshots side_by_side scenes in light and dark.
#
#   shoot_bands.sh <udid> <out-dir> [scene ...]
#
# With no scenes given, shoots every scene in side_by_side/lib/main.dart.
set -euo pipefail

UDID=$1
OUT=$2
shift 2
BUNDLE=dev.lgcompare.sideBySide

SCENES=("$@")
if [ ${#SCENES[@]} -eq 0 ]; then
  # The keys of kScenes: lines like  'buttons_photo': (_) => ...
  while IFS= read -r s; do SCENES+=("$s"); done < <(
    grep -oE "^  '[a-z_]+': \(_\)" side_by_side/lib/main.dart | cut -d"'" -f2)
fi
echo "scenes: ${SCENES[*]}"

for look in light dark; do
  mkdir -p "$OUT/$look"
  xcrun simctl ui "$UDID" appearance "$look"
  for scene in "${SCENES[@]}"; do
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
    # The debug app switches scenes on its localhost endpoint (launch
    # environment variables do not reach it).
    for _ in $(seq 1 30); do
      curl -sf "http://127.0.0.1:8790/scene?name=$scene" >/dev/null && break
      sleep 1
    done
    # The platform views and the glass need a moment after the switch.
    sleep 4
    xcrun simctl io "$UDID" screenshot "$OUT/$look/$scene.png" >/dev/null
    echo "shot $look/$scene"
  done
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
