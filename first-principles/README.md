# First Principles Analysis

A Claude Code skill that runs structured multi-pass first principles analysis on any problem — business, personal decisions, creative projects, career, health, relationships.

## What it does

Decomposes problems to irreducible truths, challenges every assumption through 4 universal lenses, and reconstructs solutions from verified fundamentals. Unlike single-pass templates, this skill runs 4 sequential analytical passes that build on each other.

## The 4 Passes

1. **Decomposition** — Restates the problem without inherited framing, surfaces all assumptions (10-15+), classifies them (Hard/Soft/Unvalidated), maps dependency chains
2. **Multi-Lens Challenge** — Examines through 4 universal lenses, each with a required technique:
   - **Constraints** — theoretical minimum + Five Whys
   - **Resources** — Gap Analysis (fundamental cost vs current price)
   - **Human** — 6-step Socratic Questioning + job-to-be-done
   - **Context** — Counterfactual thinking + minimum viable version
3. **Ground Truths & Reconstruction** — Tags truths with confidence (High/Medium/Low), surfaces domain blind spots, generates 3-5 solutions with cross-domain analogues
4. **Devil's Advocate** — Structured challenges with counter-arguments, concrete falsification tests, and verdicts

## Key output elements

- Assumptions Map (table with Hard/Soft/Unvalidated classification)
- Assumption dependency chains
- Explicit theoretical minimum / gap calculations
- Visible Five Whys chain
- Full 6-step Socratic Questioning sequence
- Ground truths with confidence levels
- Domain blind spots (what an expert should verify)
- Cross-domain analogues for each solution (Boyd's Snowmobile method)
- Concrete falsification tests (not rhetorical questions)
- Recommendations with "Reverse if:" invalidation conditions

## Two modes

- `/first-principles` — Standard: single-agent, sequential passes (3-5 min)
- `/first-principles deep` — Deep: parallel subagents per lens + dedicated devil's advocate (10-15 min)

## Installation

Copy the `first-principles/` folder to your Claude Code skills directory:

```bash
# Global installation
cp -r first-principles ~/.claude/skills/

# Project-specific installation
cp -r first-principles your-project/.claude/skills/
```

## Benchmark results

Tested against 3 real business analysis prompts, comparing with-skill vs baseline (no skill):

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
