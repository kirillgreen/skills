---
name: attack-surface
description: >
  Strategic research framework that compresses months of market/competitive research into hours through structured power questions. Extracts unspoken industry insights, fragile market assumptions, and strategic attack surfaces from competitor data, reviews, and industry sources using parallel Exa-powered intelligence gathering.
  Use when user says "attack surface", "research the market", "competitive analysis", "analyze competitors", "find market opportunity", "stress-test this idea", "market research", "evaluate opportunity", "find blind spots", "market entry", or when they want to deeply understand a market, evaluate a new direction, find industry blind spots, assess a partnership, or analyze opportunities.
  Do NOT use for code review, testing, deployment, bug fixing, or implementation tasks.
---

# Attack Surface — Strategic Research Framework

Compress months of market research into hours. The difference between 3 hours and 3 months isn't the amount of information — it's knowing which questions actually matter.

Instead of "summarize these" or "analyze the competition", this framework extracts:
- **UNSPOKEN INSIGHTS** — what successful players understand that customers never say out loud
- **FRAGILE ASSUMPTIONS** — beliefs the entire market is built on, and how they break
- **ATTACK SURFACES** — the blind spots, the fragile consensus, the opening nobody is talking about

## When to Use

- Entering a new market or vertical
- Evaluating a new feature direction for an existing project
- Assessing a partnership or platform opportunity
- Stress-testing a business idea before committing
- Finding competitive blind spots and underserved niches
- Any strategic question that benefits from deep evidence-based analysis

## Workflow Overview

7 phases plus a Source Vetting firewall (2.5), alternating between automated intelligence gathering and user-guided analysis:

| Phase | Name | Mode | Output |
|-------|------|------|--------|
| 1 | Briefing | Interactive | Research brief |
| 2 | Source Collection | Automated (parallel) | Source dossier |
| 2.5 | Source Vetting | Automated (firewall) | Credibility ledger |
| 3 | Unspoken Insights | Automated + checkpoint | Insight report |
| 4 | Fragile Assumptions | Automated + checkpoint | Assumption map |
| 5 | Investor Stress-Test | Automated + checkpoint | Stress-test results |
| 6 | Opportunity Mapping | Automated + checkpoint | Opportunity matrix |
| 7 | Action Plan & Save | Automated | Final research document |

---

## Phase 1: Briefing

Start by understanding what the user wants to research. This is an interactive conversation — ask questions until you have a clear research brief.

**Gather:**
1. **Target** — What market, industry, or opportunity? (e.g., "construction project management SaaS", "AI tutoring for K-12", "fitness tracking apps")
2. **Angle** — What's the user's position? Entering as newcomer, expanding existing product, evaluating partnership?
3. **Known competitors** — Any specific companies or products the user already knows about?
4. **User-provided sources** — URLs, files, documents the user wants included? Accept any format.
5. **Specific questions** — Anything particular the user wants answered beyond the standard framework?

**Project context:** If the research relates to an existing project the user is working on, ask about the current product, tech stack, and strategic position. This grounds the analysis in real context rather than hypotheticals.

**Output a research brief** before proceeding:
```
Research Brief:
- Target: [market/opportunity]
- Angle: [newcomer / existing player / evaluator]
- Known competitors: [list]
- User sources: [list of URLs/files]
- Key questions: [specific questions beyond standard framework]
- Project context: [if applicable, key facts about the user's product]
```

Ask user to confirm before proceeding to Phase 2.

---

## Phase 2: Source Collection

This is the intelligence-gathering phase. Launch parallel subagents to collect diverse source material via Exa MCP. The quality of analysis depends on the quality and diversity of sources.

### What to gather

Launch 4-6 parallel `general-purpose` subagents, each focused on a different source type. All subagents should use Exa MCP tools (`mcp__exa__web_search_exa`, `mcp__exa__crawling_exa`, `mcp__exa__deep_researcher_start`).

**Subagent 1: Competitor Intelligence**
Search for and crawl 5-8 competitor landing pages, product pages, and pricing pages. Extract: value propositions, positioning, pricing models, feature lists, target audience language.

**Subagent 2: Customer Voice**
Search Reddit, forums, review sites (G2, Trustpilot, Product Hunt, App Store reviews) for customer complaints, praise, and unmet needs in this market. Extract: recurring pain points, feature requests, emotional language, switching triggers.

