#!/usr/bin/env bash
#
# Turn the "## [Unreleased]" heading into a dated release heading and open a
# fresh Unreleased section above it. release-it calls this from `after:bump`, so
# the rewritten CHANGELOG lands in the release commit.
#
#   bash scripts/changelog-stamp.sh 2.1.0
#
# No-ops when there is no Unreleased section — which is the case when releasing a
# version whose heading was already written by hand.
set -euo pipefail

VERSION="${1:?usage: changelog-stamp.sh <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG="$ROOT/CHANGELOG.md"
REPO_URL="https://github.com/dayaki/react-native-health-kits"
DATE="$(date +%Y-%m-%d)"

if ! grep -q '^## \[Unreleased\]' "$CHANGELOG"; then
  echo "changelog-stamp: no '## [Unreleased]' section, leaving CHANGELOG.md alone" >&2
  exit 0
fi

if grep -q "^## \[$VERSION\]" "$CHANGELOG"; then
  echo "changelog-stamp: '## [$VERSION]' already present, leaving CHANGELOG.md alone" >&2
  exit 0
fi

TMP="$(mktemp)"
awk -v ver="$VERSION" -v date="$DATE" '
  /^## \[Unreleased\]/ && !stamped {
    print "## [Unreleased]"
    print ""
    print "## [" ver "] - " date
    stamped = 1
    next
  }
  { print }
' "$CHANGELOG" > "$TMP"
mv "$TMP" "$CHANGELOG"

# Link references live at the bottom of the file, newest first. Insert above the
# first existing one rather than appending, so the order keeps matching the
# sections above.
if ! grep -q "^\[$VERSION\]:" "$CHANGELOG"; then
  LINK="[$VERSION]: $REPO_URL/releases/tag/v$VERSION"
  if grep -q '^\[[0-9]' "$CHANGELOG"; then
    TMP="$(mktemp)"
    awk -v link="$LINK" '
      /^\[[0-9]/ && !inserted { print link; inserted = 1 }
      { print }
    ' "$CHANGELOG" > "$TMP"
    mv "$TMP" "$CHANGELOG"
  else
    printf '\n%s\n' "$LINK" >> "$CHANGELOG"
  fi
fi

echo "changelog-stamp: stamped [$VERSION] - $DATE"
