---
name: wrap-up
description: >-
  Semi-automatic end-of-session ritual. Scans the session and machine for
  loose ends, presents ONE categorized report, and on approval executes
  cleanup + closing tasks so the user can `exit` with nothing undone,
  uncommitted, unmerged, or left as garbage. Invoke whenever the user signals
  they're finishing up — "/wrap-up", "wrap up", "wrap up the session", "close
  out", "let's wrap", "I'm done for today", "before I exit", "tidy up the
  session". Covers: uncommitted/unmerged work, stale dev servers, leftover git
  worktrees, booted/leaked simulators, scratchpad & temp files, issue-tracker
  status, docs that drifted, a code review of the session's diff, and a disk-residue
  check. Do NOT use for a one-off cleanup of a single thing the user named
  explicitly (just do that directly), nor as a substitute for a mid-session
  code review or deploy verification.
---

# wrap-up

The closing ritual for a work session. One command, one report, one approval —
then the machine is clean and every loose end is either resolved or explicitly
flagged. The goal is a single feeling: **after this runs, `exit` is safe.**
Nothing uncommitted, nothing unmerged, no orphaned server eating CPU, no leaked
simulator eating disk, no scratchpad cruft, no ticket lying about its state.

But first, before tidying anything, wrap-up asks one blunt question: **is the
work actually finished?** Firing it in a session where the job is half-done is
the one way this skill can do harm — it would stop a server you're mid-debug on,
remove a worktree holding your next step, mark a ticket "Done" that isn't. So a
completion gate runs ahead of everything else and refuses to clean up on
unfinished work without an explicit "yes, anyway."

You (the agent running this) did the session's work, so you already hold most
of the context: which servers you started, which worktrees you created, which
branch you're on, which issues you touched, which files you changed. The
scan's job is to **corroborate that memory against live system state** and catch
what you've forgotten or what drifted while you weren't looking.

## Adapting this to your setup

Written against a macOS + git + Node/Swift workflow with an issue tracker. The
*structure* is the portable part; some detectors are not:

- **macOS-specific:** `stat -f %B` (birth time), `ps -o lstart`, `xcrun simctl`.
  On Linux use `stat -c %W` / `ps -o lstart=` / drop the simulator category.
- **Optional categories:** simulators (iOS only), issue tracker, secret-manager
  wrappers. Skip any category your setup doesn't have — a missing category is not
  a finding.
