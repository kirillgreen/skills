#!/usr/bin/env bash
# Fixture suite for naming-gate.sh (deny creating a file with a non-conforming name) and for
# naming-lint.sh -n, the shared negative list the gate calls.
#
# Runs against a sandboxed HOME and a COPY of the bundle, so it never touches your real notes
# and never needs the skill to be installed. From a fresh clone:
#
#     bash naming-gate/tests/run.sh
#
# Exit 0 = all green. Requires bash, jq, awk, grep.
#
# Every exemption assertion uses an input that WOULD be a finding without the exemption —
# a name that trips nothing either way proves nothing about the code it claims to guard.

set -u

SKILL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
GATE_SRC="$SKILL_DIR/naming-gate.sh"
LINT="$SKILL_DIR/naming-lint.sh"
CONF="$SKILL_DIR/naming.conf.example"
RULE="$SKILL_DIR/references/grammar.md"
PASS=0; FAILED=0

command -v jq >/dev/null 2>&1 || { echo "naming-gate tests: jq is required" >&2; exit 2; }
for f in "$GATE_SRC" "$LINT" "$CONF" "$RULE"; do
  [ -r "$f" ] || { echo "naming-gate tests: missing $f" >&2; exit 2; }
done

SBOX=$(mktemp -d "${TMPDIR:-/tmp}/nmg-fx.XXXXXX")
# Canonicalize: macOS TMPDIR sits behind a symlink, and the gate compares $HOME-prefixed
# literals against the incoming path — a symlinked sandbox HOME makes those diverge in ways a
# real (canonical) $HOME never does. `cd && pwd -P` does it with no python or GNU readlink.
SBOX=$(cd -- "$SBOX" && pwd -P)
PAUSE="$SBOX/pausefile"
ALLOW="$SBOX/allowfile"
trap 'rm -rf "$SBOX"' EXIT

# A COPY of the bundle, not a symlink: the gate resolves its lint and its config as siblings
# of itself, so the only way to test "the validator is broken" is to own the copy that breaks.
mkdir -p "$SBOX/skill/references"
cp "$GATE_SRC" "$SBOX/skill/naming-gate.sh"
cp "$LINT"     "$SBOX/skill/naming-lint.sh"
cp "$CONF"     "$SBOX/skill/naming.conf"
cp "$RULE"     "$SBOX/skill/references/grammar.md"
GATE="$SBOX/skill/naming-gate.sh"

# The tree the example config describes.
mkdir -p "$SBOX/notes/research" \
         "$SBOX/notes/plans/active" \
         "$SBOX/notes/plans/completed/2026-08-26-interfaces-baseline" \
         "$SBOX/notes/decisions" \
         "$SBOX/notes/references" \
         "$SBOX/notes/tools" \
         "$SBOX/notes/audits" \
         "$SBOX/notes/lessons" \
         "$SBOX/notes/Transcripts" \
         "$SBOX/notes/templates" \
         "$SBOX/notes/imports/2026-05-26" \
         "$SBOX/notes/archive/versions" \
         "$SBOX/дневник/выжимки" \
         "$SBOX/дневник/архив" \
         "$SBOX/дневник/отчёты" \
         "$SBOX/scratch"

say() {
  if [ "$4" = 1 ]; then printf '%-38s want=%-9s got=%-9s ✓\n' "$1" "$2" "$3"; PASS=$((PASS+1))
  else printf '%-38s want=%-9s got=%-9s ✗ FAIL\n' "$1" "$2" "$3"; FAILED=1; fi
}

run_gate() {  # $1 = absolute path inside the sandbox
  jq -nc --arg fp "$1" \
     '{hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$fp,content:"x"}}' |
  HOME="$SBOX" NAMING_GATE_PAUSE_FILE="$PAUSE" NAMING_GATE_ALLOW_FILE="$ALLOW" bash "$GATE"
}
run_gate_tool() {  # $1 = tool name, $2 = path
  jq -nc --arg t "$1" --arg fp "$2" \
     '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{file_path:$fp,content:"x"}}' |
  HOME="$SBOX" NAMING_GATE_PAUSE_FILE="$PAUSE" NAMING_GATE_ALLOW_FILE="$ALLOW" bash "$GATE"
}
run_gate_conf() {  # $1 = config path, $2 = file path
  # an explicit pass-through rather than a `NAMING_CONF=x run_gate …` env prefix: a prefix on a
  # FUNCTION call leaks into the rest of the shell in POSIX mode, which would silently repoint
  # every later test at the mutated config
  jq -nc --arg fp "$2" \
     '{hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$fp,content:"x"}}' |
  HOME="$SBOX" NAMING_GATE_PAUSE_FILE="$PAUSE" NAMING_GATE_ALLOW_FILE="$ALLOW" \
  NAMING_CONF="$1" bash "$GATE"
}
run_gate_raw() {  # $1 = literal stdin
  printf '%s' "$1" |
  HOME="$SBOX" NAMING_GATE_PAUSE_FILE="$PAUSE" NAMING_GATE_ALLOW_FILE="$ALLOW" bash "$GATE"
}
run_lint() {  # the repo lint, pointed at the example config; $@ = -n <path>...
  NAMING_CONF="$CONF" bash "$LINT" "$@"
}
verdict() { printf '%s' "$1" | grep -q '"permissionDecision": *"deny"' && echo DENY || echo OPEN; }
check() { [ "$2" = "$3" ] && say "$1" "$2" "$3" 1 || say "$1" "$2" "$3" 0; }

