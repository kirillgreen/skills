#!/usr/bin/env bash
# naming-lint.sh — validate artefact filenames against a naming grammar.
#
# The grammar shipped alongside this script (references/grammar.md) is an EXAMPLE.
# Replace it with your own. The machinery does not care what your convention is; it
# cares that the ways a name can break it are enumerated, which is what this file is.
#
# WHY A NEGATIVE LIST AND NOT A REGEX. A grammar's parse expression has a catch-all
# title slot, so it accepts a kebab slug exactly as happily as a canonical name —
# parsing is not validating. So validation is the enumerated set of ways a name goes
# wrong, each with a code the caller can quote back:
#
#   kebab-date      2026-09-05-quarterly-review   date glued to the title with a hyphen
#   kebab-adr       ADR-0015-some-decision        series number glued with a hyphen
#   slug-like       three or more lowercase ASCII words joined by hyphens
#   braces          { or } anywhere (template-placeholder collision; zsh brace expansion)
#   underscore      _ in a prose name (an ALLCAPS token like API_NOTES is a constant, exempt)
#   two-dashes      more than one " — "
#   spaced-endash   " – " (the en-dash is for ranges only, unspaced: 27.07–06.08)
#   forbidden-char  any of  \ : * ? " < > | # ^ [ ]
#   too-long        stem longer than 100 characters
#   redundant-type  the folder's default genre written into the head (plans/… · Plan — …)
#
# redundant-type is the one POSITIVE check, and the only one that needs configuration:
# it reads which folder implies which genre from naming.conf. The mirror-image check —
# Type MISSING where the folder has no default — is deliberately absent. Telling a Type
# word from a title word needs a closed vocabulary and still guesses, and this list feeds
# a BLOCKING hook where a false positive costs real work.
#
# Usage:  naming-lint.sh [-a] [-q] <dir|file>...
#         naming-lint.sh -n <path>...          check names only, paths need not exist
#   -a   lint every regular file, not only *.md
#   -q   quiet: print only the summary line
#   -n   name mode: validate each argument as a path STRING (no disk access, no recursion).
#        This is the mode naming-gate.sh calls, so the blocking gate and any periodic
#        sweep can never drift apart: one negative list, two callers.
# Skips hidden files, ALLCAPS singletons (README, CLAUDE.md, *_META.md, INDEX.md …), any
# *-baseline/ bundle, and the directories .git .obsidian node_modules .worktrees .archive
# _site .trash templates .claude — plus the names in $NAMING_LINT_SKIP, a |-separated list.
# Output: one "path<TAB>code" line per finding on stdout, a summary on stderr, exit 1 on findings.
# Config: $NAMING_CONF, default naming.conf beside this script. Missing is fine — see below.
# Tests:  tests/run.sh covers both modes.

set -u

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# Character semantics, not bytes: the 100-character check and every non-ASCII name depend
# on ${#stem} counting characters. A hardcoded en_US.UTF-8 is absent from minimal Linux
# images, so probe rather than assume — the string below is two characters and four bytes,
# which tells the two worlds apart with no fork. If nothing UTF-8 is installed the inherited
# locale is restored and only `too-long` degrades (a non-Latin name is measured in bytes and
# so trips the 100 cap early); every other check is byte-safe.
_probe='ää'; _orig_lc=${LC_ALL-}; _lc_ok=0
# Check the INHERITED locale FIRST. bash keeps the previous locale when setlocale() fails, so a
# probe taken after an export cannot tell "this locale works" from "the old one still does" —
# breaking there would pin an LC_ALL the system does not have, which every child process
# (sed, awk, sort) then silently falls back to C on, with a setlocale warning per invocation.
if [ ${#_probe} -eq 2 ]; then
  _lc_ok=1
else
  for _loc in "${NAMING_LINT_LOCALE:-}" en_US.UTF-8 C.UTF-8 en_US.utf8 C.utf8; do
    [ -n "$_loc" ] || continue
    export LC_ALL="$_loc"
    if [ ${#_probe} -eq 2 ]; then _lc_ok=1; break; fi
  done
  if [ $_lc_ok -eq 0 ]; then
    if [ -n "$_orig_lc" ]; then export LC_ALL="$_orig_lc"; else unset LC_ALL; fi
  fi
fi

all=0; quiet=0; namemode=0
while getopts "aqn" opt; do
  case $opt in
    a) all=1 ;;
    q) quiet=1 ;;
    n) namemode=1 ;;
    *) echo "usage: naming-lint.sh [-a] [-q] [-n] <dir|file>..." >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