**Subagent 3: Industry Analysis**
Search for industry reports, expert analysis, trend pieces, and earnings call transcripts. Use `deep_researcher_start` with `exa-research-pro` for comprehensive coverage. Extract: market size, growth trends, key players, regulatory landscape, technology shifts.

**Subagent 4: Adjacent & Emerging**
Search for startups entering this space, adjacent markets that could expand into it, and emerging technologies that could disrupt it. Extract: new entrants, pivot signals, technology trends, funding patterns.

**Subagent 5: User-Provided Sources** (if any)
Crawl all URLs the user provided using `mcp__exa__crawling_exa`. Extract full content.

### Subagent prompt template

Read `references/gatherer-prompt.md` for the detailed prompt template to use for each subagent. Each subagent receives:
- The research brief from Phase 1
- Its specific focus area
- Instructions to return structured, evidence-rich findings

### After collection

Compile all subagent results into a **Source Dossier** — a structured document with all collected evidence organized by source type.

**Compile the raw dossier — do NOT tier it yet.** Organize the evidence by source type with full quotes/data and the basic provenance facts for each source (author, date, publisher, and whether the item is raw data or a claim). Do **not** assign authority/independence tags here: that is the job of the independent **Source Vetting** pass (Phase 2.5), and pre-tagging would anchor that supposedly-fresh judge to your priors. (User-provided sources are included and get tiered in 2.5 too — never dropped, since the user chose them.)

Present a summary to the user:

```
Source Dossier Summary:
- X competitor pages analyzed
- X customer reviews/complaints collected
- X industry reports found
- X emerging players identified
- X user-provided sources crawled
Key themes so far: [2-3 sentences]
(Credibility mix is presented after the Phase 2.5 vetting pass, not here.)
```

Ask: "Sources collected. Anything you want me to search for specifically before we start analysis? Or should I proceed?"

---

## Phase 2.5: Source Vetting (the firewall — runs before any analysis)

This is the separation-of-duties step that keeps Phase-2 junk from becoming unquestioned ground truth for a strategic bet. **Launch a single `general-purpose` Source Vetting subagent that did NOT gather any of the sources** (a fresh judge, not a gatherer re-approving its own haul). Use the prompt in `references/vetting-prompt.md`.

It independently grades every dossier source against `references/source-credibility.md` and returns a **Credibility Ledger**: `source-ID | URL | Authority (P/S/T) | Independence (Ind/Int/Unknown) | sub-flag (manipulable/⚠vendor) | what it supports | one-line reason`.

**The ledger annotates the dossier; it does not replace it.** Phases 3-6 receive the *full source content* with each item's ledger tags attached (analysts need the quotes/data to analyze — they just now know which sources to trust).