RS="$SBOX/notes/research"
PL="$SBOX/notes/plans/active"
DN="$SBOX/дневник"

# --- 0. the shipped scripts parse ------------------------------------------------
for s in naming-gate.sh naming-lint.sh; do
  bash -n "$SKILL_DIR/$s" 2>/dev/null && say "syntax_${s%.sh}" OK OK 1 || say "syntax_${s%.sh}" OK BROKEN 0
done
# a clone must ship no naming.conf — an installed gate stays inert until its owner writes one
[ -e "$SKILL_DIR/naming.conf" ] && say clone_ships_no_conf ABSENT PRESENT 0 || say clone_ships_no_conf ABSENT ABSENT 1

# --- 1. kebab date under a governed root -> deny -----------------------------------
check kebab_date_denied DENY "$(verdict "$(run_gate "$RS/2026-09-08-lead-sources.md")")"

# --- 2. canonical name -> allowed --------------------------------------------------
check canonical_allowed OPEN "$(verdict "$(run_gate "$RS/2026-09-08 Payments — lead sources for teachers.md")")"

# --- 3. every negative-list code blocks --------------------------------------------
# one representative name per code the gate can see; each must deny
CASES="braces:2026-09-08 {tool} — x.md
forbidden-char:2026-09-08 Search — a: colon.md
two-dashes:2026-09-08 Search — one — two.md
spaced-endash:2026-09-08 Search – dash.md
kebab-adr:ADR-0018-some-decision.md
slug-like:council-pricing-notes.md"
# IFS=newline + `set -f` rather than a pipe or a here-string: a pipe would run `check` in a
# subshell and lose PASS/FAILED, and `set -f` stops a name containing `*` from globbing
OLDIFS=$IFS; IFS=$'\n'; set -f
for row in $CASES; do
  code=${row%%:*}; nm=${row#*:}
  [ -n "$code" ] || continue
  check "code_${code}_denied" DENY "$(verdict "$(run_gate "$RS/$nm")")"
done
set +f; IFS=$OLDIFS

# --- 4. redundant folder genre -> deny ----------------------------------------------
check redundant_type_denied DENY "$(verdict "$(run_gate "$PL/2026-09-08 Search · Plan — redundant.md")")"
# ...including with no title after it, which the `*"· $GENRE"` arm of the case exists for
check redundant_type_at_end_denied DENY "$(verdict "$(run_gate "$PL/2026-09-08 Search · Plan.md")")"

# The genre word only counts inside a ` · ` Type slot. Everywhere else it is indistinguishable
# from a proper noun, and these folders are exactly where proper nouns carry it.
check title_ending_in_genre_ok OPEN "$(verdict "$(run_gate "$RS/2026-02-27 Spec-Driven TDD Gemini Deep Research.md")")"
check source_named_reference_ok OPEN "$(verdict "$(run_gate "$SBOX/notes/references/2026-03-01 The Swift Language Reference — value semantics.md")")"
check head_ending_in_genre_ok OPEN "$(verdict "$(run_gate "$RS/2026-09-08 Deep Research — agentic pipelines.md")")"
check tool_named_tool_ok OPEN "$(verdict "$(run_gate "$SBOX/notes/tools/2026-09-08 Clarity Tool — prose editor.md")")"

# a hyphenated identifier as the title is a compound, not a slug
check compound_title_ok OPEN "$(verdict "$(run_gate "$SBOX/notes/references/2026-09-08 Anthropic — claude-code-sdk.md")")"

# --- 5. scope: outside the governed roots -> never gated -----------------------------
check ungoverned_root_ignored OPEN "$(verdict "$(run_gate "$SBOX/scratch/2026-09-08-flight-log.md")")"
# the two roots the config excludes: tool exports and frozen versions
check imports_excluded OPEN "$(verdict "$(run_gate "$SBOX/notes/imports/2026-05-26/317373-2026-1341_export.md")")"
check archive_excluded OPEN "$(verdict "$(run_gate "$SBOX/notes/archive/versions/draft_for_review_v9.md")")"

# a `..` that leaves a governed root must not be judged by the root it started in
check dotdot_escapes_governed OPEN "$(verdict "$(run_gate "$SBOX/notes/audits/../../scratch/2026-09-08-flight-log.md")")"
# ...and the same when the parent does not exist yet, which is the arm that used to keep the
# `..` in the string: falling back to the raw dirname made this a live FALSE DENY
check dotdot_escapes_new_parent OPEN "$(verdict "$(run_gate "$SBOX/notes/audits/../../scratch/newdir/2026-09-08-flight-log.md")")"
# and one that ENTERS a governed root must be caught
check dotdot_enters_governed DENY "$(verdict "$(run_gate "$SBOX/scratch/../notes/plans/active/2026-09-08-bad.md")")"
# a file_path written with a leading ~/ resolves against $HOME before matching
# shellcheck disable=SC2088  # not expanding it here is the POINT — the gate must do that
check tilde_path_governed DENY "$(verdict "$(run_gate "~/notes/plans/2026-09-08-tilde.md")")"
# a RELATIVE path is ungoverned by design — it would resolve against the hook process's cwd
check relative_path_ungoverned OPEN "$(verdict "$(run_gate_raw '{"tool_name":"Write","tool_input":{"file_path":"notes/plans/2026-09-08-kebab.md"}}')")"

# --- 6. the non-ASCII tree ------------------------------------------------------------
# governed() matches this with a literal Cyrillic pattern and the lint measures its length in
# characters; a locale or encoding regression here would otherwise be silent
check nonascii_root_governed DENY "$(verdict "$(run_gate "$DN/отчёты/2026-09-08-otchet.md")")"
check nonascii_canonical_ok OPEN "$(verdict "$(run_gate "$DN/выжимки/2026-09-08 разговор с врачом.md")")"
# 60 Cyrillic characters is 120 bytes: UNDER the 100-character cap, OVER it if measured in
# bytes. The locale probe at the top of naming-lint.sh is the only reason this passes.
LONG=$(printf 'я%.0s' $(seq 1 60))
check nonascii_length_in_chars OPEN "$(verdict "$(run_gate "$DN/выжимки/2026-09-08 $LONG.md")")"
# ...and the cap itself, from both sides, so it cannot drift unnoticed
CAP=$(printf 'a%.0s' $(seq 1 100)); OVER=$(printf 'a%.0s' $(seq 1 101))
check too_long_at_cap_ok OPEN "$(verdict "$(run_gate "$RS/$CAP.md")")"
check too_long_over_denied DENY "$(verdict "$(run_gate "$RS/$OVER.md")")"

# --- 7. exempt subtrees inside a governed root -----------------------------------------
# each input WOULD be a finding without the exemption under test
check templates_exempt OPEN "$(verdict "$(run_gate "$SBOX/notes/templates/states_screen.md")")"                     # underscore
check baseline_bundle_exempt OPEN "$(verdict "$(run_gate "$SBOX/notes/plans/completed/2026-08-26-interfaces-baseline/2026-08-26-field-x.md")")"  # kebab-date
check allcaps_singleton_exempt OPEN "$(verdict "$(run_gate "$PL/README_old_notes.md")")"                            # underscore
check non_markdown_exempt OPEN "$(verdict "$(run_gate "$PL/2026-09-08-notes.txt")")"                                # kebab-date

# --- 8. an existing file is an overwrite, not a naming decision ---------------------------
touch "$RS/2026-09-08-already-here.md"
check existing_file_not_gated OPEN "$(verdict "$(run_gate "$RS/2026-09-08-already-here.md")")"

# --- 9. only Write is gated -----------------------------------------------------------------
for t in Edit MultiEdit Read Bash; do
  check "tool_${t}_ignored" OPEN "$(verdict "$(run_gate_tool "$t" "$RS/2026-09-08-kebab-name.md")")"
done

# --- 10. malformed or missing input must fail OPEN -------------------------------------------
i=0
for BADIN in 'not json at all' '{"tool_name":"Write"}' '{"tool_name":"Write","tool_input":{"file_path":null}}' '{}'; do
  i=$((i+1))
  check "malformed_input_${i}_open" OPEN "$(verdict "$(run_gate_raw "$BADIN")")"
done

# --- 11. a broken validator must fail OPEN ----------------------------------------------------
# The single most important safety property: the gate must never block a write because its own
# machinery died. Exercised by breaking the shell-out two ways.
rm -f "$SBOX/skill/naming-lint.sh"
check lint_missing_fails_open OPEN "$(verdict "$(run_gate "$RS/2026-09-08-lint-missing.md")")"
printf '#!/bin/bash\nif then fi ((\n' > "$SBOX/skill/naming-lint.sh"
check lint_broken_fails_open OPEN "$(verdict "$(run_gate "$RS/2026-09-08-lint-broken.md")")"
# Third break: the path exists but cannot be run as a script BY ANYONE. `chmod 000` is the
# obvious way to write this and the wrong one, twice over. It does nothing for root, and CI
# containers routinely run as root — so the lint keeps working and the assertion passes for no
# reason. And applied here it would have landed on the broken stub the previous case left
# behind, which is unrunnable already: an assertion that cannot fail. A DIRECTORY at that path
# is unrunnable for every user, root included, and does not depend on what was there before.
rm -f "$SBOX/skill/naming-lint.sh"; mkdir "$SBOX/skill/naming-lint.sh"
check lint_unrunnable_fails_open OPEN "$(verdict "$(run_gate "$RS/2026-09-08-lint-unrunnable.md")")"
rmdir "$SBOX/skill/naming-lint.sh"
# A lint that writes to stdout but says nothing the gate understands must also fail open.
# The second case is the sharp one: a stray TAB-bearing line has a field 2, and denying on it
# would produce a block with an EMPTY explanation — a deny with no stated reason.
printf '#!/bin/bash\nprintf "just noise\\n"\n' > "$SBOX/skill/naming-lint.sh"
check lint_nontsv_noise_open OPEN "$(verdict "$(run_gate "$RS/2026-09-08 Payments — fine one.md")")"
printf '#!/bin/bash\nprintf "p\\tmystery-code\\n"\n' > "$SBOX/skill/naming-lint.sh"
check lint_unknown_code_open OPEN "$(verdict "$(run_gate "$RS/2026-09-08 Payments — fine two.md")")"
cp "$LINT" "$SBOX/skill/naming-lint.sh"
check lint_restored DENY "$(verdict "$(run_gate "$RS/2026-09-08-lint-restored.md")")"

# --- 12. escape hatches -------------------------------------------------------------------------
touch "$PAUSE"
check pause_file_opens OPEN "$(verdict "$(run_gate "$RS/2026-09-08-paused-name.md")")"
# a stale pause must NOT disarm the gate forever
touch -t 202001010000 "$PAUSE"
check stale_pause_ignored DENY "$(verdict "$(run_gate "$RS/2026-09-08-stale-pause.md")")"
# nor may a FUTURE mtime make the pause permanent
touch -t 209901010000 "$PAUSE"
check future_pause_ignored DENY "$(verdict "$(run_gate "$RS/2026-09-08-future-pause.md")")"
# the window is four hours, pinned from both sides so it cannot drift
touch -t "$(date -v-239M +%Y%m%d%H%M 2>/dev/null || date -d '239 minutes ago' +%Y%m%d%H%M)" "$PAUSE"
check pause_within_4h_opens OPEN "$(verdict "$(run_gate "$RS/2026-09-08-pause-in-window.md")")"
touch -t "$(date -v-241M +%Y%m%d%H%M 2>/dev/null || date -d '241 minutes ago' +%Y%m%d%H%M)" "$PAUSE"
check pause_past_4h_rearms DENY "$(verdict "$(run_gate "$RS/2026-09-08-pause-expired.md")")"
# GNU coreutils reads `-f` as --file-system and then treats `%m` as a FILENAME OPERAND: it
# errors on that name, exits 1, and still prints the real file's filesystem block to STDOUT.
# So neither half of the obvious fallback works — the exit status is 1 whether the dialect is
# wrong or the file is missing, and stdout is populated either way. Without payload validation
# the arithmetic below gets a paragraph of text, aborts the pause check, and the gate DENIES
# with the hatch armed: broken on every Linux, and invisible on macOS without this shim.
mkdir -p "$SBOX/gnubin"
REAL_STAT=$(command -v stat)
# Ask the HOST which dialect it speaks, so the shim can still answer `-c %Y` with a real mtime
# whichever kind of stat is underneath. Validate the payload rather than the exit status, for
# exactly the reason above — this is the gate's own trick, used here to build its adversary.
_hm=$("$REAL_STAT" -f %m "$SBOX" 2>/dev/null)
case "$_hm" in ''|*[!0-9]*) HOST_F=-c; HOST_V=%Y ;; *) HOST_F=-f; HOST_V=%m ;; esac
# A faithful GNU shim, both halves: `-f %m` reproduces the measured behaviour (a non-numeric
# dump on stdout, exit 1), and `-c %Y` — which BSD stat does not accept at all — answers with
# the real mtime. A shim emulating only the first half would fail this test for the wrong
# reason; one hardcoding BSD for the second half passes on macOS and fails on Linux.
{ printf '#!/bin/sh\n'
  printf 'if [ "$1" = -f ]; then\n'
  printf '  shift; printf "stat: cannot read file system information for %%s\\n" "$1" >&2; shift\n'
  printf '  printf "  File: %%s\\n    ID: fc819e39c702003b Namelen: 255 Type: overlayfs\\n" "$1"\n'
  printf '  exit 1\n'
  printf 'fi\n'
  printf 'if [ "$1" = -c ] && [ "$2" = %%Y ]; then shift 2; exec %s %s %s "$@"; fi\n' "$REAL_STAT" "$HOST_F" "$HOST_V"
  printf 'exec %s "$@"\n' "$REAL_STAT"
} > "$SBOX/gnubin/stat"; chmod +x "$SBOX/gnubin/stat"
touch "$PAUSE"
OUT=$(jq -nc --arg fp "$RS/2026-09-08-gnu-stat.md" \
      '{hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$fp,content:"x"}}' |
      PATH="$SBOX/gnubin:$PATH" HOME="$SBOX" NAMING_GATE_PAUSE_FILE="$PAUSE" \
      NAMING_GATE_ALLOW_FILE="$ALLOW" bash "$GATE" 2>/dev/null)
