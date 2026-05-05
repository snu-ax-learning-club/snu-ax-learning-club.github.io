#!/usr/bin/env bash
# Render slides in ../sal-tutorials and sync the output into this repo.
#
# Behavior:
#   1. quarto render each session-*/slides.qmd in the source repo (in-place).
#   2. Remove this repo's session-XX/index.html and session-XX/slides_files/.
#   3. Copy the freshly rendered slides.html → index.html and slides_files/.
#
# Note: sal-tutorials is a separate git repo. Renders mutate its working tree;
# commit those changes there separately.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_ROOT="$(cd "$DEST_ROOT/../sal-tutorials/docs/slides" 2>/dev/null && pwd || true)"

if ! command -v quarto >/dev/null 2>&1; then
  echo "error: quarto CLI not found in PATH" >&2
  exit 1
fi

if [[ -z "$SOURCE_ROOT" || ! -d "$SOURCE_ROOT" ]]; then
  echo "error: source not found at ../sal-tutorials/docs/slides (relative to $DEST_ROOT)" >&2
  exit 1
fi

shopt -s nullglob
sessions=("$SOURCE_ROOT"/session-*/)
shopt -u nullglob

if (( ${#sessions[@]} == 0 )); then
  echo "error: no session-* directories under $SOURCE_ROOT" >&2
  exit 1
fi

for src_dir in "${sessions[@]}"; do
  src_dir="${src_dir%/}"
  name="$(basename "$src_dir")"
  qmd="$src_dir/slides.qmd"

  if [[ ! -f "$qmd" ]]; then
    echo "[$name] skip (no slides.qmd)"
    continue
  fi

  echo "[$name] rendering…"
  quarto render "$qmd"

  dest_dir="$DEST_ROOT/$name"
  mkdir -p "$dest_dir"
  rm -rf "$dest_dir/index.html" "$dest_dir/slides_files"

  cp "$src_dir/slides.html" "$dest_dir/index.html"
  cp -R "$src_dir/slides_files" "$dest_dir/slides_files"

  echo "[$name] rendered → synced"
done

echo "done."