[ $# -ge 1 ] || { echo "usage: naming-lint.sh [-a] [-q] [-n] <dir|file>..." >&2; exit 2; }
if [ $namemode -eq 0 ]; then
  for arg in "$@"; do [ -e "$arg" ] || { echo "naming-lint: no such path: $arg" >&2; exit 2; }; done
fi

# `templates/` names encode the pattern they produce, and `.claude/` holds skill, agent and
# agent-memory files — neither is an artefact, so both are exempt here rather than in every
# caller's filter.
skip_dirs='.git|.obsidian|node_modules|.worktrees|.archive|_site|.trash|templates|.claude'
[ -n "${NAMING_LINT_SKIP:-}" ] && skip_dirs="$skip_dirs|${NAMING_LINT_SKIP}"

# ALLCAPS means "entry point, one per folder" — a singleton is named by its role, not by the
# grammar. Add your own to this list rather than working around it in a config.
is_singleton() {
  case "$1" in
    README*|CLAUDE.md|AGENTS.md|*_META.md|*_Meta.md|INDEX.md|DESIGN.md|PRODUCT.md|VISION.md|\
    ARCHITECTURE.md|API.md|CHANGELOG*|LICENSE*|CONTRIBUTING*|SECURITY.md)
      return 0 ;;
  esac
  return 1
}