check gnu_stat_pause_still_opens OPEN "$(verdict "$OUT")"
rm -f "$PAUSE"

touch "$ALLOW"
# a CONFORMING write must not eat the token — it is spent only on a real offence
check oneshot_survives_good_write OPEN "$(verdict "$(run_gate "$RS/2026-09-08 Payments — a fine name.md")")"
if [ -e "$ALLOW" ]; then say oneshot_not_eaten KEPT KEPT 1; else say oneshot_not_eaten KEPT GONE 0; fi
check oneshot_allow_opens OPEN "$(verdict "$(run_gate "$RS/2026-09-08-one-shot.md")")"
if [ ! -e "$ALLOW" ]; then say oneshot_consumed GONE GONE 1; else say oneshot_consumed GONE LEFT 0; fi
check oneshot_not_sticky DENY "$(verdict "$(run_gate "$RS/2026-09-08-after-oneshot.md")")"

# --- 13. the deny message has to be actionable ----------------------------------------------------
MSG=$(run_gate "$RS/2026-09-08-lead-sources.md" | jq -r '.hookSpecificOutput.permissionDecisionReason' 2>/dev/null)
if printf '%s' "$MSG" | grep -q 'grammar.md' &&
   printf '%s' "$MSG" | grep -q 'kebab-date' &&
   printf '%s' "$MSG" | grep -q 'Canonical form here'
