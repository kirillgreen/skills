---
name: deep-research
description: >
  Conduct deep, multi-source research on any topic using parallel subagents, Exa search, and adversarial validation.
  Two modes: /deep-research (standard: 10+ sources, thorough single-agent) and /deep-research deep (multi-agent with 20+ sources, adversarial review, UNION merge).
  Use when the user asks to research a topic, investigate a question, find information across multiple sources,
  compare approaches, understand a domain, or says "research this", "deep dive", "investigate", "find out about",
  "what are the best practices for", "compare options for", "глубокое исследование", "ресерч", "исследуй",
  "найди информацию", "разберись в теме". Also use when the user wants competitive analysis, technology evaluation,
  or needs to understand a complex topic before making a decision.
  Do NOT use for simple factual questions answerable in one search, code review, bug fixing, or implementation tasks.
---

# Deep Research

Research any topic with the rigor of an expert analyst. The difference between good and great research isn't volume — it's knowing when to go wide, when to go deep, and when your sources are lying to you.

This skill produces research that surfaces **non-obvious insights**, **flags contradictions**, and **cross-references claims** across independent sources — rather than summarizing whatever comes up first in search results.

**Write like an expert journalist, not an AI assistant.** Lead with the most important findings. No filler phrases ("It's worth noting", "In today's landscape", "It's important to understand"). Every factual claim gets a `[N]` citation in the same sentence — not at the end of a paragraph, not as a footnote, but right next to the claim it supports.

## Modes

| Mode | Invoke | Min sources | Time | Token cost | When to use |
|------|--------|-------------|------|------------|-------------|
| **Standard** | `/deep-research` | 10+ | 3-10 min | ~5x chat | Most research questions — go deep by default |
| **Deep** | `/deep-research deep` | 20+ | 15-45 min | ~15x chat | High-stakes decisions, when you need adversarial validation and multi-agent coverage |

The user can also specify effort as a number: `/deep-research 15` means "use at least 15 sources."

**Important:** The source minimums are floors, not ceilings. If the topic is rich and you're finding valuable sources, keep going. A standard-mode research that finds 30 great sources is better than one that stops at 10 because "the minimum is met." Search as broadly and deeply as the topic warrants — the skill adds structural discipline, not artificial limits.

---

## Standard Mode (5 phases)

Single-agent with structured search, source quality filtering, and synthesis. Standard mode should be thorough — don't cut corners on search breadth just because it's not "deep mode." The difference from deep mode is architecture (single-agent vs multi-agent), not ambition.

### Phase 1: Scope

Understand what the user actually needs to know and why. This shapes everything downstream.

