# naming-gate

A Claude Code skill that enforces your filename convention at the moment a file is created,
rather than documenting it and hoping. A PreToolUse hook checks the name a `Write` is about to
use, denies it with the specific reason and the canonical form for that folder, and lets
everything else through.

The convention shipped here is an example. What transfers is everything around it.

## The problem it solves

You write the convention down. You put it in `CLAUDE.md`, or a rule file, or the project's
instructions — somewhere the agent genuinely reads every session. For a while it holds.

Then one file lands with a kebab-case name. Maybe a stale template produced it, maybe an
older instruction file in one project still described the previous dialect. The next agent
opens that folder, sees the neighbours, and matches them — because imitating what is already
there is a stronger signal than a rule sitting in context, and it is *usually the right
instinct*. Now there are two. A month later your notes tree has three dialects, links break
on the renames you eventually do, and sorting by name stops meaning anything.

The naming rule was in context the entire time. That is the part worth sitting with: this
does not fail because the agent didn't know. It fails because knowing and doing are
different, and nothing was checking.

## What it does differently

1. **The rule is checked, not just published.** A `Write` under a governed root is validated
   before the file exists. The convention stops being advice.
2. **Validation is a negative list, because parsing is not validating.** A grammar's parse
   expression has a catch-all title slot, so it matches `2026-09-05-quarterly-review` exactly
   as happily as a canonical name. Any regex loose enough to *parse* your convention is too
   loose to *enforce* it. So the lint enumerates the ways a name goes wrong instead, each
   with a code it can quote back at you.
3. **One list, two callers.** A blocking write-time gate and a periodic sweep that each own a
   copy of the rules drift apart within weeks. The gate holds no checks of its own — it shells
   out to `naming-lint.sh -n` (name mode: no disk access, the path need not exist), which is
   the same command a sweep runs. There is one implementation and no way to skew them.
4. **Every failure of the gate's own machinery fails OPEN.** Its own section below.
5. **A root is governed only once its files already lint clean.** Turn the gate on over a
   folder whose neighbours are non-conforming and it starts denying names that match every
   file around them. That is how a gate gets switched off permanently on its second day. The
   example config excludes a `imports/` folder of tool exports and an `archive/` of frozen
   versions for exactly this reason.
6. **Per-folder policy is data, not code.** Which folder implies which genre, which roots are
   gated, what a deny message suggests — all of it is `naming.conf`, read by both scripts. The
   table also exists in prose for humans, and the test suite pins the two together as a
   **pair** (folder → genre), in both directions. Pinning the folder name alone lets the
   mapping drift silently, which is what a review caught by mutation: repointing a folder's
   genre used to pass.
7. **Escape hatches shaped so they cannot become permanent.** Its own section below.

Points 4 and 7 are the two that are easy to get wrong on the first attempt, so they get the
rest of the page.

## Fail open, always

A blocking hook that denies writes when its own plumbing breaks is worse than no hook. The
asymmetry is not close: a false deny costs an agent's turn and a human's attention, and it
arrives looking like a rule violation rather than a bug. A false allow costs one badly named
file that a sweep catches later.

So every failure mode is enumerated and each one lets the write through:

| What breaks | What happens |
|---|---|
| `jq` missing | empty tool name, exit 0 |
| input is not JSON, or has no `file_path` | exit 0 |
| `naming-lint.sh` missing, unreadable, or syntactically broken | no output → no codes → exit 0 |
| lint writes non-TSV noise | empty code field → exit 0 |
| `naming.conf` missing or unreadable | tables empty → nothing is governed → exit 0 |
| a malformed row in the config | that row is skipped, the rest load |
| a `governed` value that is neither `yes` nor `no` | treated as `no`, with a line on stderr |
| the lint reports a code this gate cannot explain | that code is ignored, with a line on stderr |

The last two rows are the interesting ones, and for the same reason: failing open *silently*
is its own bug.

A trailing space after `yes` once made that value compare unequal, ungoverning an entire root
with nothing visible in the file to explain it. So the gate fails open **and says so** — the
write proceeds, and stderr names the root it skipped.

The unknown-code row is the same instinct pointed the other way. The gate denies only on codes
it can *explain*; one it has never heard of — a lint mid-edit, or a lint upgraded ahead of the
gate — would otherwise produce a block with an empty reason underneath it. A deny that says
nothing about why is worse than no deny at all.

Fresh installs work the same way. The bundle deliberately ships no `naming.conf`, only
`naming.conf.example`, so a gate that is wired up but not yet configured governs nothing.
You turn it on one root at a time.

## Escape hatches with the right shape

Two, and the shape of each matters more than its existence:

- **`/tmp/.naming-gate-allow`** — a one-shot for a name that is a deliberate exception. It is
  consumed **only when an offence is real**. Consuming it on first sight would let any
  conforming write earlier in the same turn eat the token before the exceptional name is ever
  attempted, and the human would watch their exception silently not apply.