then say deny_message_actionable FULL FULL 1; else say deny_message_actionable FULL THIN 0; fi

# --- 14. naming-lint -n contract --------------------------------------------------------------------
run_lint -n "$RS/2026-09-08 Payments — fine.md" > /dev/null 2>&1
[ $? -eq 0 ] && say lint_namemode_clean_rc0 RC0 RC0 1 || say lint_namemode_clean_rc0 RC0 RC1 0
run_lint -n "$RS/2026-09-08-bad.md" > /dev/null 2>&1
[ $? -eq 1 ] && say lint_namemode_finding_rc1 RC1 RC1 1 || say lint_namemode_finding_rc1 RC1 RC0 0
# -n must not require the path to exist (the whole point: the file is not written yet)
OUT=$(run_lint -n "$PL/no such file.md" 2>&1)
printf '%s' "$OUT" | grep -q 'no such path' && say lint_namemode_no_stat NOSTAT STAT 0 || say lint_namemode_no_stat NOSTAT NOSTAT 1

# --- 15. forbidden-char class parity --------------------------------------------------------------------
# The class is a bash bracket expression whose `]`-first / non-initial-`^` placement is easy to
# break silently, and a regression here is a false ALLOW on a Finder/Obsidian-breaking name.
PARITY=""
for ch in '\' ':' '*' '?' '"' '<' '>' '|' '#' '^' '[' ']'; do
  OUT=$(run_lint -n "$RS/2026-09-08 Search — a${ch}b.md" 2>/dev/null | awk -F'\t' '{print $2}')
  [ "$OUT" = forbidden-char ] || PARITY="$PARITY miss:$ch"
