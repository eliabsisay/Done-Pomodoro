#!/usr/bin/env bash
#
# design-lint.sh — design-token guard for the visual redesign.
# (See docs/redesign-plan.md, Decisions log #9.)
#
# A zero-dependency (bash + grep) check that flags HARDCODED styling values
# creeping into Modules/ — the exact regression the redesign is fixing. It does
# NOT scan Common/ (Color+Extensions, Constants, DesignSystem/), because that's
# where tokens are legitimately DEFINED; this guards the consumption side.
#
# Baseline model: the un-redesigned Modules/ already contains ~dozens of legacy
# hardcoded values, so we can't fail on all of them yet. The lint compares
# against scripts/design-lint-baseline.txt and reports ONLY violations not in
# that baseline (i.e. NEWLY introduced ones). As each redesign PR cleans a
# screen, regenerate the baseline so it shrinks toward empty by PR4.
#
# Signatures are keyed by "path<TAB>trimmed-source-line" (no line numbers), so
# edits that merely shift lines around don't register as new violations.
#
# Enforcement: advisory until PR2 (warns, exit 0), blocking from PR2 onward.
# Controlled by DESIGN_LINT_BLOCKING (default false). CI flips it to true at PR2.
#
# Usage:
#   scripts/design-lint.sh                    # check; list any new violations
#   scripts/design-lint.sh --update-baseline  # snapshot current tree as baseline
#   DESIGN_LINT_BLOCKING=true scripts/design-lint.sh   # fail on new violations
#
# Escape hatch: append  // design-lint:allow  to a line to exempt it.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SCAN_DIRS=("Modules")
BASELINE="scripts/design-lint-baseline.txt"
BLOCKING="${DESIGN_LINT_BLOCKING:-false}"

# Each pattern flags a hardcoded styling value that should come from a token.
PATTERNS=(
  # Literal/system colors handed to styling modifiers. Note: semantic
  # .primary / .secondary are intentionally NOT listed — they adapt to
  # light/dark and are allowed.
  '\.(tint|foregroundColor|foregroundStyle|background|fill|stroke|border|accentColor)\(\s*\.(blue|red|green|orange|yellow|pink|purple|gray|grey|black|white|brown|cyan|mint|teal|indigo)\b'
  # Ad-hoc color construction.
  'Color\(\s*(red:|hue:|\.sRGB)'
  'UIColor\(\s*(red:|white:|hue:)'
  # Raw spacing / corner-radius numeric literals.
  '\.(padding|cornerRadius)\(\s*-?[0-9]'
)

# Emit "path<TAB>trimmed-line" for every match, dropping allow-listed lines.
collect() {
  local dir pat
  for dir in "${SCAN_DIRS[@]}"; do
    for pat in "${PATTERNS[@]}"; do
      grep -rnE --include='*.swift' "$pat" "$dir" 2>/dev/null
    done
  done \
    | grep -v 'design-lint:allow' \
    | sed -E 's/^([^:]+):[0-9]+:[[:space:]]*/\1\t/' \
    | sort -u
}

current="$(collect)"

# --- Update mode -----------------------------------------------------------
if [[ "${1:-}" == "--update-baseline" ]]; then
  printf '%s\n' "$current" | grep -c . >/dev/null   # touch, see count below
  printf '%s\n' "$current" > "$BASELINE"
  count="$(grep -c . "$BASELINE" || true)"
  echo "✅ Baseline updated: $count entries → $BASELINE"
  exit 0
fi

if [[ ! -f "$BASELINE" ]]; then
  echo "::error::Missing $BASELINE — run: scripts/design-lint.sh --update-baseline"
  exit 1
fi

# --- Check mode ------------------------------------------------------------
# New violations = current signatures absent from the baseline.
new="$(comm -13 <(sort -u "$BASELINE") <(printf '%s\n' "$current" | sort -u))"
new="$(printf '%s\n' "$new" | grep -c . || true)"
new_lines="$(comm -13 <(sort -u "$BASELINE") <(printf '%s\n' "$current" | sort -u) | grep -c . || true)"

baseline_count="$(grep -c . "$BASELINE" || true)"
echo "🎨 design-lint: baseline=$baseline_count known violation(s) in Modules/ (blocking=$BLOCKING)"

if [[ "$new_lines" -eq 0 ]]; then
  echo "✅ No new hardcoded styling values introduced."
  exit 0
fi

echo ""
echo "⚠️  $new_lines NEW hardcoded styling value(s) introduced (not in baseline):"
echo ""
comm -13 <(sort -u "$BASELINE") <(printf '%s\n' "$current" | sort -u) \
  | sed 's/\t/  →  /' | sed 's/^/   • /'
echo ""
echo "   Fix: use a design token (Constants.Spacing / Color+Extensions / a"
echo "   ButtonStyle), or — if truly intentional — append  // design-lint:allow"
echo "   to the line. After a redesign PR cleans a screen, refresh the baseline:"
echo "     scripts/design-lint.sh --update-baseline"
echo ""

if [[ "$BLOCKING" == "true" ]]; then
  echo "::error::design-lint failed: $new_lines new hardcoded styling value(s)."
  exit 1
fi

echo "(advisory mode — not failing CI yet; flip DESIGN_LINT_BLOCKING=true at PR2)"
exit 0