**Ask (if not obvious from context):**
- What's the core question? Not the topic — the *decision* or *understanding* they need.
- What do they already know? (Avoid re-discovering what's obvious to them.)
- Any known sources, constraints, or angles?

If the user gave a clear prompt, skip the interview and extract answers from context. State your interpretation and proceed.

**Output:** A research brief — 3-5 bullet points capturing the question, angle, known constraints, and success criteria.

### Phase 2: Decompose & Search

Break the question into 3-5 sub-questions that, when answered together, fully address the original question.

**Search strategy — breadth first, then narrow:**

1. Start with **short, broad queries** via Exa. Broad queries surface the landscape; specific queries miss the unexpected.
2. Evaluate what's available — which sub-topics have rich sources? Which are sparse?
3. Follow up with **narrower, targeted queries** based on what you found.

Use advanced search operators when helpful: `"exact phrase"`, `site:domain.com`, date filters.

**Tools:**
- `mcp__exa__web_search_exa` — primary search (AI-powered, better for conceptual queries)
- `WebSearch` — fallback for factual/current queries
- `mcp__exa__crawling_exa` — extract content from specific URLs

**Per sub-question:** Run 2-3 search queries with different phrasings. Variety in query formulation is how you escape the filter bubble.

**Don't stop early.** Run multiple search iterations: search → read → reflect → search again with refined queries. The first pass gives you the landscape; the second pass fills gaps; the third surfaces the non-obvious. If you're finding valuable sources, keep searching — depth matters more than speed.

### Phase 3: Read & Extract

For each promising result, read the **full page** (not snippets). Snippets miss context, caveats, and methodology.

- Use `WebFetch` or `mcp__exa__crawling_exa` to read full content
- Read 3-5 pages per search iteration minimum
- Extract: key claims, data points, exact quotes, methodology, author credentials
- Note the **source type**: primary research, industry report, blog post, documentation, forum discussion

**Source quality tiers** (don't let SEO farms dominate your research):

| Tier | Examples | Use |
|------|----------|-----|
| **A — Authoritative** | Academic papers, official docs, gov data, standards bodies, regulatory filings, practitioner blogs with data | Primary evidence. Cite freely. |
| **B — Credible** | Reputable journalism, analyst reports with methodology, company tech blogs, conference talks | Supporting evidence. Cross-reference with Tier A when possible. |
| **C — Supplementary** | Opinion pieces, marketing content, aggregators, forum discussions | Use sparingly. Never as sole source for a claim. |
| **Exclude** | No author/date, unverifiable, clearly outdated, SEO content farms | Do not cite. |

When a blog post references a study — find the study. Chase primary sources. Secondary sources introduce telephone-game distortion.

**Source diversity rule:** No single domain (e.g., crunchbase.com, techcrunch.com) should account for more than 25% of your sources. If you notice concentration, deliberately search for alternative source ecosystems — academic databases, industry associations, government data, regional publications, practitioner blogs. Concentration = blind spot.

**Geographic awareness:** Default search results skew US/English. If the topic has global relevance, explicitly search for perspectives from other markets (EU, Asia, emerging markets). Add geographic qualifiers to at least one search query per sub-question. A US-only analysis should be flagged as such in the report, not presented as universal.

### Phase 4: Synthesize

Combine findings into a coherent answer. This is where mediocre research fails — by smoothing over contradictions to create a clean narrative.

**Instead:**
- **Flag contradictions explicitly.** "Source A claims X [1], but Source B found Y [2]. The difference may be because..."
- **Distinguish confidence levels.** Some claims have strong multi-source support; others are single-source speculation.
- **Surface minority viewpoints.** The consensus answer isn't always right. If credible sources disagree, say so.
- **Cross-reference:** Every significant claim should appear in 2+ independent sources. Single-source claims get flagged.

**Anti-hallucination protocol:**
- Every factual claim requires a `[N]` citation in the same sentence
- Distinguish fact (cited) from synthesis (your analysis connecting facts) from speculation (explicitly labeled)
- If you can't verify a claim, flag it: "uncertain — could not verify"
- Never fabricate citations. If you read something but lost the URL, say so rather than inventing one

**Citation hygiene (check before packaging):**
- Every source in the Sources list must be cited at least once in the body text. If a source isn't cited, either cite it where relevant or remove it — orphaned sources erode trust.
- Every `[N]` in the body must have a corresponding entry in Sources. No phantom references.
- Scan your draft for uncited factual claims (numbers, percentages, dates, named findings). Each one needs a `[N]` or an explicit "based on the author's analysis" qualifier.

### Phase 5: Package

Produce the final report using the structure in [Report Format](#report-format) below.

**For long reports (>5K words):** Write each section individually to disk using the Edit tool, building the report progressively. This prevents context overflow and ensures nothing gets lost.

Before finalizing, run the **pre-publish checklist** (ALL must pass):
1. Minimum source count reached (10 for standard, or user-specified number)
2. All sub-questions answered with adequate source support
3. At least 2-3 search iterations completed (not just one pass)
4. Major contradictions investigated and explained (not hidden)
5. Conflicting information resolved or explicitly acknowledged
6. Could you defend each conclusion if challenged? If not, add evidence or a confidence qualifier
7. **Citation audit:** every source in the list is cited in the body; every `[N]` in the body has a source. No orphans in either direction
8. **Source diversity:** no single domain accounts for >25% of sources
9. **Geographic scope:** if the topic is global, non-US perspectives are represented (or the US-focus is explicitly flagged)

---

## Deep Mode (8 phases)

For high-stakes research where being wrong is expensive. Read `references/deep-mode.md` for detailed subagent instructions before proceeding.

### Phase 1: Scope & Decompose

Same as Standard Phase 1, but decompose into **8-12 sub-questions** organized into 3-4 research threads.

### Phase 2: Plan & Assign

Design the research strategy. Create a research plan that assigns sub-questions to parallel subagents.

**Subagent design principles** (from Anthropic's multi-agent research):
- Each subagent gets a **specific objective**, **output format**, **tool guidance**, and **clear boundaries**
- Vague instructions like "research topic X" cause duplication and gaps
- Assign 2-3 sub-questions per subagent, grouped by theme
- Include one dedicated **Knowledge Gap Agent** that reviews all intermediate findings and identifies what's missing

### Phase 3: Parallel Retrieve

Launch subagents via the `Agent` tool. Each subagent follows the Standard Mode phases 2-4 independently.

**Subagent prompt template:**
```
You are a research subagent investigating: [specific sub-questions]

Context: [research brief, what other subagents are covering]

Instructions:
1. Search for information using mcp__exa__web_search_exa and WebSearch
2. Read full pages with WebFetch for the most relevant results
3. For each claim, note the source URL, author, and your confidence
4. Flag any contradictions or surprising findings
5. Write your findings as structured notes (not a polished report)

Output format:
## Findings
[For each sub-question: answer, evidence, sources, confidence (high/medium/low)]

## Contradictions & Surprises
[Anything unexpected or conflicting]

## Source List
[URL, title, type, quality score 1-5]

Save output to: [workspace path]
```

Launch all research subagents in a **single message** for maximum parallelism.

### Phase 4: Triangulate

After subagents return, cross-reference findings:
- Claims supported by 3+ independent sources → high confidence
- Claims from 2 sources → medium confidence
- Single-source claims → flag for verification or qualify heavily
- Direct contradictions → investigate deeper (may need additional searches)

### Phase 5: Knowledge Gap Analysis

Review all findings and identify:
- Sub-questions with thin or single-source answers
- Areas where only secondary sources were found
- Contradictions that weren't resolved
- Angles that weren't explored

Launch targeted follow-up searches to fill gaps. This is the phase that separates thorough research from surface-level summarization.

### Phase 6: Synthesize (UNION Merge)

For deep mode, use the **UNION merge technique** — instead of synthesizing findings into a single draft yourself, launch 2-3 subagents that each independently write the **complete report** from the collected evidence. Then merge:

1. Launch 2-3 synthesis subagents, each with access to ALL research findings
2. Each writes a complete draft report independently (different agents emphasize different things)
3. Merge using UNION logic: keep all unique findings, consolidate duplicates with the most detailed phrasing
4. Never remove content during merge without explicit justification

This produces richer reports than single-pass synthesis because different agents notice different patterns in the same evidence. The merge step catches anything a single synthesizer would miss.

If UNION merge feels excessive for the topic, fall back to single-agent synthesis (Standard Phase 4 approach with more depth).

### Phase 7: Adversarial Review

Launch a **Contrarian Agent** subagent that attacks the draft:

```
You are a skeptical expert reviewer. Your job is to find weaknesses in this research.

[Insert draft report]

For each major conclusion:
1. What's the strongest counter-argument?
2. What evidence would disprove this?
3. Are there alternative explanations the author didn't consider?
4. Is the source base diverse enough, or does it lean on one type?
5. What would a domain expert find naive or oversimplified?

Be specific. Vague criticism ("needs more research") is useless. Point to exact claims and explain why they're weak.
```

Integrate the contrarian feedback: strengthen weak arguments, add caveats where needed, remove claims that don't survive scrutiny.

### Phase 8: Package

Produce the final report with the [Report Format](#report-format). Include a confidence assessment section.

**Deep mode stopping criteria:**
1. All sub-questions answered with 2+ independent sources
2. Contradictions investigated and resolved or explicitly acknowledged
3. Adversarial review completed and integrated
4. Knowledge gaps identified and either filled or flagged
5. 20+ unique authoritative sources consulted
6. You could defend every major conclusion under expert questioning

---

## Report Format

```markdown
---
id: RESEARCH-YYYY-MM-DD-{topic}
created: YYYY-MM-DD
topic: {research topic}
mode: standard | deep
sources: [{url1}, {url2}, ...]
tags: [relevant, tags]
---

# {Research Topic}

## Executive Summary
3-5 key findings. Lead with the most important or surprising.

## Key Findings

### {Finding 1}
{Analysis with inline source references [1], [2]}

### {Finding 2}
{...}

## Contradictions & Open Questions
{Where sources disagree. What remains uncertain. Why.}

## Confidence Assessment (deep mode only)
| Claim | Confidence | Basis |
|-------|-----------|-------|
| {claim} | High/Medium/Low | {why — source count, quality, agreement} |

## Recommendations
{Specific, actionable items based on findings}

## Sources
1. [{Title}]({URL}) — {type: paper/docs/blog/report}, {quality: 1-5}
2. ...

## Research Metadata
- **Mode:** standard | deep
- **Sources consulted:** {N total, N Tier A, N Tier B, N Tier C}
- **Sub-questions:** {N}
- **Search queries executed:** {N}
- **Pages read in full:** {N}
- **Subagents used:** {N} (deep mode only)
- **Adversarial review:** yes/no
```

Track these counts as you work. The metadata section helps the user understand the depth and cost of each research run, and compare across runs.

---

## Techniques That Make Research Excellent

These aren't phases — they're principles that apply throughout.

**Query craft matters.** Most agents write queries that are too specific, returning few results. Start broad: "electric vehicle market trends" before "EV fleet management SaaS competitive landscape 2025." Use different phrasings for the same concept — synonyms surface different source ecosystems.

**Read the actual page.** Snippets in search results are optimized for clicks, not accuracy. The full page often contains caveats, methodology, and nuance that the snippet hides. Always WebFetch or crawl before citing.

**Chase primary sources.** When a blog post cites a study, find the study. When an article references data, find the data. Secondary sources introduce telephone-game distortion.

**Track what you don't know.** The most valuable research output is often not the answers but the mapped uncertainty — knowing precisely *what* you're uncertain about and *why* lets the user make informed decisions rather than confident-but-wrong ones.

**Avoid the clean narrative trap.** Real topics have messy, contradictory evidence. If your research reads like a Wikipedia article where everything fits together neatly, you've probably smoothed over the most interesting parts. Preserve the mess — that's where insight lives.

---

## Tool Reference

| Tool | Use for | Notes |
|------|---------|-------|
| `mcp__exa__web_search_exa` | Primary search | Best for conceptual/semantic queries |
| `mcp__exa__crawling_exa` | Read specific URLs | Full page content extraction |
| `WebFetch` | Read web pages | Fallback for page reading |
| `WebSearch` | Factual/current searches | Good for recent events, specific facts |
| `Agent` | Parallel subagents (deep mode) | Launch all in single message |

## Output

The report is written to the current working directory or a location specified by the user. If you have a knowledge base or documentation system, offer to save the report there for future reference.