done
for ch in '(' ')' '!' '&' '%' '+' '=' ',' ';' '@' '~'; do
  OUT=$(run_lint -n "$RS/2026-09-08 Search — a${ch}b.md" 2>/dev/null)
  [ -z "$OUT" ] || PARITY="$PARITY over:$ch"
done
[ -z "$PARITY" ] && say forbidden_char_class_parity OK OK 1 || say forbidden_char_class_parity OK "BAD:$PARITY" 0

# --- 16. drift guard: config vs the grammar document -------------------------------------------------------
# The tables want to live in three copies (prose, lint, gate). Here there are two by
# construction — naming.conf for code, references/grammar.md for humans — and this guard pins
# exactly that pair, in both directions.
# Only the GRAMMAR tables are pinned. `governed` rows describe enforcement scope, which the
# grammar document says nothing about on purpose: which folders are gated is a risk decision,
# not something a reader needs in order to name a file correctly.
# The document's own table, isolated once: a `genre` row is pinned against THIS, not against
# the whole document, so a leaf that merely appears in the prose somewhere cannot stand in for
# a table row. `form` rows keep the looser whole-document check — they legitimately name
# folders the genre table does not list (evergreen, the catch-all).
RULE_TABLE=$(awk '/^## Default genre per folder/{f=1;next} /^## /{f=0} f && /^\|/' "$RULE")
MISSING=""
while IFS=$'\t' read -r kind glob val rest; do
  case "$kind" in genre|form) ;; *) continue ;; esac
  [ -n "$glob" ] && [ -n "$val" ] || continue
  [ "$glob" = '*' ] && continue                  # the catch-all names no folder to pin
  leaf=${glob%/\*}; leaf=${leaf##*/}
  [ -n "$leaf" ] || continue
  if [ "$kind" = form ]; then
    # -F, not a BRE: a leaf is a literal here, and a stray metacharacter in one would either
    # match loosely or hard-error under a grep that rejects an empty subexpression.
    grep -qF -- "$leaf" "$RULE" || MISSING="$MISSING rule:$leaf"
    continue
  fi
  # A genre row must name the SAME genre the document's table row does. Pinning the folder
  # alone leaves the mapping — the half of the table that actually carries meaning — free to
  # drift: repointing `plans/* -> Note` would pass.
  row=$(printf '%s\n' "$RULE_TABLE" | awk -F'|' -v l="$leaf" 'index($2,l)>0 {print $3; exit}')
  if [ -z "$row" ]; then MISSING="$MISSING table:$leaf"
  else case "$row" in *"$val"*) ;; *) MISSING="$MISSING pair:$leaf=$val" ;; esac; fi
