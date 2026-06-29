# deep-research

A Claude Code skill for conducting thorough, multi-source research on any topic.

## What it does

Transforms Claude from "search and summarize" into a structured research process with inline citations, source quality tiers, contradictions analysis, and a pre-publish checklist.

Two modes:
- **Standard** (`/deep-research`) — one researcher + a source-vetting subagent, 10+ sources, ~7 min
- **Deep** (`/deep-research deep`) — multi-agent with parallel subagents, 20+ sources, adversarial review, UNION merge, ~15-45 min

## Why use it

Opus is already an excellent researcher. Without this skill, it produces great reports — sometimes. The problem is inconsistency: one run gives you 33 sources and deep analysis, the next gives you a shallow overview with no citations.

This skill doesn't make every research 2x better. It eliminates the bad runs.

### What changes

| Without skill | With skill |
|--------------|------------|
| Citations sometimes present, sometimes not | Every factual claim gets `[N]` inline citation |
| No contradictions analysis | Dedicated "Contradictions & Open Questions" section |
| No confidence assessment | Claims rated High/Medium/Low with reasoning |
| No research metadata | Source counts, queries, pages read tracked |
| Source diversity unchecked | Max 25% from any single domain |
| Geographic bias unnoticed | Non-US perspectives explicitly sought |
| Executive summary sometimes | Always leads the report |
| Polished vendor/corporate blogs trusted as authoritative | Two-axis credibility (authority × independence); interested-party claims written as "X claims…", never bare fact |
| Confidence keyed to source count | Confidence keyed to *independent evidence chains* (echoes collapsed) |
| Quality range: 49-69/80 | Consistent 65-70/80 |

### Benchmark data (tested across 6 research topics)

**Standard mode:**
- Quality: 65-70/80 (vs 49-69 baseline — higher floor, similar ceiling)
- Sources: 22-27 consistently (vs 13-33 unpredictably)
- Tokens: ~75K per research (~25% premium over no-skill)
- Time: ~7-10 min

**Deep mode:**
- Quality: 71/80 (vs 49 baseline — +22 points)
- Sources: 33 with adversarial review
- Tokens: ~88K per research
- Time: ~8-15 min

The skill is worth the token premium not for peak quality, but for consistency. You never have to re-prompt for missing citations or wonder if contradictions were smoothed over.

> **Note:** these benchmark numbers predate the source-credibility upgrade (two-axis tiering, vetting pass, conclusion gate, independent-chain confidence). The credibility layer is validated separately by the calibration eval in `evals/` (frozen planted-source dossier, polarity-aware grading) rather than by this quality score.

## Structure

```
deep-research/
├── SKILL.md                      # Main skill (phases, templates, checklist)
├── README.md                     # This file
├── references/
│   ├── deep-mode.md              # Detailed subagent orchestration for deep mode
│   └── source-credibility.md     # Two-axis credibility rubric (read before tiering/citing)
└── evals/
    ├── evals.json                # Calibration eval (frozen planted-source dossier)
    └── fixtures/                 # Frozen dossier + grader answer key for the eval
```

## Key techniques

Built from research into the top open-source deep research implementations (199-biotechnologies, XInTheDark, daymade/claude-code-skills, GPT-Researcher, Anthropic multi-agent patterns):

- **Breadth-first search** — start broad, narrow as uncertainty drops
- **Two-axis source credibility** — authority (Primary/Secondary/Tertiary) × independence (Independent/Interested/Unknown); production polish ≠ authority; reconciled with the legacy A/B/C tiers in `references/source-credibility.md`
- **Independent vetting pass** — a second agent that didn't gather grades the sources (separation of duties); fails-open to Unknown=Interested
- **Independent evidence chains** — corroboration counts chains, not citations (two sources tracing to one PR = one chain)
- **Anti-hallucination protocol** — every claim needs `[N]` citation in same sentence
- **Citation hygiene** — no orphan sources, no phantom references
- **UNION merge** (deep mode) — multiple agents write complete drafts, merge keeps all unique findings
- **Adversarial review** (deep mode) — contrarian agent attacks conclusions with counter-evidence
- **12-point pre-publish checklist** — source count, citation audit, diversity, geographic scope, credibility gate, anti-Goodhart, exec-summary caveat

## Usage

```
/deep-research What are the best approaches to real-time collaborative editing?
```

```
/deep-research deep What is the current state of AI regulation across EU, US, and Asia? Practical compliance implications for a SaaS startup.
```

```
/deep-research 20 Compare vector databases — I need at least 20 sources
```

## Installation

Copy the `deep-research/` folder to `~/.claude/skills/` (or your skills directory).

Requires: Exa MCP (primary search) or WebSearch (fallback), WebFetch (page reading), Agent tool (deep mode subagents).
