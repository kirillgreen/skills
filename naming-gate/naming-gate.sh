#!/usr/bin/env bash
# naming-gate.sh — refuse to CREATE a file whose name breaks your naming grammar.
#
# WHY: a naming convention that lives only in a document drifts by default. Agents imitate
# their neighbours, so the first non-conforming file breeds more, and the drift is visible
# only when somebody remembers to run a lint. A document tells an agent what to do; this
# hook is what makes it true at the moment the name is chosen.
#
# WHAT IT CHECKS: nothing of its own. It shells out to naming-lint.sh -n, the same negative
# list a periodic sweep uses, so the gate and the sweep cannot drift apart. A finding is a
# deny carrying the offending codes and the folder's canonical form.
#
# SCOPE — deliberately narrow, because a false deny costs real work:
#   * Write only. Edit/MultiEdit target a path that already exists; renaming is not their job.
#   * Only under the roots the `governed` rows of naming.conf mark `yes` (that file is the
#     whole list; this header does not repeat it). THE INVARIANT FOR ADDING ONE: its existing
#     corpus must already lint clean (`naming-lint.sh <root>` → 0 findings). Govern a root
#     whose neighbours are non-conforming and the gate denies a name that matches every file
#     around it — which is how a gate gets switched off permanently on its second day.
#   * Only for a path that does not exist yet. Overwriting a file is not a naming choice.
#   * Only for an ABSOLUTE path. A relative file_path would resolve against the hook process's
#     working directory, which is not the agent's project root, so it is left ungoverned.
#   * templates/, *-baseline/, .claude/, ALLCAPS singletons and non-.md files are exempt —
#     that logic lives in naming-lint.sh and is not repeated here.
#
# KNOWN GAP (by design): a file created through Bash (`cat > x.md`, `mv`, a script) is not
# seen. Covering that needs either command-string guessing or a snapshot diff, and neither is
# worth the complexity while the agent writes artefacts through the Write tool. A periodic
# `naming-lint.sh <dir>` sweep is what catches whatever gets in some other way.
#
# ESCAPE (a Write carries no command line, so there is no env-prefix idiom here):
#   touch /tmp/.naming-gate-allow    one-shot, consumed ONLY on a real offence, so a
#                                    conforming write earlier in the turn cannot eat it
#   touch /tmp/.naming-gate-paused   pauses this gate for 4h from its mtime; stale = ignored
# Both are the HUMAN's to create. An agent that creates its own escape hatch has no gate —
# say so in the instructions you give it, because nothing here can enforce that.
#
# Input: PreToolUse hook JSON on stdin. Output: permissionDecision JSON, exit 0 (a non-zero
# exit from a hook is always an accident). Every failure of the gate's own machinery — no jq,
# no lint, broken lint, malformed input, missing config, malformed row, a code this gate cannot
# explain — must fail OPEN.
# Tests: tests/run.sh

set -u

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
LINT="$SELF_DIR/naming-lint.sh"
PAUSE_FILE="${NAMING_GATE_PAUSE_FILE:-/tmp/.naming-gate-paused}"
ALLOW_FILE="${NAMING_GATE_ALLOW_FILE:-/tmp/.naming-gate-allow}"

INPUT=$(cat)

# Two plain jq calls rather than one @tsv read: @tsv escapes a tab, newline or backslash in
# the path into a two-character sequence, and the consumer would have to decode it back.
# The second call only runs on a Write, and the whole hook measures ~40 ms against timeout 5.
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "${TOOL:-}" = "Write" ] || exit 0
FP=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
[ -n "${FP:-}" ] || exit 0

# Normalize before matching: a path carrying `..` can otherwise point into an ungoverned tree
# while still matching a governed prefix (notes/../../scratch/…) — a false deny — or the
# reverse. `pwd -P` also collapses the parent's symlinks.
# shellcheck disable=SC2088  # the quoted `~/` is a PATTERN matching a literal tilde in the
                             # incoming path; the expansion is done by hand on the next line
case "$FP" in "~/"*) FP="$HOME/${FP#\~/}" ;; esac
case "$FP" in /*) ;; *) exit 0 ;; esac      # relative: see SCOPE — ungoverned, fails open
# A Write may create its own parent directory, so `cd` to the dirname can fail. Canonicalizing
# the nearest ancestor that DOES exist and re-attaching the missing tail is what makes that case
# safe: simply falling back to the raw dirname leaves the `..` in the string, and a path that
# escapes a governed root then still matches the prefix it started under — a live false deny.
_d=$(dirname -- "$FP"); _tail=
while [ ! -d "$_d" ] && [ "$_d" != / ] && [ "$_d" != . ]; do
  _tail="${_d##*/}/$_tail"; _d=$(dirname -- "$_d")
