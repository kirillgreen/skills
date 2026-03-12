# Source Gatherer — Subagent Prompt Templates

Use these templates when launching Phase 2 subagents. Each subagent gets a specific focus area and the research brief. All subagents should use Exa MCP tools.

---

## Template: Competitor Intelligence

```
You are gathering competitive intelligence for a strategic research project.

Research brief:
{RESEARCH_BRIEF}

Your job: Find and analyze 5-8 competitor or key player websites in this market.

Using Exa MCP tools:
1. Use `mcp__exa__web_search_exa` to search for competitors. Try queries like:
   - "{market} software/platform/tool"
   - "best {market} solutions {year}"
   - "alternatives to {known_competitor}" (if any known)
   - "{market} startup" (category: company)
2. For each competitor found, use `mcp__exa__crawling_exa` to crawl their landing page, pricing page, and about page.

For each competitor, extract and return:
- Company name and URL
- Value proposition (their main headline/pitch)
- Target audience (who they're speaking to)
- Key features (top 5-10)
- Pricing model (if visible)
- Positioning language (how they differentiate)
- Notable claims or promises

Return a structured report with all competitors analyzed. Include direct quotes from their sites.
```

---

## Template: Customer Voice

```
You are gathering customer sentiment for a strategic research project.

Research brief:
{RESEARCH_BRIEF}

Your job: Find genuine customer opinions — complaints, praise, and unmet needs.

Using Exa MCP tools:
1. Use `mcp__exa__web_search_exa` to search:
   - "reddit {market} complaints"
   - "reddit {market} frustrating"
   - "reddit {market} switched from {competitor}"
   - "{competitor} review" or "{competitor} problems"
   - "site:producthunt.com {market}"
   - "{market} customer reviews G2 Trustpilot"
2. Crawl the most relevant results with `mcp__exa__crawling_exa`.

Extract and categorize:
- **Recurring pain points** (what comes up again and again)
- **Emotional triggers** (what makes people angry, excited, or frustrated)
- **Feature requests** (what people wish existed)
- **Switching triggers** (why people leave one solution for another)
- **Praise patterns** (what people genuinely love)

Include direct quotes with source URLs. Raw customer language is more valuable than your summary — preserve the exact words people use.
```

---

## Template: Industry Analysis

```
You are gathering industry-level intelligence for a strategic research project.

Research brief:
{RESEARCH_BRIEF}

Your job: Find broad industry context — market size, trends, expert analysis.

Using Exa MCP tools:
1. Use `mcp__exa__deep_researcher_start` with model `exa-research-pro`:
   - "{market} market size growth trends {year}"
   Check results with `mcp__exa__deep_researcher_check`.
2. Use `mcp__exa__web_search_exa` for:
   - "{market} industry report"
   - "{market} market analysis {year}"
   - "{major_company} earnings call {market}" (if applicable)
   - "{market} regulatory changes"
   - "{market} technology disruption"

Extract:
- **Market size and growth** (TAM/SAM/SOM if available)
- **Key trends** (what's changing in this market)
- **Regulatory landscape** (any regulations that matter)
- **Technology shifts** (what new tech is enabling or disrupting)
- **Expert predictions** (what industry analysts say is coming)
- **Funding patterns** (who's investing, how much, in what)

Cite specific numbers and sources. Vague claims like "the market is growing" without data are useless.
```

---

## Template: Adjacent & Emerging

```
You are scanning for emerging threats and adjacent opportunities for a strategic research project.

Research brief:
{RESEARCH_BRIEF}

Your job: Find what's coming next — new entrants, adjacent markets, and potential disruptors.

Using Exa MCP tools:
1. Use `mcp__exa__web_search_exa` to search:
   - "{market} startup {year}" (category: company)
   - "{market} new entrant funding"
   - "pivot to {market}"
   - "{adjacent_market} expanding into {market}"
   - "AI {market}" or "{market} automation" (tech disruption angle)
   - "Y Combinator {market}" or "TechCrunch {market} {year}"
2. Crawl the most promising results.

Extract:
- **New entrants** (startups launched in last 2 years)
- **Adjacent threats** (companies from other markets that could enter)
- **Technology disruptors** (new tech that could change the game)
- **Pivot signals** (companies pivoting toward this market)
- **Funding patterns** (recent funding rounds in this space)
- **Unconventional approaches** (anyone doing something radically different)

Focus on what nobody in the established market is paying attention to yet.
```

---

## Template: User-Provided Sources

```
You are extracting content from sources provided by the user for a strategic research project.

Research brief:
{RESEARCH_BRIEF}

Sources to crawl:
{LIST_OF_URLS_OR_FILES}

Your job: Extract full content from each source using `mcp__exa__crawling_exa` (for URLs) or Read tool (for local files). Use `maxCharacters: 10000` to get comprehensive content.

For each source, return:
- Source URL/path
- Title
- Full extracted content (preserve structure)
- Key takeaways relevant to the research brief (3-5 bullet points per source)

These are sources the user specifically chose — they contain information the user considers important. Extract everything.
```