done < "$CONF"
# ...and the other direction, or a row duplicated rather than deleted drops a folder from the
# table while the count below still passes: every folder the document gives a genre to must
# have a row in the config. Rows whose genre cell says "none" are the folders that
# deliberately have none (evergreen, the inbox catch-all).
GENRE_LEAVES=$(awk -F'\t' '$1=="genre"{g=$2; sub(/\/\*$/,"",g); sub(/.*\//,"",g); print g}' "$CONF")
OLDIFS=$IFS; IFS=$'\n'; set -f
for trow in $RULE_TABLE; do
  case "$trow" in *---*) continue ;; esac
  cell1=$(printf '%s' "$trow" | awk -F'|' '{print $2}')
  cell2=$(printf '%s' "$trow" | awk -F'|' '{print $3}')
  case "$cell1" in *Folder*) continue ;; esac
  case "$cell2" in *none*|*"no type"*) continue ;; esac
  for tok in $(printf '%s\n' "$cell1" | grep -o '`[^`]*`' | tr -d '`'); do
    tleaf=${tok%/\*}; tleaf=${tleaf%/}; tleaf=${tleaf##*/}   # `notes/plans/*` -> plans
    [ -n "$tleaf" ] || continue
    printf '%s\n' "$GENRE_LEAVES" | grep -qxF -- "$tleaf" || MISSING="$MISSING conf:$tleaf"
  done
done
set +f; IFS=$OLDIFS
[ -z "$MISSING" ] && say conf_matches_rule SYNC SYNC 1 || say conf_matches_rule SYNC "MISS:$(printf '%s' "$MISSING" | tr ' ' ',' | cut -c1-60)" 0

# the config must actually hold the tables — an empty parse would make every check above vacuous
NG=$(grep -c "^genre	" "$CONF"); NV=$(grep -c "^governed	" "$CONF"); NF=$(grep -c "^form	" "$CONF")
if [ "$NG" -ge 10 ] && [ "$NV" -ge 4 ] && [ "$NF" -ge 13 ]
then say conf_tables_populated "10/4/13+" "$NG/$NV/$NF" 1
else say conf_tables_populated "10/4/13+" "$NG/$NV/$NF" 0; fi
# a glob with an unescaped alternation would silently never match — bash `case` does not honour
# `|` inside a variable expansion, so an author who writes one gets no match and no error
grep -E "^(genre|governed|form)	[^	]*\|" "$CONF" > /dev/null \
  && say conf_no_alternation NONE FOUND 0 || say conf_no_alternation NONE NONE 1
# Every root the config marks `yes` must really deny. This is the check with teeth: the value
# column is one word of text, and a trailing space or a CRLF line ending used to make it compare
# unequal to `yes` and ungovern the whole root silently — failing open, which is the safe
# direction, but invisibly. Driven from the config so a root added later is covered for free.
OLDIFS=$IFS; IFS=$'\n'; set -f
for grow in $(grep "^governed	" "$CONF"); do
  gglob=$(printf '%s' "$grow" | awk -F'	' '{print $2}')
  gval=$(printf '%s' "$grow" | awk -F'	' '{print $3}')
  [ "$gval" = yes ] || continue
  gdir="$SBOX${gglob#\~}"; gdir=${gdir%/\*}
  mkdir -p "$gdir" 2>/dev/null
  check "governed_${gdir##*/}_denies" DENY "$(verdict "$(run_gate "$gdir/2026-09-08-bad-name.md")")"
done
set +f; IFS=$OLDIFS

# --- 17. degradation: a broken table must not block anything -------------------------------------------
# A blocking gate may never deny because its own config broke. Both consumers degrade instead.
rm -f "$SBOX/skill/naming.conf"
check no_conf_gate_fails_open OPEN "$(verdict "$(run_gate "$PL/2026-09-08-no-conf.md")")"
# ...and the lint keeps its whole negative list, losing only the config-dependent check
OUT=$(NAMING_CONF=/nonexistent bash "$LINT" -n "$RS/2026-09-08-kebab.md" 2>/dev/null | awk -F'\t' '{print $2}')
[ "$OUT" = kebab-date ] && say no_conf_lint_still_checks kebab-date "$OUT" 1 || say no_conf_lint_still_checks kebab-date "$OUT" 0
OUT=$(NAMING_CONF=/nonexistent bash "$LINT" -n "$PL/2026-09-08 Search · Plan — x.md" 2>/dev/null)
[ -z "$OUT" ] && say no_conf_drops_redundant_only NONE NONE 1 || say no_conf_drops_redundant_only NONE "$OUT" 0
# a malformed row is skipped, not fatal
BADCONF="$SBOX/bad.conf"
printf 'genre\n\t\t\ngenre\t*/notes/plans/*\tPlan\n' > "$BADCONF"
OUT=$(NAMING_CONF="$BADCONF" bash "$LINT" -n "$PL/2026-09-08 Search · Plan — x.md" 2>/dev/null | awk -F'\t' '{print $2}')
[ "$OUT" = redundant-type ] && say malformed_row_skipped redundant-type "$OUT" 1 || say malformed_row_skipped redundant-type "$OUT" 0
# a governed value that is neither yes nor no is treated as `no` — excluded, so the gate fails
# open — and says so on stderr rather than looking like a table that was never there
printf 'governed\t~/notes/plans/*\tmaybe\n' > "$BADCONF"
ERR=$(run_gate_conf "$BADCONF" "$PL/2026-09-08-bad-value.md" 2>&1 >/dev/null)
OUT=$(run_gate_conf "$BADCONF" "$PL/2026-09-08-bad-value.md" 2>/dev/null)
LOUD=SILENT
case "$ERR" in *"neither yes nor no"*) LOUD=LOUD ;; esac
check bad_governed_value_open_and_loud "OPEN-LOUD" "$(verdict "$OUT")-$LOUD"
# a last row with no trailing newline must still count — `read` returns false on it
printf 'genre\t*/notes/plans/*\tPlan' > "$BADCONF"
OUT=$(NAMING_CONF="$BADCONF" bash "$LINT" -n "$PL/2026-09-08 Search · Plan — x.md" 2>/dev/null | awk -F'\t' '{print $2}')
[ "$OUT" = redundant-type ] && say final_row_no_newline_kept redundant-type "$OUT" 1 || say final_row_no_newline_kept redundant-type "$OUT" 0
# a CRLF-authored config must not silently ungovern a root
printf 'governed\t~/notes/plans/*\tyes\r\n' > "$BADCONF"
check crlf_config_still_governs DENY "$(verdict "$(run_gate_conf "$BADCONF" "$PL/2026-09-08-crlf.md" 2>/dev/null)")"
# nor may a trailing SPACE — the anecdote the README is built on, and it had no test
printf 'governed\t~/notes/plans/*\tyes \n' > "$BADCONF"
check trailing_space_after_yes DENY "$(verdict "$(run_gate_conf "$BADCONF" "$PL/2026-09-08-trailing-space.md" 2>/dev/null)")"
# a CRLF-authored GENRE row must still drive redundant-type: `Plan\r` can never match `· Plan`
printf 'genre\t*/notes/plans/*\tPlan\r\n' > "$BADCONF"
OUT=$(NAMING_CONF="$BADCONF" bash "$LINT" -n "$PL/2026-09-08 Search · Plan — x.md" 2>/dev/null | awk -F'\t' '{print $2}')
[ "$OUT" = redundant-type ] && say crlf_genre_row_parses redundant-type "$OUT" 1 || say crlf_genre_row_parses redundant-type "$OUT" 0
# A config the gate cannot read is the same as a missing one: govern nothing. Broken with a
# DIRECTORY rather than `chmod 000` for the same reason as the lint above — mode bits do not
# stop root, so under CI that spelling would load the config normally and assert nothing. A
# directory passes `[ -r ]` and then fails the redirect, leaving the tables empty.
mkdir -p "$SBOX/conf-as-a-directory"
check conf_unreadable_fails_open OPEN "$(verdict "$(run_gate_conf "$SBOX/conf-as-a-directory" "$PL/2026-09-08-conf-unreadable.md" 2>/dev/null)")"
# the `doc` record type: a row points the deny message at the reader's own document...
printf 'doc\thttps://example.com/g.md\ngoverned\t~/notes/plans/*\tyes\n' > "$BADCONF"
MSG=$(run_gate_conf "$BADCONF" "$PL/2026-09-08-doc-row.md" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecisionReason')
case "$MSG" in *'https://example.com/g.md'*) say doc_row_used OK OK 1 ;; *) say doc_row_used OK MISSING 0 ;; esac
# ...and with no row it falls back to the grammar document BESIDE the scripts, not to an
# install path, which is what lets the bundle be moved anywhere as a whole
printf 'governed\t~/notes/plans/*\tyes\n' > "$BADCONF"
MSG=$(run_gate_conf "$BADCONF" "$PL/2026-09-08-doc-default.md" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecisionReason')
case "$MSG" in *"$SBOX/skill/references/grammar.md"*) say doc_default_is_sibling OK OK 1 ;; *) say doc_default_is_sibling OK ELSEWHERE 0 ;; esac
cp "$CONF" "$SBOX/skill/naming.conf"
check conf_restored DENY "$(verdict "$(run_gate "$PL/2026-09-08-conf-restored.md")")"