done
_d=$( (cd -- "$_d" 2>/dev/null && pwd -P) || printf '%s' "$_d" )
FP="$_d/$_tail$(basename -- "$FP")"
FP=${FP//\/\//\/}

# --- the tables ---------------------------------------------------------------
# The governed-root list, the per-folder canonical forms and the pointer to your grammar
# document all live in naming.conf, alongside the genre table naming-lint.sh reads. Order
# inside each record type is the semantics: FIRST MATCH WINS, so exclusions precede catch-alls.
# A missing or unreadable config leaves the tables empty, which governs nothing and so fails
# open — the same direction every other failure in this hook takes. That is also what a fresh
# install does: copy naming.conf.example to naming.conf and the gate stays inert until you
# mark a root `yes`.
NAMING_CONF="${NAMING_CONF:-$SELF_DIR/naming.conf}"
GOV_GLOB=(); GOV_VAL=(); FORM_GLOB=(); FORM_VAL=(); DOC=
if [ -r "$NAMING_CONF" ]; then
  # `|| [ -n "$_kind" ]` keeps the last row when the file ends without a newline — read
  # returns false there, and the row would otherwise be dropped with nothing to see
  while IFS=$'\t' read -r _kind _glob _val _rest || [ -n "${_kind:-}" ]; do
    _val=${_val%$'\r'}                                       # a CRLF-authored config must still parse
    case "${_kind:-}" in
      doc) [ -n "${_glob:-}" ] && [ -z "$DOC" ] && DOC=${_glob%$'\r'}; continue ;;
    esac
    [ -n "${_glob:-}" ] && [ -n "${_val:-}" ] || continue     # a malformed row is skipped, never fatal
    case "${_kind:-}" in
      governed)
        # yes/no decides whether a whole root is judged, so it must not be defeated by invisible
        # whitespace: a single trailing space used to make `yes` compare unequal and silently
        # ungovern the root, with nothing to see in the file. Strip it, and treat anything that is
        # still neither yes nor no as `no` — excluding a root fails OPEN, which is the direction
        # every other failure in this hook takes, and the note on stderr is what makes it visible.
        _val=${_val//[$'\r'$'\t' ]/}
        case "$_val" in
          yes|no) ;;
          *) printf 'naming-gate: %s: governed value [%s] for %s is neither yes nor no — treating as no\n' \
                    "$NAMING_CONF" "$_val" "$_glob" >&2
             _val=no ;;
        esac
        GOV_GLOB+=("${_glob/#\~/$HOME}");  GOV_VAL+=("$_val") ;;
      form)     FORM_GLOB+=("${_glob/#\~/$HOME}"); FORM_VAL+=("$_val") ;;
    esac
  done < "$NAMING_CONF"
