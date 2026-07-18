# bugfix-pipeline

A Claude Code skill that fixes bugs the way a careful engineer does: trace the code path
that actually runs, prove the bug with a failing test, fix only what the trace pointed at,
then verify nothing else broke.

## The problem it solves

Ask an agent to fix a bug and it will grep for a plausible-looking function, find one, and
fix it. The fix is often perfectly correct — applied to code that never runs.

Real codebases make this easy. There's a `searchOrders()` in the service layer and another
`searchOrders()` in a legacy helper nobody deleted. A barrel file re-exports one of them.
Only one is imported by the route that's actually serving the request. The agent picks
wrong, edits confidently, reports success — and the bug is still there. Worse, you now
have a diff that *looks* like a fix, so the next person assumes that area was already
investigated.

This is not a knowledge problem. The agent isn't confused about how to fix the bug; it's
confused about **where the bug lives**. No amount of model capability removes it, because
the wrong file genuinely looks right in isolation.

## What it does differently

The pipeline makes wrong-path fixes structurally impossible rather than unlikely:

1. **Trace before touching.** Follow the call chain forward from the entry point — route
   handler, component, command — and check at each hop which implementation is *actually*
   imported. Dead lookalikes get listed explicitly as not-the-path.
2. **Confirm the path with the human.** One gate, before any edit. You know your codebase;
   this is the cheapest possible place to catch a wrong trace.
3. **The test must fail first.** A failing test proves the bug reproduces *in the path you
   just traced*. If it passes on the first run, that's information, not an inconvenience —
   you traced the wrong path, or the bug is already gone. Either way, stop.
4. **Constrain the fix to the traced files.** The implementer is told which files it may
   touch. If it reaches outside them, that's surfaced rather than silently accepted.
5. **Run the whole suite, not just the new test.** A fix that passes its own test and
   breaks two others isn't a fix.

## The gate that pays for the whole thing

Step 2's "test must fail" gate looks like ceremony until the day it fires. When the test
passes immediately, every downstream step would otherwise have proceeded: the implementer
would have made a change, the change would have kept the test green, and you'd have gotten
a confident report about a bug that was never reproduced.

That's the run where this skill saves you an afternoon and a misleading commit.

## Requirements

- The **`tdd-test-writer`** and **`tdd-implementer`** agents, which ship with the
  [`tdd`](../tdd/) skill in this repo. Copy its `agents/*.md` into `~/.claude/agents/`.
- A project with a runnable test suite.
- An issue tracker is **optional** — the pipeline works from a plain bug description.

## Installation

```bash
cp -r bugfix-pipeline/ ~/.claude/skills/bugfix-pipeline/
cp tdd/agents/*.md ~/.claude/agents/
```

## Usage

```
/bugfix ENG-233
/bugfix the search returns stale results after an update
```

## Relationship to `/tdd`

Same discipline, different job. `/tdd` writes a failing test to **specify behavior that
doesn't exist yet**; `/bugfix` writes one to **reproduce behavior that's broken**. The
routing rule is intent:

| Situation | Skill |
|---|---|
| New behavior | [`tdd`](../tdd/) |
| Something is broken | `bugfix-pipeline` |
| Pure refactor, no behavior change | neither — just edit |

## License

MIT
