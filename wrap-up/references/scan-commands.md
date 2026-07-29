# scan-commands.md — detectors for each wrap-up category

Read-only. Run the independent probes in parallel. Everything here is a
*detector* — it reports state. Acting on findings happens in Phase 3, after
approval. Replace `<repo>` with each repo the session touched (discovered in §0)
and `<projects-root>` with the directory your repos live under.

**Platform note:** these are macOS/BSD commands. On Linux, `stat -f %B` →
`stat -c %W`, and the simulator category doesn't apply. Skip any category your
setup doesn't have — a missing category is not a finding.

## Three-state discipline (applies to EVERY detector here)

A probe has three outcomes, never two: **CLEAN**, **DIRTY**, **UNKNOWN**. A
command that errors, times out, or can't run (sandbox/XPC failure, missing
API key, network down) is **UNKNOWN — not CLEAN**. Capture exit status; an
empty result from a *failed* command must never render as "0 / clean." This is
the load-bearing rule behind the "Safe to exit" promise: the verdict may only
print a clean line for a category whose probe actually *succeeded and came back
empty*. Any UNKNOWN forbids the unqualified ✅ (see safety-rules.md #8).
Exception: a detector may document an rc inversion inline (the §0.5 conflict
probes — rc=1 means clean there); judge those by OUTPUT, as noted at the site.

```bash
out=$(some_probe 2>&1); rc=$?
if [ $rc -ne 0 ]; then echo "UNKNOWN: <category> probe failed — $out"
elif [ -z "$out" ]; then echo "CLEAN"
else echo "DIRTY: $out"; fi
```

---

## 0. Session footprint — establish T0, discover repos, detect code-change

### T0 — the session-start anchor (survives compaction)

After a context compaction you no longer *remember* which servers/worktrees/sims
you created. Don't guess — attribute by time. The session scratchpad `<uuid>`
dir is re-sent in the env preamble every turn, so its birth time is a stable
session-start clock.

```bash
# NOTE: shell state dies between Bash tool calls — re-derive T0 inside EVERY
# call that compares against it; a stale/unset $T0 fails open or silently.
SESSION_DIR=$(dirname "<session-scratchpad-dir>")   # the <uuid> dir, not /scratchpad
T0=$(stat -f %B "$SESSION_DIR")                      # birth time, epoch seconds (BSD stat)
NOW=$(date +%s)

# A process is THIS session's iff it started after T0. NOTE: macOS `ps` has no
# `etimes` (that's Linux/procps) — it silently returns junk. Parse `lstart`:
LSTART=$(ps -o lstart= -p <PID>)        # e.g. "Fri Jun 26 16:56:08 2026"
PSTART=$(date -j -f "%a %b %e %T %Y" "$LSTART" +%s 2>/dev/null)
[ -n "$PSTART" ] && [ "$PSTART" -gt "$T0" ] && echo "session-owned" || echo "pre-existing (only --deep)"

# A worktree / scratchpad file / sim is this session's iff born after T0:
[ "$(stat -f %B <path>)" -gt "$T0" ] && echo "session-owned"
```

**Residual risk — state it, don't hide it:** a server the user launched in
*another terminal* within the same window also reads `> T0`. Before proposing to
kill a server, add a second discriminator — confirm its working dir is in the
touched-repo set: `lsof -a -p <PID> -d cwd -Fn 2>/dev/null`. No cwd match → treat
as someone else's, report don't kill.

### Repo discovery — deterministic, not from memory

```bash
# Any git checkout under <projects-root> that is dirty, ahead, OR committed-to
# since T0 is a candidate. What this two-pass discovery is shaped around:
#   - a worktree's .git is a FILE, not a dir, and worktrees can nest at any
#     depth under a repo — no depth-bounded find alone is complete. Pass 2
#     asks git itself for every registered worktree of every root found:
#     authoritative, depth-proof;
#   - node_modules must be pruned: at depth ≤4 that's thousands of package
#     dirs per project;
#   - `dirty OR ahead` alone misses a repo whose work is already committed
#     AND pushed — clean, not ahead, but tracker/docs steps still apply. The
#     HEAD-commit-after-T0 test catches those. A HEAD>T0 hit in a repo you
#     don't recall touching may be a PEER session's commit (parallel agent
#     sessions exist — safety-rules #7): a SOFT candidate — confirm with the
#     user, never auto-act on it.

# T0 must be derived IN THIS SHELL — env vars do not survive between Bash tool
# calls, and zsh treats [ n -gt "" ] as TRUE (every repo would match); an
# unresolved T0 must degrade loudly to UNKNOWN, never silently:
T0=$(stat -f %B "$(dirname "<session-scratchpad-dir>")" 2>/dev/null)
case "$T0" in ''|*[!0-9]*) echo "UNKNOWN: T0 unresolved — HEAD>T0 test disabled"; T0= ;; esac

# Pass 1 — checkout roots (depth-bounded find; trailing -prune skips
# descending into the hundreds-to-thousands of dirs inside each .git):
ROOTS=$(find <projects-root> -maxdepth 4 -name node_modules -prune \
  -o -name .git \( -type d -o -type f \) -print -prune 2>/dev/null | sed 's|/\.git$||')

# Pass 2 — every registered worktree of every root (awk sub(), not $2: paths
# may contain spaces). Dedup by INODE, not by name: on a case-insensitive
# filesystem git's admin files can record a different CASE than the on-disk
# name, and a byte-wise sort -u then keeps both spellings — one worktree
# becomes two destructive DECISIONS entries. (`cd`+`pwd -P` does NOT fix case
# in bash, only zsh — the inode is shell-proof; -L follows symlinks so a
# linked path can't double-count; Linux: stat -Lc '%d:%i'.)
# The stat also drops stale/prunable worktree records whose path is gone.
# Guard empty ROOTS: `git -C ""` silently operates on cwd.
[ -z "$ROOTS" ] && echo "UNKNOWN: no git checkouts found — discovery failed"
{ [ -n "$ROOTS" ] && printf '%s\n' "$ROOTS"
  [ -n "$ROOTS" ] && printf '%s\n' "$ROOTS" | while read -r r; do
    git -C "$r" worktree list --porcelain 2>/dev/null \
      | awk '/^worktree /{sub(/^worktree /,""); print}'
  done
} | grep -v '^$' | while read -r r; do
  key=$(stat -Lf '%d:%i' "$r" 2>/dev/null) && printf '%s\t%s\n' "$key" "$r"
done | awk -F'\t' '!seen[$1]++{print substr($0, index($0,"\t")+1)}' | while read -r r; do
  dirty=$(git -C "$r" status --porcelain 2>/dev/null)
  ahead=$(git -C "$r" rev-list --count @{u}..HEAD 2>/dev/null)
  last=$(git -C "$r" log -1 --format=%ct 2>/dev/null)
  [ -n "$dirty" ] || [ "${ahead:-0}" -gt 0 ] \
    || { [ -n "$T0" ] && [ "${last:-0}" -gt "$T0" ]; } && echo "$r"
done
```

Confirm the set with the user before acting on it. This corroborates (not
replaces) your memory of what you touched.

### Code changed this session? (gates the heavy steps — Unicode-safe)

```bash
# core.quotepath=false: don't let git quote non-ASCII or spaced paths and break
# the extension match. -z + tr handles NUL safely.
git -C <repo> -c core.quotepath=false diff --name-only -z HEAD 2>/dev/null \
  | tr '\0' '\n' \
  | grep -qvE '\.(md|mdx|markdown|txt|rst)$' && echo "code changed → heavy steps fire"
```

Excludes the doc extensions. If your harness has a quality-gate hook with its own
doc-extension set, keep the two aligned so they never disagree. Untracked new code
files: add `git ls-files --others --exclude-standard` to the same filter.

---

## 0.5 Completion signals (the fool-proofing gate — run BEFORE the scan)

The question is *did the work reach a coherent stopping point?* — not "is it
tidy." Run the **instant, side-effect-free** structural signals first; only if
those pass AND code changed do you run the fast-signal build tier. Never run a
full build/suite here by default — it's slow, has side effects, duplicates the
Phase-3 review, and a flaky/env failure would false-halt the gate.

### Structural signals (instant — always)

```bash
# Open work items: the harness task list (pending/in_progress that were the goal)
#   → you hold this in context; no shell probe.

# Mid-operation git states
git -C <repo> status | grep -iE "rebase in progress|unmerged|you have unmerged"
# Conflict markers — via git, which respects .gitignore (a raw `grep -r` walks
# node_modules: seconds of wall-clock for pure noise). NOTE: these invert the
# §top three-state template — judge by OUTPUT, not rc (git grep rc=1 = clean
# no-match; diff --check rc=2 = FOUND problems). And filter --check to
# conflict lines only — it also flags trailing whitespace, which would
# false-halt the gate on every unformatted repo:
git -C <repo> diff HEAD --check 2>/dev/null | grep -i 'conflict marker' | head
git -C <repo> grep -n "^<<<<<<< " 2>/dev/null | head   # tracked files
git -C <repo> ls-files --others --exclude-standard -z 2>/dev/null \
  | xargs -0 grep -l '^<<<<<<< ' 2>/dev/null | head    # untracked new files

# Fresh WIP — ADDED lines only (not old TODOs already in the file)
git -C <repo> -c core.quotepath=false diff HEAD 2>/dev/null \
  | grep '^+' | grep -nE 'TODO\(|FIXME[:(]|XXX' | head

# Unticked items in a plan THIS SESSION touched (NOT a tree-wide grep)
#   You know which plan file(s) you edited from Phase 0. Check only those:
grep -n '\- \[ \]' "<this-session-plan-file>" 2>/dev/null | head
#   ^ Do NOT grep every plan directory — every project always has some open box;
#     a tree-wide grep halts the gate on essentially every run, and bash needs
#     `shopt -s globstar` for ** anyway. Scope or skip — never halt on another
#     session's plan.

# Mid-TDD: only relevant if THIS session ran a RED/TDD phase (you know this).
#   If your setup writes a TDD marker file after a passing cycle, a STALE marker
#   lies — it says "verified" while a newer test edit went unverified. A missing
#   marker on a non-TDD session is NOT a halt. Adjust the filename to your setup:
MARKER=<repo>/.tdd-gate-passed
if [ -f "$MARKER" ]; then
  m=$(stat -f %m "$MARKER")
  t=$(git -C <repo> ls-files -z '*test*' '*Test*' 2>/dev/null | xargs -0 stat -f %m 2>/dev/null | sort -rn | head -1)
  [ -n "$t" ] && [ "$t" -gt "$m" ] && echo "STALE tdd marker — newer test edited after pass → unfinished"
fi
```

### Fast-signal build tier (only if structural signals pass AND code changed)

The single most common "actually broken" state slips past test runners:
**vitest/jest/swc strip types without checking them**, so the test run is green
while the types are red. Run the cheap project-level checks, fast ones first:

```bash
# Discover the command, in priority order:
#   1. the project's documented CI/CD entry point
#   2. package.json scripts: typecheck / lint / build
#   3. Swift: `swift build` or `xcodebuild build`;  4. Makefile target
jq -r '.scripts | keys[]' <repo>/package.json 2>/dev/null | grep -iE 'typecheck|lint|build'

# TS — the load-bearing one the test runner hides:
( cd <repo> && npx --no-install tsc --noEmit ) 2>&1 | tail -5
```

If your harness runs a per-turn quality-gate hook, coordinate rather than
duplicate: that hook already validated the *last turn's* files. wrap-up's value
here is the **cross-file project typecheck** spanning files the per-turn lint
never saw together. Run that; don't re-run the full lint the hook just did.
Treat an *errored* check (missing dep, no script) as UNKNOWN — "couldn't
determine," not a halt. Don't run this while session dev servers are up — they
starve the runner and produce a false RED; either stop them first or don't treat
a single timeout as red.

---

## 1. Git state (per touched repo)

```bash
git -C <repo> status --short --branch          # dirty? ahead/behind?
git -C <repo> stash list                       # ⚠️ stashed work shows CLEAN in status — MUST check
git -C <repo> branch --show-current            # empty = detached HEAD (hard flag)
git -C <repo> symbolic-ref -q HEAD >/dev/null || echo "DETACHED HEAD — flag, don't auto-act"

# Unpushed — handle the no-upstream case explicitly (the silent false-clean):
UP=$(git -C <repo> rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
if [ -z "$UP" ]; then
  base=$(git -C <repo> merge-base HEAD main 2>/dev/null || git -C <repo> rev-list --max-parents=0 HEAD | tail -1)
  echo "NO UPSTREAM — these commits exist ONLY locally:"; git -C <repo> log --oneline "$base"..HEAD
else
  git -C <repo> log --oneline @{u}..            # normal unpushed
fi

# On main/master? Then do NOT auto-commit-and-push without authorization
b=$(git -C <repo> branch --show-current)
[ "$b" = "main" ] || [ "$b" = "master" ] && echo "ON MAIN — surface as ⚠️, do not auto-push"
```

Why each matters: `git log @{u}..` with `2>/dev/null` on a **never-pushed**
branch errors (no `@{u}`) and returns empty → reads as "0 unpushed" → the exact
"unmerged work left behind" the skill promises to catch, missed silently.
`git stash` work is invisible to `status --porcelain`. A detached HEAD orphans
commits on the next checkout.

## 2. Worktrees (per touched repo)

```bash
git -C <repo> worktree list --porcelain        # --porcelain marks `prunable` ones
git -C <wt> status --porcelain                  # MUST be empty to remove
# unpushed — SAME no-upstream handling as §1 (a no-upstream worktree branch
# counts ALL its commits as unpushed; never read empty-from-error as safe):
UP=$(git -C <wt> rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
[ -z "$UP" ] && echo "no upstream → ALL commits unpushed → NOT removable"
```

A worktree is removable **only** when clean AND no unpushed commits (no-upstream
= unpushed) AND its branch is merged (verified against the remote — squash-merge
can hide this). **Re-run this full invariant in Phase 3 immediately before each
removal**, not from the stale Phase-1 scan — commits/pushes between scan and
removal change the answer, and the deletion is irreversible (TOCTOU).

## 3. Local dev servers

```bash
ps aux | grep -iE "next dev|vite|bun run dev|npm run dev|node .*dev" | grep -v grep
lsof -nP -iTCP -sTCP:LISTEN | grep -iE "node|bun|vite" | head
```

Add your own wrappers to the pattern if your dev command runs behind one (a
secret-manager launcher, `concurrently`, a task runner) — the parent process is
what you need to kill, and it won't match a bare `vite` pattern.

Attribute by T0 (§0): session scope = `PSTART > T0` **and** cwd in the touched
set; `--deep` = anything older. Stop the tree by **explicit PID** — kill the root
(the wrapper/`concurrently` parent) and its listed children:

```bash
kill <PID> <PID> <PID>            # the PIDs you identified, by number
```

⚠️ Do NOT "catch survivors" with `pkill -f "<project-path>"` or
`ps | grep <path> | kill`. That net also catches a peer session's live
`git push` / pre-push hook, a running `tsc --noEmit`, and other concurrent
sessions on the same repo (safety-rules #7 — this caused a real incident). If a
PID genuinely survives, re-identify it by number and re-check T0/cwd before
killing; a newer-than-orphan PID is not yours.

In the final re-scan, verify the **port** is free (`lsof -nP -iTCP:<port>
-sTCP:LISTEN` empty), not just that the PID is gone — a watcher/`concurrently`
can rebind under a new PID.

## 4. Simulators *(iOS/macOS only — skip otherwise)*

```bash
xcrun simctl list devices booted               # may XPC-error under sandbox → UNKNOWN, not CLEAN
# (leaked XCTestDevices clones are --deep tier — their du lives in §10)
```

**Before proposing to touch ANY sim**, check whether its UDID is pinned as
canonical in your project docs — and check it correctly:

```bash
if grep -rqi "<UDID>" <projects-root> --include="*.md"; then
  echo "PINNED — do not touch"
else
  echo "not pinned — shutdown candidate"
fi
```

⚠️ Do **not** write `grep <UDID> ... | head -1 >/dev/null && echo PINNED`.
Piping to `head` masks grep's exit status (`head` always succeeds), so the test
passes for *every* sim and reports even generic sims as pinned. Use `grep -q`
directly, no pipe. (Same trap applies to any "did grep match?" test in this file
— and is why the three-state block at the top captures `$?` explicitly.)

`xcrun simctl` needs the sandbox disabled (it talks to CoreSimulatorService over
XPC). If a call errors, that category is **UNKNOWN** — the verdict must say "sim
scan failed — couldn't confirm none booted," never imply clean by omission.
Cleanup targets: a non-pinned sim born after T0 (shutdown); `--deep` leaked
`XCTestDevices` clones (`xcrun simctl --set testing delete all` — never pinned).

## 5. Scratchpad / temp

```bash
ls -la "<session-scratchpad-dir>"                       # this session's
du -sh "<scratchpad-parent>"/*/ 2>/dev/null | sort -h | tail -20   # --deep: old dirs
```

Session scope: clear only this session's own scratchpad subdir. `--deep`: old
session dirs (keep the current one; under `--deep`, also skip any `<uuid>` dir
with mtime in the last few minutes — it may be a *concurrent live* session).

## 6. Issue tracker *(skip if none)*

For each issue the session touched, fetch its current status and compare to what
was actually done. If your tracker has multiple workspaces/projects and the
session spanned several repos, **route each issue to its own workspace** — never
batch-update across workspaces with one key/token. After updating, **re-fetch**
the issue to confirm the status field actually changed in the correct workspace
(a write with the wrong credentials can succeed against the wrong issue) —
otherwise the category is UNKNOWN.

## 7. Docs (only if code changed)

The one category with no OS-level probe — but don't run it from memory (post-
compaction, memory is exactly what's gone). Build a candidate list mechanically,
then judge each candidate against the real trigger — *documented behavior
changed?* (a refactor that changes no documented behavior needs nothing):

```bash
# Changed + untracked source files → distinctive module-name tokens.
# Capture git's rc BEFORE piping into grep — grep exits 1 on "no source files",
# which is a legitimate CLEAN, not an error (same trap as the §4 pinned-sim check).
DIFF=$(git -C <repo> -c core.quotepath=false diff --name-only HEAD 2>&1); rc=$?
NEW=$(git -C <repo> ls-files --others --exclude-standard 2>/dev/null)
CH=$(printf '%s\n%s\n' "$DIFF" "$NEW" | grep -vE '\.(md|mdx|markdown|txt|rst)$')
# Tokens = distinctive module names ONLY. Generic filenames (route.ts, page.tsx,
# index.ts …) take their PARENT dir; bare path dirs (app/lib/src …) are dropped —
# otherwise `app`/`route` matches every doc and the candidate list is useless.
TOK=$(echo "$CH" | while read -r p; do
        b=$(basename "${p%.*}")
        case "$b" in route|page|layout|index|main|mod|init|utils|types|styles)
          b=$(basename "$(dirname "$p")");; esac
        echo "$b"
      done | grep -viE '^(app|lib|src|api|components|server|pages|__tests__?)$' \
      | grep -E '...' | sort -u | head -25)   # min 3 chars — `ai` would match every doc
# Docs mentioning a changed module = drift CANDIDATES (candidates, not verdicts).
# -wF: whole-word fixed-string (substring `ai` ⊂ "email" was pure noise);
# --include: markdown only (docs/ dirs also hold CSVs and assets).
for t in $TOK; do
  grep -rliwF --include='*.md' --include='*.mdx' -- "$t" \
    <repo>/docs <repo>/README.md <repo>/ARCHITECTURE.md 2>/dev/null
done | sort -u
```

Three-state like every other category: the git probe errored (`rc` ≠ 0) →
**UNKNOWN** ("docs couldn't be assessed" — never imply clean); candidates
found, or a *new* documented surface (module / route / schema) with no doc
anywhere → **DIRTY** (judge each: real drift → fix inline now or delegate in
Phase 3; already updated inline this session → say so);
`CH` empty or no candidates and no documented-behavior change → **CLEAN**.
The outcome feeds the mandatory `docs:` token in the close-out verdict
(SKILL.md Phase 3 step 6).

## 8. Code review (only if code changed)

**Skip check first — reuse the pass, but carry its VERDICT, never assume it
was clean.** Per repo: if a `code-reviewer` pass already ran this session on
this repo's current diff (no code changes since), don't re-run it — record
what that pass actually concluded:
  - it approved → `review: passed in-session`;
  - it left findings open → `review: <N> open (in-session) — NOT clean`,
    which forbids the unqualified ✅ (verdict (b), safety-rules #8). Note the
    asymmetry: *fixing* the findings changes the code, which voids the skip
    and re-runs the review — so "no code changed since" alone proves nothing
    about cleanliness, only about staleness.
The skip only discharges the tier the diff requires: a high-stakes diff
(auth/payments/migrations/releases/cross-project/large) needs 2–3 decorrelated
reviewers — one in-session pass doesn't satisfy that; run the missing ones over
the current diff. That certainty lives only in your conversation context; after
a compaction you may not have it — when unsure, run the review (a duplicate
pass costs tokens; a skipped-but-needed one ships a bug).

Otherwise delegate to `code-reviewer` in Phase 3 over each touched repo's
session diff. In a multi-repo session, gate **each repo independently** (run
that repo's fast check before committing it) — a per-turn hook typically only
verifies the cwd repo, so other repos would otherwise get committed unverified.
Single vs. multi reviewer by stakes (routine → one; auth/payments/migrations/
releases/cross-project/large → 2–3 decorrelated, dedup+rank into one list, keep
single-source HIGH/MED).

## 9. Memory

Judgment, not a command. Durable, non-obvious lesson → draft a one-line
suggestion for your notes/memory file; never auto-write. Before appending on a
second run, grep that file for the line so a double-run doesn't duplicate it.

## 10. Disk

```bash
# session scope:
du -sh "<session-scratchpad-dir>" 2>/dev/null
df -h / | tail -1
```

```bash
# --deep only — XCTestDevices/DerivedData can reach hundreds of GB; walking
# them costs tens of seconds per run for a report-only number:
du -sh ~/Library/Developer/XCTestDevices ~/Library/Developer/Xcode/DerivedData 2>/dev/null
```

Report only. Deletion beyond this session's own scratchpad is `--deep`-tier and
individually gated.
