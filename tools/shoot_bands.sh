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
    SIMCTL_CHILD_SCENE="$scene" xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
    # Debug build: the first frame, the platform views and the glass all
    # need a moment.
    sleep 9
    xcrun simctl io "$UDID" screenshot "$OUT/$look/$scene.png" >/dev/null
    echo "shot $look/$scene"
  done
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