in_skipped_dir() {
  local p="/$1/" name rc=1
  # a frozen bundle keeps the names it was captured with
  case "$p" in *-baseline/*) return 0 ;; esac
  local IFS='|'
  # `set -f` because the split words are still subject to pathname expansion: an entry with a
  # glob character in $NAMING_LINT_SKIP would otherwise expand against the current directory
  # and skip whatever happened to match there. Restored below, never left on.
  set -f
  for name in $skip_dirs; do
    case "$p" in */"$name"/*) rc=0; break ;; esac
  done
  set +f
  return $rc
}

# The default-genre table lives in naming.conf, not here — it used to exist in three copies
# (the prose table a human reads, this function, and the gate's form hints) and a test had to
# police the divergence. Loaded once; a missing or unreadable config leaves the table empty,
# which costs only the redundant-type check. Every other check is config-free by design, so
# the lint degrades rather than failing.
NAMING_CONF="${NAMING_CONF:-$SELF_DIR/naming.conf}"
GENRE_GLOB=(); GENRE_VAL=()
if [ -r "$NAMING_CONF" ]; then
  # `|| [ -n "$_kind" ]` keeps the last row when the file ends without a newline — read
  # returns false there, and the row would otherwise be dropped with nothing to see
  while IFS=$'\t' read -r _kind _glob _val _rest || [ -n "${_kind:-}" ]; do
    [ "${_kind:-}" = genre ] || continue
    _val=${_val%$'\r'}                                         # a CRLF-authored config still parses
    [ -n "${_glob:-}" ] && [ -n "${_val:-}" ] || continue      # a malformed row is skipped, never fatal
    GENRE_GLOB+=("${_glob/#\~/$HOME}")
    GENRE_VAL+=("$_val")
  done < "$NAMING_CONF"
fi

# Sets GENRE to the implicit Type of the folder holding $1, or to the empty string when the
# folder has none — there the Type is always written, so nothing can be redundant.
# Assigns rather than echoes on purpose: a $(…) here forks a subshell per file, which turned a
# 3-second sweep over a 600-file tree into minutes when this check was first added.
default_genre_of() {
  local i
  GENRE=
  for (( i = 0; i < ${#GENRE_GLOB[@]}; i++ )); do
    # unquoted on purpose — an unquoted expansion in a case pattern is matched AS a pattern
    # shellcheck disable=SC2254
    case "/$1" in ${GENRE_GLOB[$i]}) GENRE=${GENRE_VAL[$i]}; return ;; esac
  done
}

findings=0; files=0; GENRE=
report() {
  findings=$((findings + 1))
  [ $quiet -eq 1 ] || printf '%s\t%s\n' "$1" "$2"
}

sep=' — '

# check_path <path> — the negative list over one path string. Nothing here touches the disk,
# so the caller decides whether the path has to exist.
check_path() {
  local path=$1 name stem rest t n prose
  in_skipped_dir "$path" && return 0
  name=${path##*/}
  case "$name" in .*) return 0 ;; esac
  if [ $all -eq 0 ]; then case "$name" in *.md) ;; *) return 0 ;; esac; fi
  is_singleton "$name" && return 0
  files=$((files + 1))
  stem=${name%.*}

  [[ $stem =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]] && report "$path" kebab-date
  [[ $stem =~ ^ADR-[0-9]{4}- ]] && report "$path" kebab-adr

  # slug-like = the whole title slot is one kebab run. The slot is what follows the first
  # " — " (or the key when there is no head), minus a trailing (qualifier). A hyphenated
  # compound inside a sentence (willingness-to-pay, text-to-graph) is not a slug.
  case "$stem" in
    *"$sep"*) rest=${stem#*"$sep"} ;;
    *) rest=$stem
       [[ $rest =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}(.*)$ ]] && rest=${BASH_REMATCH[1]}
       [[ $rest =~ ^ADR-[0-9]{4}(.*)$ ]] && rest=${BASH_REMATCH[1]} ;;
  esac
  rest=${rest%% (*}
  rest=${rest# }
  # Only when the name has NO head. With a head the name already has structure, and a title
  # that IS one hyphenated identifier is a compound, not a slug — `2026-09-08 Anthropic —
  # claude-code-sdk.md` is exactly the shape a references folder produces. Checked against
  # every real finding in a 640-file corpus: none is lost by this guard.
  case "$stem" in
    *"$sep"*) ;;
    *) [[ $rest =~ ^[a-z][a-z0-9]*(-[a-z0-9]+){2,}$ ]] && report "$path" slug-like ;;
  esac

  case "$stem" in *[{}]*) report "$path" braces ;; esac
  # an underscore inside an ALLCAPS token (API_NOTES, HTTP_CACHE) is a constant's name, not prose
  if [[ $stem == *_* ]]; then
    prose=$(printf '%s' "$stem" | LC_ALL=C sed -E 's/[A-Z0-9]+(_[A-Z0-9]+)+//g')
    [[ $prose == *_* ]] && report "$path" underscore
  fi

  t=${stem//"$sep"/}
  n=$(( (${#stem} - ${#t}) / ${#sep} ))
  [ "$n" -gt 1 ] && report "$path" two-dashes

  case "$stem" in *' – '*) report "$path" spaced-endash ;; esac
  # a bash case, not `printf | grep` — this runs on every file of a 600+ file sweep and on every
  # Write the gate sees, and a fork per file is the whole cost of the pass. Equivalence with the
  # obvious grep class is asserted in tests/run.sh (forbidden_char_class_parity).
  case "$stem" in *[]\\:*?\"\<\>\|\#^[]*) report "$path" forbidden-char ;; esac
  [ ${#stem} -gt 100 ] && report "$path" too-long

  # the folder's own genre must not be repeated in the head: plans/… · Plan — …
  default_genre_of "$path"
  if [ -n "$GENRE" ]; then
    # ONLY inside a ` · ` Type slot. A genre WORD anywhere else is indistinguishable from a
    # proper noun: `The Swift Language Reference — value semantics` in a references folder and
    # `Clarity Tool — prose editor` in a tools folder are exactly the shape those folders ask
    # for, and a title may legitimately end in the word too. A type written without the ` · `
    # is a separator error this list cannot tell from a name; a human reading a sweep is where
    # that gets caught. This list feeds a BLOCKING hook — a false positive costs work.
    case "$stem" in
      *"· $GENRE"|*"· $GENRE "*) report "$path" redundant-type ;;
    esac
  fi
}

if [ $namemode -eq 1 ]; then
  for arg in "$@"; do check_path "$arg"; done
else
  while IFS= read -r -d '' path; do
    [ -f "$path" ] || continue
    check_path "$path"
  done < <(find "$@" -type f -print0 2>/dev/null)
fi

echo "naming-lint: $findings finding(s) in $files file(s)" >&2
[ "$findings" -eq 0 ]