- **Placeholders** to replace throughout: `<projects-root>` (the directory your repos
  live under) and `<scratchpad-parent>` (where your harness keeps per-session temp
  dirs). Filled per-run rather than at setup: `<session-scratchpad-dir>` (this
  session's temp dir — the agent knows it from its env preamble), `<repo>`, `<wt>`,
  `<PID>`, `<UDID>`.
- **Issue tracker** is referenced generically. Wire it to whatever you use
  (Linear/Jira/GitHub Issues) via CLI or MCP; if you have none, skip that category.
- **Code review** is delegated to a `code-reviewer` agent. This repo doesn't ship one —
  use your own, or spawn a plain subagent with a review prompt over the session diff.
  Whatever you use, keep its power to **halt** Phase 3: a review that can't stop the
  commit is decoration.

## Flags

- (none) — **session scope.** Only residue attributable to *this* session.
  The safe default.
- `--deep` — also sweep **machine-wide orphans** from past sessions: old
  scratchpad dirs, leaked ephemeral test simulators (`~/Library/Developer/
  XCTestDevices` can reach hundreds of GB), long-dead dev servers, stale
  worktrees on other projects.
- `--dry-run` — run the scan and print the report, then **stop**. Execute
  nothing. Use to preview without committing to action.
- `--yes` — still prints the report, then runs the WILL-RUN (auto-safe) tier
  without waiting; the DECISIONS list still needs a "go"/strike — `--yes` never
  auto-runs a destructive or external action (worktree, sim, branch, tracker). For
  trusted, low-residue sessions. (The Phase 0.5 completion gate is never skipped.)

## The three phases

### Phase 0 — Establish what this session touched

Before scanning, reconstruct the session's footprint. Your memory of the
conversation is the starting point — but it does **not survive a context
compaction**, and "which server did I start" can't be answered from memory after
one. So anchor on facts, not recall (commands in `scan-commands.md` §0):

- **T0 — the session-start clock.** Take the birth time of the session `<uuid>`
  dir (its path is in your env preamble, re-sent every turn, so it survives
  compaction). Anything — server, worktree, sim, scratchpad file — born *after*
  T0 is this session's; born before is `--deep`-only. This is how you attribute
  residue deterministically instead of guessing.
- **Repos touched — discover, don't just recall.** Two passes (§0): every git
  checkout under `<projects-root>` that is dirty, ahead, **or committed-to since
  T0**, plus every worktree `git worktree list` reports from each root found (a
  worktree's `.git` is a file, so a depth-bounded find alone misses them).
  Corroborate with memory, then confirm the set with the user. A session can
  span multiple repos.
- **Code actually changed?** — the gate for the two heavy steps. Use the
  Unicode-safe diff check in §0 (a plain `grep '\.md$'` misfires on non-ASCII or
  spaced paths). Docs/config-only → heavy steps skip.

Then read `references/scan-commands.md` for the exact detection commands and run
the scan. Read `references/safety-rules.md` **before proposing any destructive
action** — it is the do-not-touch list and it overrides convenience every time.

### Phase 0.5 — Is the work actually finished? (the fool-proofing gate)

Before scanning or cleaning anything, sanity-check that this session is at a real
stopping point. The failure mode this guards against: the user fires `/wrap-up`
out of habit in a session where the work is half-done, and the cleanup buries
work-in-progress.

**This gate is never skipped — not by `--yes`, not by `--deep`, not by
`--dry-run` reasoning.** It is the one check whose entire purpose is to catch the
case where running wrap-up *at all* was the mistake. It runs first, before the
scan, because there's no point cataloguing residue you may be about to tell the
user to keep working in.

Run the **instant, side-effect-free** structural signals first; only if those
pass AND code changed do you run the fast-signal build check. A gate that runs a
slow build on every wrap-up, or cries wolf on false alarms, gets `--yes`'d into
irrelevance — so each signal below is scoped to avoid that (commands + the
anti-false-alarm scoping in `scan-commands.md` §0.5):

- **Open tasks** — the session's task list still has `pending` / `in_progress`
  items that were the actual goal (you hold this in context).
- **Mid-operation git** — a rebase/merge in progress, or `<<<<<<<` conflict
  markers in changed files.
- **Visible WIP** — `TODO(`/`FIXME:`/`XXX` on **added lines only** (not a
  months-old TODO already in the file — that false-halts).
- **Unchecked plan** — unticked items in the plan file *this session* touched.
  Never tree-grep every plan directory — every project always has an open box, so
  that halts on every run.
- **Mid-TDD** — only if this session ran a RED/TDD phase: a RED test with no
  GREEN, or (if your setup writes a TDD marker file) a **stale** marker, older
  than the newest test edit. A missing marker on a non-TDD session is not a signal.
- **Red fast-check** — `tsc --noEmit` / lint / compile fails (test runners strip
  types without checking, so green tests ≠ green types). Run *after* the structural
  signals, and not while dev servers are up (they starve the runner → false RED).
- **Stated goal unmet** — from the conversation, the thing the user set out to do
  plainly isn't done.

**Untidy ≠ unfinished.** Uncommitted changes are *expected* at wrap-up — that's
what wrap-up commits; they are not, by themselves, a reason to halt. The question
is whether the work reached a coherent stopping point, not whether everything is
already put away. Don't manufacture doubt: if the session is clearly at rest,
pass this gate silently and move to the scan.

**If a signal fires, STOP and ask — do not scan-and-clean past it.** Encode
confidence in the marker so the gate doesn't cry wolf: `●` for a hard signal
(failing check, RED test, conflict), `○` for a soft/uncertain one (a lingering
task that might just be a note). Reserve `🛑` for a true blocker — this routine
double-check opens softer:

```
✋ Before I clean up — this session doesn't look finished:
  ● 3 tests failing (api package)               — hard
  ● feat/x: RED test, no implementation         — hard
  ○ 2 task items still open                     — maybe just notes?

Wrap now and I'd stop servers, drop worktrees, and mark ENG-280 done — on top of
unfinished work. Wrap anyway, or keep working?
  • "wrap anyway"  → scan + report (see scope note below)
  • "keep working" → I stop here and touch nothing
```

Only on an explicit "wrap anyway" do you proceed. And when you do, **down-scope
the cleanup** — the user just told you the work is unfinished, so do NOT mark its
issue Done, remove its worktree/branch, or treat "code changed" as
"complete." Run only the safe tier (stop *your* servers, clear *this* scratchpad)
and list everything bound to the unfinished work as deliberately-kept residue in
the verdict. A blanket "wrap anyway" must not re-create the exact harm the gate
just prevented.

### Phase 1 — SCAN (read-only, never mutates)

Run the detectors across these ten categories. Parallelize the independent
shell probes. Collect findings — do not act yet.

1. **Git state** — per touched repo: uncommitted/staged changes, untracked
   files worth keeping, unpushed commits, current branch, whether a feature
   branch is merged.
2. **Worktrees** — `git worktree list` per repo. For each, record dirty state
   and unpushed commits — a worktree with unsaved work is **data-loss risk**,
   never a delete candidate.
3. **Local servers** — dev servers you started (next/vite/bun/node/`npm run dev`,
   or whatever wrapper your project uses). Session scope = ones you started;
   `--deep` = all stale ones.
4. **Simulators** *(iOS/macOS only — skip otherwise)* — booted sims and (with
   `--deep`) leaked ephemeral clones. **Sims pinned as canonical in project docs
   are sacred** — never a delete candidate; at most propose *shutdown* if you
   booted one this session.
5. **Scratchpad / temp** — this session's scratchpad dir; with `--deep`, the
   accumulated old session dirs and other obvious temp.
6. **Issue tracker** *(skip if none)* — issues you touched. Does each issue's
   status reflect what the session actually accomplished (e.g. work done but still
   "In Progress")?
7. **Docs** — *only if code changed*: did the project's docs (README / architecture
   / setup / API) drift relative to the change?
8. **Code review** — *only if code changed*: the session diff deserves a
   `code-reviewer` pass before you call it done — but not a second one. Per
   repo: a pass that already ran this session on the current diff (no code
   changes since) is reused **with its verdict, never assumed clean**:
   approved → `review: passed in-session`; findings still open → `review: <N>
   open (in-session) — NOT clean` (forbids the unqualified ✅). Only in-context
   certainty qualifies; post-compaction, when unsure, run it. High-stakes diffs
   (auth / payments / migrations / cross-project) warrant a multi-reviewer
   fan-out — one in-session pass doesn't discharge that tier. Details:
   scan-commands.md §8.
9. **Memory** — any durable, non-obvious learning from this session worth writing
   to your notes/memory file? Surface as a *suggestion*, never auto-write.
10. **Disk** — `du` on this session's scratchpad + `df`; the heavy trees
    (XCTestDevices, DerivedData) are `--deep`-tier — walking them costs tens
    of seconds. Report only; deletions are individually gated.

### Phase 2 — REPORT (one screen, then one approval)

Present ONE report. Lead with a headline carrying the only two numbers that set
the user's cognitive cost — *how many destructive decisions, and is anything
blocking* — then put the **decisions first** and collapse the no-decision tier to
a single count-led line. A wall of five equal-weight sections produces numbness,
and numbness is what makes a tired user rubber-stamp. Be specific: name the
worktree, PID, UDID, issue ID, exact command.

```
## 🧹 wrap-up — api + web · session scope
Need you: 2 decisions · Nothing blocking · 3 auto-safe + review run on your OK

DECISIONS (each is destructive or external — strike any you don't want)
  1. Commit 3 files on feat/x & push — feature-branch flow (never main)
     → git add -A && git commit -m … && git push
  2. Issue ENG-280 "In Progress" → "Done" — work looks complete (judgment call)
  3. Delete worktree web/eng-233-settings-email — merged, clean, pushed
     → git worktree remove …

WILL RUN on your OK (no data risk)
  · stop vite (PID 52098, born this session) · clear scratchpad (12 files, 4 MB)
  · shut down iPhone 16 (UDID …9F2C, not pinned)

THEN (code changed): code-reviewer on 14 files · docs pass for the api README
  ↳ review can HALT the rest if it finds a real bug

ℹ️  Left alone: pinned sim project-canonical-iPhone16 (canonical)
    --deep would also sweep: old scratchpad dirs · XCTestDevices (sizes not measured in session scope)
🧠  Lesson worth saving: <one line> — say so and I'll write it
```

**One approval, itemized — not N sequential prompts.** Sequential y/n per item is
exactly the fatigue that trains rubber-stamping; full visibility + selective
opt-out + a single action preserves real consent:

```
Reply "go" → run all decisions + auto-safe + heavy steps.
Or strike items: "skip 2", "not the worktree", "1 and 3 only".
```

Note the approval word is **"go"**, deliberately different from the gate's "wrap
anyway", so muscle-memory can't blow through both. Honor `--dry-run` (stop here)
and `--yes` (per Flags: WILL-RUN tier auto-runs, DECISIONS still need a
"go"/strike). Anything genuinely irreversible-with-data-loss (force-removing
a *dirty* worktree) the rules forbid auto-proposing anyway, so the single "go"
should be the only prompt in practice.

### Phase 3 — EXECUTE (order matters — preserve before you destroy)

Run in this order. The principle: **everything that produces or preserves work
comes before anything that destroys residue**, because cleanup can erase
something a later step still needs (a worktree with uncommitted changes is the
classic trap).

1. **Heavy steps first, and they can halt the rest.** If code changed, run
   `code-reviewer` (and any docs pass) — **per touched repo**, gating each one
   independently and honoring the `scan-commands.md` §8 skip-and-carry (a repo
   whose current diff was already reviewed this session doesn't pay twice — its
   verdict carries into the close-out). A real blocker → **stop and surface
   it**; do not commit/clean over a known bug. Green + docs *before* merge. Docs
   drift you can't fix right now (file mid-edit by a concurrent session, fix
   belongs to an unmerged branch)
   must leave a **durable artifact before the verdict**: a tracker issue or an
   unticked item in the session's plan file — and the `docs:` verdict token names
   it. A chat-only "fold into next merge" evaporates — treat it as not handled.
