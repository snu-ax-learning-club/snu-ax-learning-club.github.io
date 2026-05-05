#!/usr/bin/env bash
# Render each session's slides to PDF in a portrait aspect ratio.
#
# Assumes scripts/sync-slides.sh has already produced
# session-XX/index.html in this repo. PDFs are written to
# session-XX/slides.pdf via decktape (invoked through npx).
#
# Override the page size via env vars:
#   SLIDE_WIDTH=720 SLIDE_HEIGHT=1280 ./scripts/render-pdf.sh
# Defaults: 1080x1920 (9:16, 1080p portrait).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SLIDE_WIDTH="${SLIDE_WIDTH:-1080}"
SLIDE_HEIGHT="${SLIDE_HEIGHT:-1920}"

if ! command -v node >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
  echo "error: node/npx not found in PATH (install Node.js, e.g. via nvm)" >&2
  exit 1
fi

shopt -s nullglob
sessions=("$ROOT_DIR"/session-*/)
shopt -u nullglob

if (( ${#sessions[@]} == 0 )); then
  echo "error: no session-* directories under $ROOT_DIR" >&2
  exit 1
fi

have_input=0
for dir in "${sessions[@]}"; do
  [[ -f "${dir}index.html" ]] && have_input=1 && break
done
if (( have_input == 0 )); then
  echo "error: no session-XX/index.html found. Run scripts/sync-slides.sh first." >&2
  exit 1
fi

echo "decktape size: ${SLIDE_WIDTH}x${SLIDE_HEIGHT}"
echo "(first run may take a minute while decktape downloads Chromium)"

ok=0
fail=0
for dir in "${sessions[@]}"; do
  dir="${dir%/}"
  name="$(basename "$dir")"
  html="$dir/index.html"
  pdf="$dir/slides.pdf"

  if [[ ! -f "$html" ]]; then
    echo "[$name] skip (no index.html)"
    continue
  fi

  echo "[$name] rendering ${SLIDE_WIDTH}x${SLIDE_HEIGHT} → slides.pdf"
  if npx --yes decktape reveal \
      --size="${SLIDE_WIDTH}x${SLIDE_HEIGHT}" \
      --load-pause=1000 \
      "file://${html}" \
      "$pdf"; then
    ok=$((ok + 1))
  else
    echo "[$name] FAILED" >&2
    fail=$((fail + 1))
  fi
done

echo "done. (${ok} ok, ${fail} failed)"
exit $(( fail > 0 ? 1 : 0 ))
