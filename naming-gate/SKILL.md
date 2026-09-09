---
name: naming-gate
description: >
  Enforce a filename convention for notes, docs, research, plans and transcripts at the moment
  a file is created, instead of documenting it and hoping. Ships a write-time PreToolUse hook
  that denies a non-conforming Write, a lint that is the single negative list both the hook and
  any periodic sweep call, and a per-folder config so the policy is data rather than code.
  Use when naming or renaming an artefact file, when a write was blocked by the naming gate,
  when auditing an existing folder for drift ("check the names in notes/"), when adding a
  folder to the gate, or when setting the convention up for a project.
  Do NOT use for source-code identifiers, repo/branch names, or anything the language's own
  convention already governs.
---

# naming-gate — a filename convention with teeth

Two artefacts and one config:

| File | What it is |
|---|---|
| `references/grammar.md` | the convention itself — **an example, meant to be replaced** |
| `naming-lint.sh` | the negative list: the enumerated ways a name breaks the grammar |
| `naming-gate.sh` | a PreToolUse hook that denies a `Write` whose name trips the list |
| `naming.conf` | which folder implies which genre, which roots are gated, what a deny says |

The grammar is the replaceable part. The machinery is the point.

## Naming a file

Read the grammar document — `references/grammar.md`, or whatever the `doc` row of
`naming.conf` points at, which is what a deny message names. The example convention is:

    ⟨key⟩ ⟨Scope⟩ · ⟨Type⟩ — ⟨title⟩ (⟨qualifier⟩).ext
    2026-09-05 Payments — reconciliation gaps in the nightly job.md

Two things trip agents up more than the formula does:

1. **A folder's default genre is implicit.** In a folder that only holds plans, writing
   `· Plan` into the name is noise, and the lint reports it as `redundant-type`. Check the
   default-genre table before adding a Type.
2. **The parse regex is not a validator.** Its title slot is a catch-all, so it happily
   accepts `2026-09-05-quarterly-review`. Matching it proves nothing. If you want to know
   whether a name is legal, run the lint.

Check a name before writing it — no file needs to exist:

```bash
bash naming-lint.sh -n "$HOME/notes/plans/2026-09-05 Payments — nightly job.md"
```

Silence and exit 0 mean it is fine. Otherwise you get one `path<TAB>code` line per problem.

## When the gate blocks a write

The deny message names the codes it found and the canonical form for that exact folder.
**Rename and write again.** That is the whole remedy in almost every case.

Do not reach for the escape hatch. `touch /tmp/.naming-gate-allow` is a one-shot the human
creates when a name is a deliberate exception; an agent that creates its own escape hatch has
disabled its own gate, and nothing in the code can stop it — only this instruction can.
If you believe the name is right and the gate is wrong, say so and let the human decide.

Same for `/tmp/.naming-gate-paused` (a 4-hour pause) — the human's switch, not yours.

## Sweeping a folder

```bash
bash naming-lint.sh ~/notes            # every *.md, recursive
bash naming-lint.sh -a -q ~/notes      # every file; summary line only
```

Exit 1 means findings. Hidden files, ALLCAPS singletons (`README.md`, `INDEX.md`, `*_META.md`
…), `templates/`, `*-baseline/` bundles and `.claude/` are skipped by design — they are named
by their role, not by the grammar.

## Adding a folder to the gate

The invariant, and it is not negotiable:

> **A root may only be governed once its existing files already lint clean.**

Govern a root whose neighbours are non-conforming and the gate starts denying names that match
every file around them. That is how a gate gets switched off on its second day. So:

1. `bash naming-lint.sh <root>` → must print `0 finding(s)`.
2. Not clean? Either rename the stragglers first, or exclude the sub-folder that is legitimately
   different — tool exports, frozen versions — with a `governed … no` row **above** the
   catch-all. First match wins.
3. Add `governed	<glob>	yes`, then re-run `tests/run.sh`: the suite drives every `yes` root
   from the config, so the new one is covered without writing a test.

## Editing the config

`naming.conf` is TAB-separated, four record types (`genre`, `governed`, `form`, `doc`), first
match wins inside each type. Its header documents the format; two traps are worth repeating:

- A glob is matched with bash `case`. `~/` means `$HOME`, but **`|` is not alternation** —
  inside a variable expansion it is a literal, so a row written with `|` matches nothing and
  reports no error. Write two rows.
- A `genre` row and the table in the grammar document are one fact in two places. Change both.
  `tests/run.sh` fails if they disagree in either direction, including when the folder still
  matches but the genre no longer does.

After any config change:

```bash
bash tests/run.sh
```

## What this deliberately does not check

A Type that is **missing** where the folder has no default genre. Telling a Type word from a
title word needs the closed vocabulary and still guesses, and this list feeds a blocking hook
where a false positive costs real work. A human reading a sweep catches those.

A file created through Bash (`cat > x.md`, `mv`, a script) is also invisible to the hook —
the gate sees `Write`, not shell. The periodic sweep is what covers that gap.
