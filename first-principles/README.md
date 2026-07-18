# First Principles Analysis

A Claude Code skill that runs structured multi-pass first principles analysis on any problem — business, personal decisions, creative projects, career, health, relationships.

## What it does

Grounds the analysis in real evidence first, decomposes problems to irreducible truths, challenges every assumption through 4 universal lenses, and reconstructs solutions from evidence-backed fundamentals. Unlike single-pass templates, this skill runs sequential analytical passes that build on each other — and it refuses to invent the numbers it reasons with.

## The Passes (0-4)

0. **Evidence Intake** — Gathers the facts the analysis will stand on before decomposing: prior research, sourced external numbers, and (for personal decisions) targeted questions to the user. Every fact is tagged `[verified]` / `[user-stated]` / `[model-knowledge]` / `[unverified]` — an analysis with no evidence base is a well-formatted guess
1. **Decomposition** — Restates the problem without inherited framing, surfaces all assumptions (10-15+), classifies them (Hard/Soft/Unvalidated), maps dependency chains
2. **Multi-Lens Challenge** — Examines through 4 universal lenses, each with a required technique:
   - **Constraints** — theoretical minimum (from real Pass 0 numbers, never invented) + Five Whys
   - **Resources** — Gap Analysis (fundamental cost vs current price)
   - **Human** — 6-step Socratic Questioning + job-to-be-done
   - **Context** — Counterfactual thinking + minimum viable version
3. **Ground Truths & Reconstruction** — Tags truths with confidence derived from evidence tags (not from how many lenses agree — lens agreement is coherence, not corroboration), surfaces domain blind spots, generates 3-5 solutions with cross-domain analogues
4. **Devil's Advocate** — Runs as a **fresh subagent** (context isolation beats self-critique sitting on its own anchors), produces counter-arguments, concrete falsification tests — executing the ones runnable in-session — and per-conclusion verdicts (survives/weakened/demoted) plus global checks

## Key output elements

- Evidence Base with source tags — the facts the analysis is built from
- Assumptions Map (Hard/Soft/Unvalidated classification + post-challenge Status)
- Assumption dependency chains
- Theoretical minimum / gap calculations from sourced numbers (or an honest `[unverified]` tag)
- Ground truths with evidence-derived confidence levels
- Domain blind spots (what an expert should verify)
- Cross-domain analogues for each solution (Boyd's Snowmobile method)
- Concrete falsification tests — run in-session where executable, not just named
- Recommendations with "Reverse if:" invalidation conditions

The output rule throughout: insight over completed templates. A lens that yields nothing says so in one line; technique chains (Five Whys, Socratic steps) appear in full only when they surfaced something non-obvious.

## Three modes

- `/first-principles lite` — Quick sanity check: assumptions map + top-3 challenges by dependency depth + one reconstruction, inline, no subagents
- `/first-principles` — Standard: sequential passes; devil's advocate as a subagent
- `/first-principles deep` — Deep: 4 parallel lens subagents with full evidence briefs + dedicated contrarian subagent (see `references/deep-mode.md` for the brief template, structured ground-truth records, and the merge procedure)

## Installation

Copy the `first-principles/` folder to your Claude Code skills directory:

```bash
# Global installation
cp -r first-principles ~/.claude/skills/

# Project-specific installation
cp -r first-principles your-project/.claude/skills/
```

## Benchmark results

Measured on v2, before the evidence-first rework. Tested against 3 real business analysis prompts, comparing with-skill vs baseline (no skill):

| Metric | With Skill (v2) | Baseline |
|--------|----------------|----------|
| Structural assertions (15) | **100%** pass | 24.4% pass |
| Mean time | 268s | 159s |
| Mean tokens | 38.5K | 31.6K |

The skill's main value is **structural discipline** — it forces explicit assumption classification, multi-angle analysis, cross-domain thinking, and self-challenge. Baseline often produces good insights but in a less systematic, less reproducible format.

## Research

Built from deep research on first principles thinking methodology:
- Aristotle's *archai*, Descartes' systematic doubt
- Elon Musk's 3-step process (SpaceX rockets, Tesla batteries)
- Socratic Questioning, Five Whys (Toyota), Counterfactual Thinking
- Boyd's Snowmobile method for cross-domain transfer
- Lessons from `principled-claude-code` (archived — enforcement gates are an anti-pattern)

## License

MIT
