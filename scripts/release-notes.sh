#!/usr/bin/env bash
#
# Print the CHANGELOG.md section for a given version, for use as GitHub release
# notes. release-it calls this via `github.releaseNotes`.
#
#   bash scripts/release-notes.sh 2.0.0
#
# The changelog is hand-written, so it is the source of the release notes rather
# than the commit log — the migration guidance in it is the part users need.
set -euo pipefail

VERSION="${1:?usage: release-notes.sh <version>}"
CHANGELOG="$(cd "$(dirname "$0")/.." && pwd)/CHANGELOG.md"
HEADING="## [$VERSION]"

NOTES="$(
  awk -v heading="$HEADING" '
    substr($0, 1, length(heading)) == heading { found = 1; next }
    found && /^## \[/ { exit }
    found { print }
  ' "$CHANGELOG"
)"

# Trim blank lines from both ends.
NOTES="$(printf '%s\n' "$NOTES" | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"

if [[ -z "$NOTES" ]]; then
  echo "release-notes: no '$HEADING' section found in CHANGELOG.md" >&2
  exit 1
fi

printf '%s\n' "$NOTES"