2. **Commit & push** on the current feature branch. Never `.env`/secrets; never
   `git reset --hard` or discard uncommitted work without explicit confirmation.
   **First check HEAD isn't `main`/`master`** — if the session worked on main, do
   NOT auto-push; surface it as a decision ("branch this first, or authorize").
   On a feature branch with no upstream, `git push -u`.
3. **Issue tracker** — apply approved status updates; re-fetch to confirm the
   change landed.
4. **Cleanup, destructive tier** — stop servers, clear scratchpad, remove
   worktrees, shut down / delete sims (never pinned). Each only if approved, and
   for each worktree **re-run the clean + no-unpushed + merged invariant right
   before `git worktree remove`** — not from the Phase-1 scan (state changed
   since, and the delete is irreversible).
5. **Memory** — write the notes entry only if the user said yes (grep first
   so a re-run doesn't duplicate the line).
6. **Final re-scan + verdict.** Re-run the probes (per the three-state discipline
   in `scan-commands.md`) — every verdict line must come from a probe that *just
   ran and succeeded*, not from "I ran the command earlier." Verify **ports** free
   (not PIDs gone), push landed (`git fetch && git log @{u}..` empty), issues
   re-fetched, worktrees/sims re-listed absent. Then emit the close-out.

   **The verdict always carries a `docs:` token** — one of `updated inline` /
   `updated (delegated)` / `no drift` / `drift → <issue-or-plan-item>` /
   `UNKNOWN (couldn't assess)`. Docs is the one category without an OS-level
   probe, so it's the easiest to drop silently; the mandatory token makes
   "checked, clean" distinguishable from "never looked". `drift → …` is only
   valid if the durable artifact from step 1 actually exists — verify it like
   any other verdict line. When code changed, a `review:` token rides along
   the same way — `passed` / `passed in-session` / `<N> open (in-session) —
   NOT clean` — so a skipped re-run is never mistaken for a clean one.

   **Print one of three verdicts — never dress a kept loose end or a failed probe
   as a clean exit (safety-rules #8). The condition goes in the H2, the one line a
   tired user always reads.**

   **(a) Truly clean** — collapse the evidence, make the payoff dominant:
```
## ✅ Safe to exit — nothing left behind
Reviewed, committed, pushed, cleaned. Residue: none.
   feat/x pushed · 0 servers · 0 worktrees · 0 sims · scratchpad clear · ENG-280 Done · review: passed · docs: no drift
→  exit
```
   **(b) Clean except things you chose to keep** — count in the title, unmissable:
```
## ✅ Cleaned — but 2 things you chose to keep
Everything else is resolved. These remain by your call — eye them before exit:
   ⚠ feat/payments worktree: 3 uncommitted files — kept dirty
   ⚠ code review: 1 HIGH open (auth token logged) — not addressed
Resolved: feat/x pushed · servers stopped · scratchpad clear · ENG-280 Done · review: 1 open (in-session) — NOT clean · docs: updated inline
```
   **(c) Couldn't verify** — a probe errored, so this is NOT a full all-clear:
```
## ⚠️ Mostly clean — 1 thing I couldn't check
   ✗ Sims: simctl XPC-errored — could NOT confirm none booted (check manually)
Resolved: git clean · servers stopped · scratchpad clear · docs: no drift
→  not a full all-clear: verify sims yourself before exit.
```

> **If your harness has a Stop hook** that requires a verification token in tool
> output, the close-out's `git`/`du`/`ps`/`lsof` probes may not match its pattern
> and the verdict itself can get blocked. Emit the token (e.g.
> `echo "VERIFIED: wrap-up close-out re-scan"`) as its **own separate Bash
> call**, never the tail of a longer probe — hooks often read only the first few
> hundred chars of each tool result, so a token at the end of a long combined
> re-scan is invisible. Keep the reason substantive and free of characters the
> hook's regex may stop at (e.g. `|` `"` `\`). No Stop hook → ignore this.

## Non-negotiables (full list in references/safety-rules.md)

- **Confirm the work is finished before cleaning** — the Phase 0.5 gate runs
  first and is never skipped by a flag; unfinished work needs an explicit "yes".
- **Pinned simulators are sacred** — read project docs; never delete one.
- **Never merge or push to main** without explicit authorization.
- **Never discard uncommitted work** without explicit confirmation; default to
  committing it on its branch, not throwing it away.
- **Never commit secrets / `.env`.**
- **Docs drift never defers into thin air** — can't fix now → tracker issue or
  plan-file item, named in the verdict's `docs:` token.
- **Session scope by default** — only `--deep` touches other sessions' orphans,
  and even then every deletion is individually gated.
- **The scan never mutates.** Reads only. All change happens in Phase 3, post-approval.