fi
[ -n "$DOC" ] || DOC="$SELF_DIR/references/grammar.md"
DOC=${DOC/#\~/$HOME}      # a path may be written with ~; a URL has no ~ to expand

governed() {
  local i
  for (( i = 0; i < ${#GOV_GLOB[@]}; i++ )); do
    # unquoted on purpose — an unquoted expansion in a case pattern is matched AS a pattern
    # shellcheck disable=SC2254
    case "$1" in
      ${GOV_GLOB[$i]}) [ "${GOV_VAL[$i]}" = yes ] && return 0 || return 1 ;;
    esac
  done
  return 1
}

governed "$FP" || exit 0
[ -e "$FP" ] && exit 0          # overwriting an existing file is not a naming decision

# --- pause -------------------------------------------------------------------
fresh() {   # fresh <file> <seconds>
  [ -e "$1" ] || return 1
  local m now age
  # BSD stat first, GNU second — but the EXIT STATUS cannot arbitrate between the dialects.
  # Measured on GNU coreutils 9.7: `-f` is read as --file-system and `%m` as a FILENAME, so
  # stat errors on that name, exits 1, AND still prints the real file's filesystem block to
  # stdout. Status 1 therefore means either "wrong dialect" or "no such file", and stdout is
  # populated either way — `cmd || fallback` inside one substitution concatenates the two, and
  # the arithmetic below then aborts the enclosing `if`: the gate denies with a pause armed,
  # the hatch silently broken on every Linux. So validate the PAYLOAD, which is unambiguous:
  # anything non-numeric means that dialect did not answer, whatever it exited with.
  m=$(stat -f %m "$1" 2>/dev/null)
  case "$m" in ''|*[!0-9]*) m=$(stat -c %Y "$1" 2>/dev/null) ;; esac
  case "$m" in
    ''|*[!0-9]*)
      printf 'naming-gate: cannot read the mtime of %s — the pause is NOT in effect\n' "$1" >&2
      return 1 ;;
  esac
  now=$(date +%s)
  age=$(( now - m ))
  # a FUTURE mtime must not make a pause permanent: negative age is not "fresh"
  [ "$age" -ge 0 ] && [ "$age" -lt "$2" ]
}

if [ -e "$PAUSE_FILE" ] && fresh "$PAUSE_FILE" 14400; then exit 0; fi

# --- validate ----------------------------------------------------------------
# Fails open by construction: a lint that is missing, unreadable or broken writes nothing to
# stdout. The vocabulary filter is the other half of that: only a code this gate can EXPLAIN is
# allowed to deny. A lint mid-edit, or one upgraded ahead of the gate, can emit a stray
# TAB-bearing line whose field 2 would otherwise produce a deny with an EMPTY reason block —
# a blocked write with nothing said about why, which is the worst deny there is.
RAW=$(bash "$LINT" -n "$FP" 2>/dev/null | awk -F'\t' '{print $2}' | sort -u)
CODES=
OLDIFS=$IFS; IFS=$'\n'; set -f      # one token per line, and no globbing of stray noise
for c in $RAW; do
  case "$c" in
    kebab-date|kebab-adr|slug-like|braces|underscore|two-dashes|spaced-endash|forbidden-char|too-long|redundant-type)
      CODES="$CODES$c " ;;
    '') ;;
    *) printf 'naming-gate: %s reported unknown code [%s] — ignoring\n' "$LINT" "$c" >&2 ;;
  esac
done
set +f; IFS=$OLDIFS
CODES=${CODES% }
[ -n "$CODES" ] || exit 0

# --- one-shot exception ------------------------------------------------------
# Spent only once the offence is real. Consuming it earlier would let any conforming write in
# the same turn eat the token before the exceptional name is ever attempted.
if [ -e "$ALLOW_FILE" ]; then
  rm -f "$ALLOW_FILE" 2>/dev/null
  exit 0
fi

# --- the canonical form for THIS folder --------------------------------------
# Presentation only; the authority is your grammar document. The rows are ordered from most
# specific to least, and the last one should be a `*` catch-all, so the fallback below fires
# only when the config yields no form rows at all — missing, unreadable, empty or truncated.
form_for() {
  local i
  for (( i = 0; i < ${#FORM_GLOB[@]}; i++ )); do
    # shellcheck disable=SC2254  # matched AS a pattern, same as governed() above
    case "$1" in ${FORM_GLOB[$i]}) printf '%s\n' "${FORM_VAL[$i]}"; return ;; esac
  done
  printf '%s\n' "see $DOC"
}

explain() {   # one line per code actually found
  local c
  for c in $1; do
    case "$c" in
      kebab-date)     echo '  kebab-date — the date is glued to the title with a hyphen; put a space after it' ;;
      kebab-adr)      echo '  kebab-adr — ADR-NNNN is glued to the title with a hyphen; put a space after it' ;;
      slug-like)      echo '  slug-like — the whole name is a kebab slug; write it as words' ;;
      braces)         echo '  braces — { } are forbidden (zsh brace expansion, template placeholders)' ;;
      underscore)     echo '  underscore — _ in a prose name; only an ALLCAPS constant may carry one' ;;
      two-dashes)     echo '  two-dashes — more than one " — "; exactly one separates head from title' ;;
      spaced-endash)  echo '  spaced-endash — " – " is not a separator; the en-dash is for ranges, unspaced' ;;
      forbidden-char) echo '  forbidden-char — one of \ : * ? " < > | # ^ [ ] breaks Finder or Obsidian' ;;
      too-long)       echo '  too-long — over the 100-character hard stop (the name without its extension)' ;;
      redundant-type) echo "  redundant-type — this folder's genre is implicit; do not write it into the name" ;;
    esac
  done
}

REASON="Blocked: this filename breaks the naming grammar ($DOC).

  $(basename -- "$FP")

$(explain "$CODES")
Canonical form here: $(form_for "$FP")

Rename and write again. If this name is a deliberate exception, ask the human to \`touch $ALLOW_FILE\` (one-shot, consumed on use) — never create that file yourself."

jq -n --arg r "$REASON" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