- **`/tmp/.naming-gate-paused`** — pauses the gate for four hours *from the file's mtime*. A
  forgotten pause re-arms itself. And a future mtime is not "fresh" either, so `touch -t` with
  a date in 2099 cannot make the pause permanent.

Both are the human's to create. An agent that creates its own escape hatch has no gate — and
no code can prevent that, which is why `SKILL.md` says so in as many words. If you are wiring
this up for an agent, keep that line.

## What counts as a bad name

The whole list, and it is meant to be edited:

| Code | Example | Why |
|---|---|---|
| `kebab-date` | `2026-09-05-quarterly-review.md` | date glued to the title |
| `kebab-adr` | `ADR-0015-drop-legacy-index.md` | series key glued to the title |
| `slug-like` | `council-pricing-notes.md` | the whole name is a slug |
| `braces` | `2026-09-05 {draft} notes.md` | shell brace expansion; template collisions |
| `underscore` | `meeting_notes.md` | `_` in prose (`API_NOTES` is a constant, exempt) |
| `two-dashes` | `2026-09-05 X — a — b.md` | exactly one ` — ` separates head from title |
| `spaced-endash` | `2026-09-05 X – y.md` | the en-dash is for ranges, unspaced |
| `forbidden-char` | `Q3: results.md` | one of `\ : * ? " < > \| # ^ [ ]` breaks Finder or Obsidian |
| `too-long` | over 100 characters | the name without its extension, counted in characters not bytes |
| `redundant-type` | `plans/2026-09-05 X · Plan — y.md` | the folder's genre is already implicit |

Nine of the ten are pure string checks and need no configuration. Only `redundant-type` reads
the per-folder table, which is why a missing config costs you that check and nothing else.

## Requirements

`bash` (3.2 is fine — no associative arrays anywhere), `jq` for the hook, `awk` and `grep`.
macOS and Linux. No other dependencies, nothing to install.

## Installation

```bash
mkdir -p ~/.claude/skills
cp -r naming-gate ~/.claude/skills/
cp ~/.claude/skills/naming-gate/naming.conf.example ~/.claude/skills/naming-gate/naming.conf
```

Then wire the hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/skills/naming-gate/naming-gate.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Invoking it through `bash` rather than directly is deliberate: it removes any dependence on the
executable bit, which does not survive every way a file gets onto a machine. A hook that fails
to execute is reported as a non-blocking error and every Write goes through — a gate that looks
installed and enforces nothing.

The scripts locate each other as siblings, so the folder can live anywhere — move all of it
or none of it.

Now edit `naming.conf`: the example governs `~/notes/` and a Russian-language diary tree that
almost certainly are not yours. Point the `governed` rows at a folder you have, and read the
invariant in `SKILL.md` before adding the second one.

Verify the wiring end to end:

```bash
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/notes/plans/2026-09-05-bad-name.md"}}' "$HOME" \
  | bash ~/.claude/skills/naming-gate/naming-gate.sh
```

A `permissionDecision: deny` with a readable reason means it is live. Silence means that path
is not governed — which is the correct answer until you have edited the config.

## The test suite

89 assertions, no installation required, green from a fresh clone:

```bash
bash naming-gate/tests/run.sh
```

It runs against a sandboxed `$HOME` and a **copy** of the bundle, so it never touches your
notes — and so it can break the copy on purpose. 41 of the 89 assertions exist to prove things
that must *not* happen: a broken lint must not block, a stale pause must not disarm, a
conforming write must not spend the one-shot token, a `..` that escapes a governed root must
not be judged by it, a folder's genre must not drift away from the prose table.

The suite is written to be *mutation-tested*, and it earns that claim: reverting any one of
the fixes in it — the GNU-`stat` dialect handling, the `..` normalization, the unknown-code
filter, the trailing-space strip, the locale probe, the 100-character cap, the CRLF handling,
the `doc` record — turns exactly the assertion that names it red, and nothing else. If you
fork this, keep that property: an assertion no mutation can break is decoration.

Two habits worth stealing from it, whatever you are testing:

- **Every exemption assertion uses an input that would be a finding without the exemption.**
  A name that trips nothing either way proves nothing about the code it claims to guard.
- **The `governed`-root assertions are generated from the config.** Add a root, and it is
  covered without writing a test — which is the only version of "keep the tests in sync" that
  actually survives contact with a busy week.

## Turning it off

Fastest to most permanent: `touch /tmp/.naming-gate-paused` (four hours) · set the `governed`
rows to `no` · delete `naming.conf` (governs nothing, everything else keeps working) · remove
the `PreToolUse` block from `settings.json`.

`naming-lint.sh` stays useful on its own with no hook wired at all — as a pre-commit check,
or a periodic sweep over a folder you would rather clean up than police.

## License

MIT
