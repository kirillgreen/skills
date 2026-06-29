# Attack Surface — Strategic Research Framework

Compress months of market/competitive research into hours. The difference between 3 hours and 3 months isn't the amount of information — it's knowing which questions actually matter.

## What It Does

Instead of "summarize these" or "analyze the competition", this framework extracts:
- **Unspoken Insights** — what successful players understand that customers never say out loud
- **Fragile Assumptions** — beliefs the entire market is built on, and how they break
- **Attack Surfaces** — the blind spots, the fragile consensus, the opening nobody is talking about

## How It Works

7 phases, from briefing to action plan:

| Phase | Name | What Happens |
|-------|------|-------------|
| 1 | Briefing | Interactive conversation to define the research target |
| 2 | Source Collection | 4-6 parallel AI-powered searches (competitors, reviews, industry reports, emerging players) |
| 2.5 | Source Vetting | An independent subagent (didn't gather) grades every source on authority × independence, producing a credibility ledger |
| 3 | Unspoken Insights | "What does every successful player understand that customers never say out loud?" |
| 4 | Fragile Assumptions | "What assumptions is the market built on, and how do they break?" |
| 5 | Investor Stress-Test | "5 killer questions to destroy this idea" — then evidence-based answers |
| 6 | Opportunity Mapping | Top 3 highest-leverage strategic moves with evidence |
| 7 | Action Plan | Concrete next steps: this week / this month / this quarter |

Each analytical phase has a checkpoint where you review findings and steer the research.

**Source credibility built in.** Between collection and analysis, a dedicated vetting pass grades each source on two axes — authority (Primary/Secondary/Tertiary) and independence (Independent/Interested/Unknown) — so a polished vendor blog never slides into a strategic conclusion as fact. Interested-party claims are written as "X claims…" and demoted; corroboration counts *independent evidence chains*, not raw citations. The rubric lives in `references/source-credibility.md`.

## Use Cases

- Entering a new market or vertical
- Evaluating a new feature direction
- Stress-testing a business idea before committing
- Finding competitive blind spots and underserved niches
- Assessing a partnership or platform opportunity

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI)
- [Exa MCP server](https://docs.exa.ai/reference/mcp) configured for web search and crawling

## Installation

Copy the `attack-surface/` folder to your Claude Code skills directory:

```bash
cp -r attack-surface/ ~/.claude/skills/attack-surface/
```

Then invoke it by saying "attack surface" or "research the market" in Claude Code.

## File Structure

```
attack-surface/
├── SKILL.md                          # Main skill definition (7 phases + a 2.5 vetting firewall)
├── README.md                         # This file
├── references/
│   ├── gatherer-prompt.md            # Subagent prompts for source collection
│   ├── vetting-prompt.md             # Subagent prompt for the Phase 2.5 source-vetting pass
│   ├── analyst-prompt.md             # Subagent prompts for analysis phases
│   └── source-credibility.md         # Two-axis credibility rubric (authority × independence)
└── evals/
    ├── evals.json                    # Calibration eval (frozen planted-source dossier)
    └── fixtures/                     # Frozen dossier + grader answer key for the eval
```
