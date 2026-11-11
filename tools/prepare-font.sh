#!/usr/bin/env bash
# Install the exact, unmodified upstream SC font before Godot's first import.
set -euo pipefail
cd "$(dirname "$0")/.."
target=assets/fonts/NotoSansSC-Regular.otf
blob=fc0fda9394367c16c1af7555a2ae4d5e2e6a6f02
upstream=https://raw.githubusercontent.com/notofonts/noto-cjk/523d033d6cb47f4a80c58a35753646f5c3608a78/Sans/SubsetOTF/SC/NotoSansSC-Regular.otf
if [[ -f "$target" ]] && [[ "$(git hash-object --no-filters "$target")" == "$blob" ]]; then
  exit 0
fi
partial=$(mktemp "${target}.XXXXXX")
trap 'rm -f "$partial"' EXIT
curl --fail --location --silent --show-error --retry 2 "$upstream" --output "$partial"
if [[ "$(git hash-object --no-filters "$partial")" != "$blob" ]]; then
  echo "Unexpected upstream font content for $target" >&2
  exit 1
fi
mv -f "$partial" "$target"
echo "Prepared $target ($blob)"
