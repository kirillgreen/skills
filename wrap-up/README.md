# wrap-up

A Claude Code skill that closes out a work session: one scan, one report, one
approval — then the machine is clean and every loose end is either resolved or
explicitly flagged. The goal is a single feeling: **after this runs, `exit` is safe.**

## The problem it solves

Sessions don't end. They get abandoned.

You finish the thing, you're tired, you close the terminal. Left behind: a vite
server still eating CPU, a worktree from a branch you merged two hours ago, a
simulator holding several GB, a ticket that still says "In Progress", a scratchpad full
of screenshots, and — the expensive one — a commit that never got pushed. You find
out three days later, when you're looking for work you're sure you did.

Every one of those is trivial to fix *at the moment it happens* and annoying to
discover later. The problem isn't difficulty; it's that nobody does a closing pass,
because a closing pass is boring and the session already feels over.

The agent, however, was there for all of it. It knows which server it started,
which worktree it made, which branch it's on. That knowledge evaporates when the
session ends. This skill spends it before it's gone.

## What makes it more than a cleanup script

**It asks whether you're actually finished — first, and unskippably.**
The one way a cleanup skill can hurt you is running in a session where the work is
half-done: it stops the server you're mid-debug on, removes the worktree holding
your next step, marks a ticket "Done" that isn't. So a completion gate runs before
the scan and refuses to proceed on unfinished work without an explicit "wrap anyway"
— and even then it down-scopes, because a blanket "anyway" shouldn't recreate the
exact harm the gate just prevented.

**It attributes residue by time, not by memory.**
"Which server did I start?" is unanswerable after a context compaction. So the scan
anchors on T0 — the session directory's birth time — and everything born after it is
this session's. Deterministic instead of hopeful.

**It refuses to lie about being clean.**
Every probe has three outcomes, not two: CLEAN, DIRTY, **UNKNOWN**. A command that
errors returns empty — and empty-from-error reads exactly like empty-from-clean if
you're not careful. That distinction is the whole trustworthiness of a "safe to exit"
promise, so any UNKNOWN forbids the unqualified ✅. The verdict says "I couldn't
check the simulators" rather than implying there were none.

**One approval, itemized — not twelve y/n prompts.**
Sequential confirmation is what trains rubber-stamping. You get one screen, decisions
first, and you strike what you don't want: *"skip 2", "not the worktree"*.

**It preserves before it destroys.**
Phase 3 runs review → commit → push → *then* cleanup. Reversing that order is how a
worktree with uncommitted changes gets removed.

## What it checks

Git state (including `stash`, detached HEAD, and the no-upstream case that silently
reads as "nothing unpushed") · worktrees · dev servers · simulators · scratchpad ·
issue tracker · doc drift · a code review of the session diff · a memory-worthy
lesson · disk residue.

## Hard-won details worth stealing even if you don't use the skill

- `git log @{u}..` on a **never-pushed branch** errors and returns empty — which reads
  as "0 unpushed". That's the exact data-loss case a wrap-up is supposed to catch,
  missed silently. Handle no-upstream explicitly.
- `git stash` work is **invisible** to `git status --porcelain`. A repo can look clean
  and be holding hours of work.
- `grep <UDID> ... | head -1 >/dev/null && echo PINNED` marks **every** simulator as
  pinned — `head` always exits 0, masking grep's status. Use `grep -q`, no pipe.
- macOS `ps` has no `etimes`; it returns junk rather than failing. Parse `lstart`.
- Killing servers with `pkill -f <project-path>` also kills a concurrent session's
  live `git push` and any running `tsc`. Kill by attributed PID only.
- Verify the **port** is free, not that the PID is gone — `concurrently` rebinds under
  a new PID.
- A worktree's `.git` is a **file**, not a directory — and worktrees nest at
  arbitrary depths. A depth-bounded `find -type d` misses them entirely; ask
  `git worktree list` from every discovered root instead.
- On a case-insensitive filesystem, git can record a worktree under a different
  **casing** than the on-disk directory — one worktree becomes two "delete?"
  entries unless you dedup by **inode** (`stat '%d:%i'`). `cd` + `pwd -P` does
  NOT fix case in bash (it does in zsh) — don't trust it.
- Shell variables **die between tool calls**. A `$T0` set in one call is empty
  in the next — and zsh treats `[ n -gt "" ]` as *true*, so a lost variable can
  turn a scoped filter into match-everything. Re-derive state inside every call.
- Stop hooks may read only the **first few hundred chars** of a tool result — a
  verification token at the end of a long combined command's output is
  invisible. Emit it as its own call.

## Adapting it

Written against macOS + git + Node/Swift with an issue tracker. The structure ports;
some detectors don't. `stat -f %B` → `stat -c %W` on Linux, drop the simulator category
off Apple platforms, skip the tracker if you don't use one, and replace
`<projects-root>` with wherever your repos live. A missing category is not a finding.

## Installation

```bash
cp -r wrap-up/ ~/.claude/skills/wrap-up/
```

**Then adapt it to your machine — this step is not optional off macOS.** The detectors
use BSD/Apple-specific commands (`stat -f %B`, `ps -o lstart`, `xcrun simctl`); a literal
copy runs subtly wrong on Linux and mis-reports rather than failing loudly. See
[Adapting it](#adapting-it) above: swap the `stat`/`ps` calls, drop the simulator category
off Apple platforms, wire or skip the issue tracker, and replace `<projects-root>` /
`<scratchpad-parent>`. If you're pointing an agent at this repo to install it, tell it to
run that checklist — not just the copy.

## Usage

```
/wrap-up              # session scope — only this session's residue
/wrap-up --dry-run    # scan + report, execute nothing
/wrap-up --deep       # also sweep machine-wide orphans from past sessions
/wrap-up --yes        # auto-run the safe tier; destructive items still need a "go"
```

## License

MIT