# --- 18. sweep mode: the OTHER caller of the same negative list --------------------------------
# Every assertion above drives `-n`. Sweep mode is what the gate's own KNOWN GAP defers to
# (a file written through Bash) and what SKILL.md hands agents, so it needs its own coverage.
mkdir -p "$SBOX/notes/plans/templates"
: > "$SBOX/notes/plans/active/2026-09-08-sweep-kebab.md"
: > "$SBOX/notes/plans/active/2026-09-08 Payments — sweep clean.md"
: > "$SBOX/notes/plans/active/2026-09-08-sweep-kebab.txt"                # non-.md, exempt
: > "$SBOX/notes/plans/templates/sweep_skipped.md"                       # underscore, exempt
: > "$SBOX/notes/plans/completed/2026-08-26-interfaces-baseline/2026-08-26-frozen.md"
OUT=$(NAMING_CONF="$CONF" bash "$LINT" "$SBOX/notes/plans" 2>/dev/null); RC=$?
check sweep_rc_on_findings 1 "$RC"
check sweep_finds_kebab 1 "$(printf '%s\n' "$OUT" | grep -c 'sweep-kebab\.md')"
printf '%s' "$OUT" | grep -q 'sweep_skipped\|frozen\|\.txt' \
  && say sweep_honours_exemptions CLEAN LEAKED 0 || say sweep_honours_exemptions CLEAN CLEAN 1
OUT=$(NAMING_CONF="$CONF" bash "$LINT" -q "$SBOX/notes/plans" 2>/dev/null)
[ -z "$OUT" ] && say sweep_quiet_silent_stdout NONE NONE 1 || say sweep_quiet_silent_stdout NONE "$OUT" 0
# outside -n a path that does not exist is a usage error, not a finding
NAMING_CONF="$CONF" bash "$LINT" "$SBOX/nope" >/dev/null 2>&1
check sweep_missing_path_rc2 2 "$?"

printf '\nnaming-gate fixtures: %d passed, %s\n' "$PASS" "$([ $FAILED -eq 0 ] && echo 'all green' || echo 'FAILURES')"
exit $FAILED
