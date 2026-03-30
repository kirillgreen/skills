# Deep Mode — Detailed Subagent Instructions

## Subagent Architecture

Deep mode uses an orchestrator-worker pattern. You (the orchestrator) coordinate while subagents do the actual searching and reading. This matters because:

1. **Parallel execution** cuts wall-clock time by 80-90% without additional token cost
2. **Divided responsibilities** prevent the duplication that happens when one agent tries to cover everything
3. **Independent search paths** increase source diversity — different agents find different things

## How to Design Subagent Assignments

Bad assignment (too vague):
> "Research the semiconductor industry"

Good assignment (specific scope, clear output):
> "Investigate the current state of EUV lithography supply chain. Focus on: (1) ASML's market position and delivery timelines, (2) alternative lithography approaches being developed, (3) geopolitical factors affecting supply. Search for industry reports, ASML investor communications, and expert analysis. Output: structured findings with sources and confidence levels."

Each subagent needs:
- **Objective**: What specific questions to answer
- **Scope boundaries**: What NOT to investigate (prevents overlap)
- **Tool guidance**: Which search tools to use, what kinds of sources to prefer
- **Output format**: Structured findings, not prose (easier to synthesize later)
- **Context**: What other subagents are covering (so they don't duplicate)

## Recommended Subagent Configuration

### For 8-12 sub-questions (typical deep research):

| Subagent | Role | Sub-questions | Focus |
|----------|------|---------------|-------|
| Research-1 | Domain fundamentals | 2-3 | Core concepts, current state, key players |
| Research-2 | Technical depth | 2-3 | How things work, trade-offs, implementation details |
| Research-3 | Trends & future | 2-3 | Where things are heading, emerging approaches |
| Research-4 | Contrarian & edge cases | 2-3 | What could go wrong, minority viewpoints, failure modes |
| Gap-Filler | Knowledge gaps | Dynamic | Fills gaps found after initial research completes |
| Contrarian | Adversarial review | N/A | Attacks the draft (Phase 7) |

### Subagent Launch Template

Launch ALL research subagents in a **single Agent tool call block**. This is critical for parallelism.

```
Agent(name="research-1", prompt="""
You are a research subagent. Your assignment:

## Research Brief
{paste the research brief from Phase 1}

## Your Sub-Questions
1. {sub-question A}
2. {sub-question B}
3. {sub-question C}

## What Other Subagents Are Covering
- Research-2: {their topics}
- Research-3: {their topics}
Do NOT duplicate their work.

## Instructions

### Search Strategy
1. For each sub-question, generate 2-3 search queries with different phrasings
2. Use mcp__exa__web_search_exa for conceptual queries
3. Use WebSearch for factual/recent information
4. Start broad, then narrow based on what you find

### Reading Strategy
- Read full pages with WebFetch (not just snippets)
- Read at least 3 pages per sub-question
- Prefer: academic papers, official documentation, practitioner blogs, industry reports
- Avoid: SEO content farms, undated listicles, anonymous opinion pieces

### Source Scoring
For each source, assign a quality score:
5 = Primary research, data, or official documentation
4 = Expert analysis with citations
3 = Quality journalism or well-sourced blog
2 = General commentary, secondary reporting
1 = SEO content, unsourced claims, promotional material

### Output Format
Save your findings to the specified path. Use this structure:

## Sub-Question 1: {question}
### Answer
{Your synthesis}
### Evidence
- {Claim}: {evidence} [Source: {url}, Quality: {score}]
### Confidence: High/Medium/Low
### Reasoning: {why this confidence level}

## Sub-Question 2: {question}
{same structure}

## Contradictions & Surprises
{List anything unexpected or conflicting between sources}

## Gaps
{What you couldn't find good answers for}

## Source Index
| # | URL | Title | Type | Quality |
{table of all sources consulted}
""")
```

## Knowledge Gap Agent

After initial research subagents complete, launch the Gap-Filler:

```
You are a Knowledge Gap Agent. You review research findings and identify what's missing.

## All Findings So Far
{paste or reference all subagent outputs}

## Original Research Brief
{the brief}

## Your Job
1. Read all findings carefully
2. Identify:
   - Sub-questions with only 1 source (need corroboration)
   - Claims that contradict each other (need resolution)
   - Angles nobody explored (blind spots)
   - Areas where only low-quality sources were found
3. For each gap, run targeted searches to fill it
4. Output your additional findings in the same format as the research subagents

Focus on the MOST IMPORTANT gaps — the ones that would change the report's conclusions if filled differently.
```

## Adversarial Review Agent (Phase 7)

The contrarian agent is the most underappreciated phase. Its job is NOT to be negative — it's to find where the research is thin, biased, or overconfident.

```
You are a Skeptical Expert Reviewer with deep domain knowledge.

## Draft Report
{the synthesized draft}

## Source List
{all sources used}

## Your Review Protocol

For each major conclusion in the report:

### 1. Steel-Man Test
First, state the conclusion in its strongest possible form. Does the evidence actually support this strong version, or only a weaker one?

### 2. Counter-Evidence Search
Search for evidence that CONTRADICTS this conclusion. Use mcp__exa__web_search_exa with queries designed to find the opposite viewpoint. If you can't find counter-evidence, that's useful information too.

### 3. Source Diversity Check
Are the sources for this conclusion truly independent? Or do they all trace back to the same original source/dataset/author? Count the actually-independent evidence chains.

### 4. Alternative Explanations
What other explanations fit the same evidence? List at least one alternative for each major claim.

### 5. Confidence Calibration
Based on your review, what confidence level does this conclusion actually deserve?
- High: 3+ independent high-quality sources, no credible counter-evidence
- Medium: 2+ sources, some counter-evidence or limitations
- Low: sparse evidence, significant counter-arguments, or source quality concerns

## Output Format
For each reviewed conclusion:
- Original claim
- Strength of evidence (strong/moderate/weak)
- Best counter-argument found
- Alternative explanations
- Recommended confidence level
- Suggested revision (if needed)

## Meta-Review
After reviewing individual conclusions:
- What's the biggest blind spot in this research?
- What question should have been asked but wasn't?
- If you were the user making a decision based on this, what would worry you?
```

## Synthesis After Subagents Return

When combining subagent findings:

1. **De-duplicate**: Multiple subagents may have found the same source. Merge, don't repeat.
2. **Resolve conflicts**: When subagents disagree, trace back to their sources. Which sources are stronger?
3. **Elevate surprises**: If a subagent flagged something unexpected, that's often the most valuable finding.
4. **Preserve uncertainty**: Don't collapse "medium confidence" findings into definitive statements just because it reads better.
5. **Source diversity**: The final source list should span multiple types (academic, industry, practitioner, official docs). If it's all one type, the research has a systematic blind spot.

## Token Budget Guidelines

Deep mode is expensive by design — that's the trade-off for thoroughness.

| Component | Estimated tokens |
|-----------|-----------------|
| Orchestrator (you) | 30-50K |
| Each research subagent (4-5) | 20-40K each |
| Knowledge gap agent | 15-30K |
| Contrarian agent | 15-25K |
| **Total** | **150-300K** |

If the user hasn't explicitly requested deep mode, use standard. Deep mode should feel like hiring a team of researchers, not running a search query.