**Fail-open (don't let a bad ledger poison everything).** The vetter is a new single point of failure feeding all downstream phases. If it errors or returns low-confidence, fall **conservative**: treat any unvetted source as **Unknown = Interested**, and write "⚠ ledger degraded" into the report — never silently fall back to trusting the raw dossier. Keep the vetter's judgment **checklist-driven** (author? date? funding signal? data-or-assertion?) so it's mechanical, not vibe, and harder to bias by the same priors that fooled the gatherer.

**Present** the credibility mix to the user (`X Independent / X Interested / X Unknown`, plus any source every later phase will lean on that is interested-only) before proceeding.

---

## Phase 3: Unspoken Insights

The first analytical question — the one that separates this from generic "market analysis":

> "Based on all collected evidence: What does every successful player in this market understand that their customers never say out loud?"

This question works because it forces the analysis past surface-level features and pricing into the deeper truths that drive the market. The insights customers can't articulate are the ones that create defensible advantages.

**Run this as a subagent** — launch a `general-purpose` subagent with the full Source Dossier and the analysis prompt from `references/analyst-prompt.md` (Section: Unspoken Insights).

**Present findings** to the user as 3-5 numbered insights, each with:
- The insight itself (one clear sentence)
- Evidence from sources (specific quotes, data points)
- Why this matters strategically

**Checkpoint:** "Here are the unspoken insights I found. Do any of these surprise you? Want me to dig deeper on any of them, or should we move to fragile assumptions?"

---

## Phase 4: Fragile Assumptions

The second power question:

> "What are the 3-5 assumptions this entire market is built on, and what would have to be true for each one to be wrong?"

This question maps the market's attack surface — the beliefs everyone takes for granted that could be upended. Every market has fragile consensus points, and finding them is how you find openings.

**Run as subagent** with Source Dossier + Phase 3 insights. Use prompt from `references/analyst-prompt.md` (Section: Fragile Assumptions).

**Present findings** as a structured assumption map:

For each assumption:
- **The assumption** (what everyone believes)
- **Evidence it's true** (why people believe this)
- **What breaks it** (specific conditions that would make it wrong)
- **Fragility score** (1-5: how likely is it to break in the next 2-3 years?)
- **If it breaks** (what happens to the market)

**Checkpoint:** "These are the fragile assumptions I found. Any you disagree with? Want to explore any further?"

---

## Phase 5: Investor Stress-Test

The third power question:

> "Write 5 questions a world-class investor would ask to destroy this business idea, then answer each one using only the evidence in our source dossier."

This is adversarial by design. The goal is to find every weak point before committing resources. A great investor's job is to find the fatal flaw — channel that mindset.

**Run as subagent** with Source Dossier + all prior analysis. Use prompt from `references/analyst-prompt.md` (Section: Investor Stress-Test).

**Present findings** as 5 numbered challenges:

For each:
- **The killer question** (phrased as an investor would ask it)
- **The evidence-based answer** (citing only our sources)
- **Confidence level** (strong / moderate / weak)
- **Remaining risk** (what the answer doesn't fully address)

**Also stress-test the evidence base, not just the idea.** A killer question can be "answered" with confident-sounding but interested-party evidence. So add one provenance pass: *which of your own answers depend on Interested/Unknown or single-chain sources?* Re-rate those **WEAK regardless of how much agreeing-but-interested evidence exists** — an all-vendor echo is not a STRONG answer.

### Iterative Deepening

Trigger deepening on **either** weakness — argument weakness **or** provenance weakness:

> "What's the strongest version of this argument and where does it still break?"

For any answer rated "weak" confidence **OR resting on a single/interested-only evidence chain**, automatically follow up with the line above. Continue until all weak points are either resolved (with an Independent chain) or clearly flagged as genuine risks. This iterative deepening is what separates a 3-hour research sprint from a surface-level analysis.

**Checkpoint:** "Here's the stress-test. X questions have strong answers, Y have remaining risks. Want to dig deeper on any of these?"

---

## Phase 6: Opportunity Mapping

Now synthesize everything into actionable opportunities:

> "Given all the unspoken insights, fragile assumptions, and blind spots we've found — what are the 3 highest-leverage entry points or strategic moves? For each, what's the evidence, what's the risk, and what would you need to validate first?"

**Run as subagent** with ALL prior analysis. Use prompt from `references/analyst-prompt.md` (Section: Opportunity Mapping).

**Present** as an opportunity matrix:

| Opportunity | Evidence | Evidence confidence | Risk | Validation Needed | Leverage (1-5) |
|-------------|----------|---------------------|------|-------------------|----------------|
| ... | ... | High/Med/Low | ... | ... | ... |

**Credibility rides in the Evidence-confidence column — it does NOT cap Leverage.** Per the rubric, Leverage stays pure impact/effort (uncapped): a high-impact bet on thin evidence is *high-leverage, low-evidence*, not low-leverage — capping it would flatten ranking in exactly the nascent, all-interested markets this skill targets. Instead: an opportunity whose evidence is interested-only → **Evidence confidence = Low**, and `Validation Needed` must begin "independent corroboration first." State confidence in the prose proportional to evidence independence, not just with a trailing tag — so a high-Leverage / Low-evidence bet reads honestly as "big if true, unproven."

**Checkpoint:** "These are the highest-leverage opportunities I see. Which ones resonate? Should I develop any of them into a concrete action plan?"

---

## Phase 7: Action Plan & Save

Based on user's selections from Phase 6, create a concrete action plan:

1. **Immediate next steps** (this week)
2. **Validation experiments** (this month)
3. **Strategic moves** (this quarter)

### Pre-save checklist (ALL must pass — this skill produces strategic bets, so the bar is high)

1. **Credibility gate:** no Unspoken Insight, Fragile Assumption, or Opportunity rests solely on Interested/Unknown sources without ≥1 Independent corroboration chain — or it is explicitly written as "X claims…" with its **Evidence confidence = Low** (opportunities) / its stress-test answer forced to **WEAK** (single Interested chain). A single *Independent-Primary* chain is not crushed — it warrants MODERATE/medium (rubric rule 6).
2. **Anti-Goodhart:** if a finding's market has no Independent source at all, it's stamped low-confidence with the conflict named — and **no** Interested source was relabeled "Independent" to pass item 1.
3. **Echo check:** corroboration counts independent chains; sources tracing to the same PR/dataset = one chain.
4. **Exec-summary honesty:** no interested-only finding headlines the Executive Summary without a caveat.
5. **Ledger present:** the Source Credibility Ledger section is filled in.

### Save the Document

Compile ALL phases into a single research document and save it.

Use this format:

```markdown
---
id: RESEARCH-YYYY-MM-DD-attack-surface-{slug}
created: YYYY-MM-DD
topic: Attack Surface Analysis — {Topic}
sources: [list of source types used]
tags: [attack-surface, market-research, {topic-tags}]
---

# Attack Surface: {Topic}

## Executive Summary
[3-5 bullet points with the most important findings]

## Research Brief
[From Phase 1]

## Source Dossier Summary
[From Phase 2 — source counts and key themes]

## Unspoken Insights
[From Phase 3]

## Fragile Assumptions
[From Phase 4 — the assumption map]

## Investor Stress-Test
[From Phase 5 — questions, answers, confidence levels]

## Opportunity Matrix
[From Phase 6]

## Action Plan
[From Phase 7]

## Source Credibility Ledger
[From Phase 2.5 vetting — table: Source | Authority (P/S/T) | Independence (Ind/Int/Unknown) | Sub-flag | What it supports]
[Credibility mix: X Independent / X Interested / X Unknown. Note any conclusion that rests on interested-only evidence.]

## Raw Sources
[Links to all sources consulted]
```

Tell the user the file path and offer to discuss any findings further.

---

## Subagent Instructions

All subagents use the `general-purpose` subagent type via the Agent tool. Read the reference files for detailed prompt templates:

- `references/gatherer-prompt.md` — Prompt template for Phase 2 source collection subagents
- `references/vetting-prompt.md` — Prompt template for the Phase 2.5 Source Vetting subagent
- `references/analyst-prompt.md` — Prompt templates for Phases 3-6 analysis subagents

When launching subagents:
- Phase 2: Launch 4-6 gatherers **in parallel** (one Agent tool call per search focus)
- Phase 2.5: Launch **1 Source Vetting subagent** — must NOT be one of the gatherers (separation of duties)
- Phases 3-6: Launch **sequentially** (each builds on prior results)
- Always pass the **credibility-annotated dossier** (full source content with each source's Phase-2.5 P/S/T × Ind/Int tag inlined next to its quotes) to analysis subagents — not the flat, unvetted dossier. Also pass the **Credibility Ledger** itself into the Phase-6 Opportunity Mapping agent's `{CREDIBILITY_LEDGER}` slot, so the Evidence-confidence column is grounded in the tags rather than guessed
- Set `run_in_background: false` for analysis subagents (need results before proceeding)

### Token Budget

This skill launches 7-11 subagent calls total. Estimated cost:
- Phase 2: 4-6 subagents x ~5-15K tokens each
- Phase 2.5: 1 vetting subagent x ~10-20K tokens
- Phases 3-6: 4 subagents x ~10-20K tokens each
- Total: ~70-170K tokens per full research session (the vetting pass is the price of not betting strategy on junk sources)

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping Phase 1 briefing | The research brief focuses everything — never skip |
| Generic Exa searches | Use specific, targeted queries from the research brief |
| Presenting analysis without evidence | Every insight must cite specific sources |
| Moving past weak stress-test answers | Always run iterative deepening on weak answers |
| Forgetting to save | Always save the final document at the end |
| Ignoring user-provided sources | Crawl them FIRST — the user chose them for a reason (but still tier them in the ledger) |
| Treating a vendor/corporate-blog claim as fact | Tag it Interested; demand an Independent corroboration chain or write it as "X claims…" and demote the score |
| Letting production polish read as authority | A glossy blog is Interested-Secondary at best — see `references/source-credibility.md` |
