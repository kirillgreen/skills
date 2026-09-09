# Custom Claude Code Skills

Custom AI Agent Skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by Kirill Oleinichenko.

## Available Skills

| Skill | Description |
|-------|-------------|
| [attack-surface](attack-surface/) | Strategic research framework that compresses months of market research into hours through 3 power questions |
| [bugfix-pipeline](bugfix-pipeline/) | Bug fixing with test gates — traces the code path that *actually runs* before editing, so the fix can't land on a dead lookalike |
| [deep-research](deep-research/) | Multi-source research with inline citations, source quality tiers, contradictions analysis, and adversarial review |
| [deploy-verify](deploy-verify/) | Deploy to staging and prove it works — pre-flight gates, smoke tests, failure diagnosis, ending in a machine-readable verdict artifact `ship` can trust |
| [first-principles](first-principles/) | Multi-pass first principles analysis that decomposes problems to fundamental truths through 4 universal lenses |
| [naming-gate](naming-gate/) | Filename conventions with teeth — a write-time hook that denies a non-conforming name, sharing one negative list with the sweep, and failing open on every failure of its own machinery |
| [ship](ship/) | Production-release orchestrator — verifies before AND after release, and refuses to call a store upload "live to users"; a thin engine over a per-project recipe |
| [tdd](tdd/) | Spec-driven Test-Driven Development — strict Red-Green-Refactor with three isolated subagents, three-dimension spec verification, and a spec-defect escape hatch |
| [wrap-up](wrap-up/) | End-of-session ritual — one scan, one report, one approval; leaves nothing uncommitted, unmerged, or orphaned, and refuses to claim "clean" when a probe failed |

## What Are Skills?

Skills are specialized knowledge modules for Claude Code — structured prompts that teach the AI agent how to perform complex multi-step workflows. Each skill is a self-contained folder with a `SKILL.md` definition and optional reference files.

`check-rubric-drift.sh` at the repo root is a maintenance helper, not a skill: `deep-research` and `attack-surface` share a source-credibility rubric, and this script fails if the two copies drift apart. Wire it into a pre-commit hook or ignore it — it's not needed to use any skill.

## Which one when

`tdd` and `bugfix-pipeline` are a pair — same discipline, routed by intent:

| Situation | Skill |
|---|---|
| New behavior | [`tdd`](tdd/) — the failing test *specifies* it |
| Something is broken | [`bugfix-pipeline`](bugfix-pipeline/) — the failing test *reproduces* it |
| Pure refactor, no behavior change | neither |
| Session is over | [`wrap-up`](wrap-up/) |

`ship` and `deploy-verify` are the other pair — same discipline, different altitude:

| Situation | Skill |
|---|---|
| Prove a change works on staging, no release | [`deploy-verify`](deploy-verify/) |
| Take a finished change all the way to released | [`ship`](ship/) — it *calls* `deploy-verify` where a project has staging |
| Release a project with no staging at all | [`ship`](ship/) alone — prod-only mode never calls `deploy-verify` |

## Installation

Copy any skill folder to your Claude Code skills directory:

```bash
cp -r <skill-name>/ ~/.claude/skills/<skill-name>/
```

`bugfix-pipeline` reuses the `tdd-test-writer` and `tdd-implementer` agents that ship
with `tdd` — install those too:

```bash
cp tdd/agents/*.md ~/.claude/agents/
```

`ship` reads a per-project **release recipe** and does nothing irreversible without one —
on first encounter with an un-recipe'd project it runs `--dry-run` and offers to draft
it. `ship/references/recipe-schema.md` is the schema. It also assumes two things this
repo doesn't ship: a `code-reviewer` agent (use your own — but keep its power to *halt*
the release) and, optionally, a merge guard that denies pushes to `main` without an
explicit token. Both are covered in the skill's "Adapting this to your setup" section.

Two other skills need a second step. `bugfix-pipeline` reuses agents that ship with `tdd` (above),
and `naming-gate` ships executable machinery rather than prompt text — it needs a config of
your own and a `PreToolUse` hook in `settings.json`. Its README has both, and its test suite
runs green from a fresh clone with nothing installed:

```bash
bash naming-gate/tests/run.sh
```

## License

MIT
