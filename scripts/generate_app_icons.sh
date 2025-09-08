#!/bin/bash
# generate_app_icons.sh
# Usage: ./scripts/generate_app_icons.sh [source_1024_png] [target_appiconset_dir]
# Default source: icon-1024.png (project root)
# Default target: Workoutlog/Assets.xcassets/AppIcon.appiconset
# Requires: sips (macOS built-in)

set -euo pipefail

SOURCE=${1:-icon-1024.png}
TARGET_DIR=${2:-Workoutlog/Assets.xcassets/AppIcon.appiconset}

if [ ! -f "$SOURCE" ]; then
  echo "Source 1024 png not found: $SOURCE" >&2
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Target AppIcon set directory not found: $TARGET_DIR" >&2
  exit 1
fi

cp "$SOURCE" "$TARGET_DIR/AppIcon-1024.png"

pushd "$TARGET_DIR" >/dev/null

function gen() { # size outputName
  local SIZE=$1
  local NAME=$2
  sips -Z "$SIZE" AppIcon-1024.png --out "$NAME" >/dev/null
}

echo "Generating iPhone / iPad icon sizes from AppIcon-1024.png ..."

# iPhone
gen 40  AppIcon-20x20@2x.png
gen 60  AppIcon-20x20@3x.png

gen 58  AppIcon-29x29@2x.png
gen 87  AppIcon-29x29@3x.png

gen 80  AppIcon-40x40@2x.png
gen 120 AppIcon-40x40@3x.png

gen 120 AppIcon-60x60@2x.png
gen 180 AppIcon-60x60@3x.png

# iPad
gen 20  AppIcon-20x20@1x.png
gen 40  AppIcon-20x20@2x-ipad.png # duplicate size reuse; keep distinct filename to avoid overwrite

gen 29  AppIcon-29x29@1x.png
# 58 already generated (29x29@2x)

gen 40  AppIcon-40x40@1x.png
# 80 already generated (40x40@2x)

gen 76  AppIcon-76x76@1x.png
gen 152 AppIcon-76x76@2x.png

gen 167 AppIcon-83.5x83.5@2x.png

# Create updated Contents.json
cat > Contents.json <<'JSON'
{
  "images": [
    { "idiom": "iphone", "size": "20x20", "scale": "2x", "filename": "AppIcon-20x20@2x.png" },
    { "idiom": "iphone", "size": "20x20", "scale": "3x", "filename": "AppIcon-20x20@3x.png" },
    { "idiom": "iphone", "size": "29x29", "scale": "2x", "filename": "AppIcon-29x29@2x.png" },
    { "idiom": "iphone", "size": "29x29", "scale": "3x", "filename": "AppIcon-29x29@3x.png" },
    { "idiom": "iphone", "size": "40x40", "scale": "2x", "filename": "AppIcon-40x40@2x.png" },
    { "idiom": "iphone", "size": "40x40", "scale": "3x", "filename": "AppIcon-40x40@3x.png" },
    { "idiom": "iphone", "size": "60x60", "scale": "2x", "filename": "AppIcon-60x60@2x.png" },
    { "idiom": "iphone", "size": "60x60", "scale": "3x", "filename": "AppIcon-60x60@3x.png" },

    { "idiom": "ipad", "size": "20x20", "scale": "1x", "filename": "AppIcon-20x20@1x.png" },
    { "idiom": "ipad", "size": "20x20", "scale": "2x", "filename": "AppIcon-20x20@2x-ipad.png" },
    { "idiom": "ipad", "size": "29x29", "scale": "1x", "filename": "AppIcon-29x29@1x.png" },
    { "idiom": "ipad", "size": "29x29", "scale": "2x", "filename": "AppIcon-29x29@2x.png" },
    { "idiom": "ipad", "size": "40x40", "scale": "1x", "filename": "AppIcon-40x40@1x.png" },
    { "idiom": "ipad", "size": "40x40", "scale": "2x", "filename": "AppIcon-40x40@2x.png" },
    { "idiom": "ipad", "size": "76x76", "scale": "1x", "filename": "AppIcon-76x76@1x.png" },
    { "idiom": "ipad", "size": "76x76", "scale": "2x", "filename": "AppIcon-76x76@2x.png" },
    { "idiom": "ipad", "size": "83.5x83.5", "scale": "2x", "filename": "AppIcon-83.5x83.5@2x.png" },

    { "idiom": "ios-marketing", "size": "1024x1024", "scale": "1x", "filename": "AppIcon-1024.png" }
  ],
  "info": { "version": 1, "author": "script" }
}
JSON

echo "Done. Verify icons in Xcode (Assets.xcassets/AppIcon)."

popd >/dev/null
