#!/usr/bin/env bash
# Drift guard for the duplicated source-credibility rubric.
# The two skill copies are intentionally NOT byte-identical (each has its own header +
# per-skill appendix), but the SHARED-CORE block between the HTML-comment markers MUST be
# identical. All paths are resolved relative to THIS script's own location (dirname "$0"),
# so the checker is portable — run it from anywhere, or wire it into your own hook.
# Exit 0 = in sync; exit 1 = drift (a CI step or pre-commit hook should fail on exit 1).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DR="$HERE/deep-research/references/source-credibility.md"
AS="$HERE/attack-surface/references/source-credibility.md"

extract() { awk '/<!-- SHARED-CORE:BEGIN/{f=1;next} /<!-- SHARED-CORE:END/{f=0} f' "$1"; }

for f in "$DR" "$AS"; do
  if [ ! -f "$f" ]; then echo "❌ missing file: $f"; exit 1; fi
done

a="$(extract "$DR")"; b="$(extract "$AS")"
if [ -z "$a" ]; then echo "❌ no SHARED-CORE block found in $DR"; exit 1; fi

if [ "$a" = "$b" ]; then
  echo "✅ source-credibility SHARED-CORE in sync ($(printf '%s\n' "$a" | wc -l | tr -d ' ') lines, sha $(printf '%s' "$a" | shasum | cut -c1-12))"
  exit 0
else
  echo "❌ source-credibility SHARED-CORE DRIFT between deep-research and attack-surface:"
  diff <(printf '%s\n' "$a") <(printf '%s\n' "$b") || true
  exit 1
fi
