#!/usr/bin/env bash
set -euo pipefail

# bump_version.sh <major|minor|patch>
# Updates MARKETING_VERSION (semantic) and increments CURRENT_PROJECT_VERSION in Config/Base.xcconfig.
# Usage: ./scripts/bump_version.sh patch

CONFIG_FILE="Config/Base.xcconfig"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

PART=${1:-}
if [[ -z "$PART" ]]; then
  echo "Provide bump part: major|minor|patch" >&2
  exit 1
fi

CURRENT_MARKETING=$(grep -E '^MARKETING_VERSION' "$CONFIG_FILE" | awk -F '= ' '{print $2}')
CURRENT_BUILD=$(grep -E '^CURRENT_PROJECT_VERSION' "$CONFIG_FILE" | awk -F '= ' '{print $2}')

IFS='.' read -r MA MI PA <<<"$CURRENT_MARKETING"
: "${PA:=0}" # ensure patch presence

case "$PART" in
  major)
    ((MA+=1)); MI=0; PA=0 ;;
  minor)
    ((MI+=1)); PA=0 ;;
  patch)
    ((PA+=1)) ;;
  *)
    echo "Unknown part: $PART (use major|minor|patch)" >&2; exit 1 ;;
 esac

NEW_MARKETING="$MA.$MI.$PA"
NEW_BUILD=$((CURRENT_BUILD + 1))

tmp=$(mktemp)
while IFS= read -r line; do
  case "$line" in
    MARKETING_VERSION*) echo "MARKETING_VERSION = $NEW_MARKETING" ;;
    CURRENT_PROJECT_VERSION*) echo "CURRENT_PROJECT_VERSION = $NEW_BUILD" ;;
    *) echo "$line" ;;
  esac
done < "$CONFIG_FILE" > "$tmp"

mv "$tmp" "$CONFIG_FILE"

echo "Updated MARKETING_VERSION $CURRENT_MARKETING -> $NEW_MARKETING"
echo "Incremented CURRENT_PROJECT_VERSION to $NEW_BUILD"
