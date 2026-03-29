---
name: first-principles
description: >
  Multi-pass first principles analysis for any domain — business, personal decisions, creative projects, career, health, relationships. Decomposes problems to fundamental truths, challenges assumptions through 4 universal lenses (Constraints, Resources, Human, Context), and reconstructs solutions from verified ground truths only.
  Use when the user says "first principles", "from first principles", "analyze fundamentals", "challenge assumptions", "decompose problem", "why does this cost so much", "is this the right approach fundamentally", "what are we really solving", "strip away assumptions", "should I really be doing this".
  Also use when the user is stuck on a problem that seems intractable, when conventional approaches have failed, when questioning whether the whole approach is wrong, or when facing a "we've always done it this way" situation — whether in business, life, or creative work.
  Do NOT use for quick factual questions, time-critical decisions, trivial/low-stakes choices, or domains already optimized through rigorous first-principles work. Do NOT use when the user just wants a simple opinion or recommendation without deep analysis.
---

# First Principles Analysis

Decompose any problem to its irreducible truths, challenge every assumption, rebuild solutions from verified fundamentals.

First principles thinking — tracing to Aristotle's concept of *archai* ("the first basis from which a thing is known") — is the practice of breaking a problem into fundamental truths that cannot be deduced from anything else, then reasoning upward from those truths to construct original solutions. It's the opposite of reasoning by analogy ("others do X, so we should do X").

This skill runs a structured multi-pass analysis, not a single-pass template. Each pass examines the problem through a different lens, building a progressively deeper understanding.

## Modes

| Mode | Invoke | Approach | Time |
|------|--------|----------|------|
| **Standard** | `/first-principles` | Single-agent, sequential passes | 3-5 min |
| **Deep** | `/first-principles deep` | Parallel subagents per lens + devil's advocate | 10-15 min |

---

## Standard Mode — 4 Passes

### Pass 1: Decomposition

Strip the problem to its essence. Most problems arrive pre-framed by analogy ("We need a better X" assumes X is the right category).

**Step 1 — Restate the problem without any solution implied.**
Ask: "What outcome does the user actually need?" not "How do we improve the current approach?" If the user says "we need a faster database," the real problem might be "users wait too long for results" — which might not need a database at all.

**Step 2 — Surface every assumption.** List all assumptions the current situation relies on — explicit and implicit:

| Category | What to look for |
|----------|-----------------|
| Industry conventions | "It's always been done this way" |
| Technical constraints | Physics-bound vs. policy-bound vs. habit |
| Economic assumptions | Market prices vs. raw material/fundamental costs |
| User assumptions | "Users want/need/won't pay for X" |
| Organizational habits | Process inertia, cargo cult practices |

Be thorough. The most dangerous assumptions are the ones nobody questions because they feel like facts. A useful probe: "Would someone from a completely different industry find this obvious, or bizarre?"

**Step 3 — Classify each assumption:**

| Type | Test | Action |
|------|------|--------|
| **Hard constraint** | Violating it would break physics, math, or logic | Accept as ground truth |
| **Soft constraint** | Based on policy, convention, regulation, or habit | Challenge — these can change |
| **Unvalidated** | "Everyone knows" but nobody has tested | Test — likely wrong or outdated |

Output an **Assumptions Map** — a table of every assumption with its classification and a one-line challenge.

**Step 4 — Map assumption dependencies.** Some assumptions depend on others. If a root assumption falls, everything built on it collapses. After building the flat table, identify 2-3 dependency chains:

```
Root: "Users want a digital platform"
├── Depends on: "Users research online" (testable)
└── Depends on: "Digital = trustworthy for this audience" (unvalidated)
    └── Depends on: "Our UX meets luxury expectations" (soft)
```

Challenge from the bottom up — root assumptions are the highest-leverage targets.

### Pass 2: Multi-Lens Challenge

This is where the analysis becomes multi-dimensional. Examine the problem through four independent lenses. Each lens has its own set of questions — the goal is to find ground truths that survive scrutiny from all angles.

The lenses below are universal — they work for business, personal, creative, scientific, and life decisions. The framing adapts to the domain.

**Constraints Lens** (physics, biology, time, information, engineering):
- What are the actual hard limits — laws of physics, biology, mathematics, information theory?
- **Calculate the theoretical minimum** — the absolute floor for time, cost, energy, or effort required. Write it down explicitly. The gap between this floor and the current state is the opportunity space. For personal decisions, the "theoretical minimum" might be the minimum time/energy a path requires if everything goes perfectly.
- Which "limitations" are really just current implementation choices, habits, or social conventions?
- Apply **Five Whys** to the most important soft constraint. Show the chain visibly in the output — this often reveals the real root cause is 3-4 levels below the stated problem.

**Resources Lens** (money, time, energy, relationships, attention):
- What is the fundamental cost — in money, time, energy, and relationships?
- Apply **Gap Analysis** — explicitly calculate and show: (1) the fundamental/irreducible cost and (2) the current actual cost. For business: commodity cost vs market price (Musk's battery insight: $80/kWh vs $600/kWh). For personal decisions: minimum time/effort required vs what you're currently spending. For creative work: core skill/tools needed vs accumulated overhead. The ratio is your signal — a large gap means opportunity or waste.
- What are you actually paying for — genuine value, or process inefficiency / convention / fear?
- What would this look like if designed from scratch today with zero legacy, zero sunk cost?

**Human Lens** (needs, psychology, behavior, values):
- What does the person (user, customer, or yourself) fundamentally need at the deepest level? Not the stated want, but the underlying need. (Not "a faster horse" but "get somewhere quickly." Not "a better job" but "feel competent and valued.")
- Apply **Socratic Questioning** — all 6 steps, shown visibly in the output as a numbered sequence. This is the heart of the human lens — don't abbreviate it:
  1. Clarify: Why do I think this is needed? Where did this belief come from?
  2. Challenge: How do I know this is true? What if I'm wrong?
  3. Evidence: What data, experience, or observation supports this?
  4. Alternatives: What would someone from a different culture, era, or life stage think?
  5. Consequences: What happens if this assumption is wrong?
  6. Meta: Am I asking the right questions, or avoiding the hard ones?
- What behavior actually exists vs. what behavior is assumed or hoped for?
- Identify the **actual job-to-be-done** — not the category, but the progress being made. For products: what progress is the user hiring this for? For personal decisions: what life progress am I trying to make? Often reveals that the real alternatives are in a different category entirely.

**Context Lens** (environment, competition, timing, culture, trends):
- What is the broader environment — market, social, cultural, technological, regulatory?
- What would someone with zero legacy, zero emotional attachment, and full information do?
- Apply **Counterfactual Thinking**: "What if the opposite of the current approach were true?" For business: what if competitors' strategy is right and ours is wrong? For personal: what if I stayed instead of leaving (or vice versa)?
- What is the minimum viable version that satisfies all ground truths?
- What timing factors matter — is this reversible or a one-way door?

Not every lens applies equally to every problem. Spend proportional effort — a pure engineering problem needs deep constraints and light context analysis. A life decision may need heavy human and resource lenses. A business problem may need all four equally.

### Pass 3: Ground Truths & Reconstruction

**Identify ground truths** — what survives all four lenses:
- Physical laws and mathematical truths
- Verified empirical data (not projections or opinions)
- Irreducible functional requirements
- Fundamental human needs

Tag each ground truth with a confidence level: **High** (supported by multiple lenses + empirical evidence), **Medium** (supported by 2 lenses or logical reasoning without strong data), **Low** (single-lens or analyst's inference — needs external validation). Low-confidence ground truths are hypotheses worth testing, not facts to build on.

These are the "Lego blocks" — the irreducible pieces that can be reassembled into something new.

**Surface domain blind spots.** Before reconstruction, explicitly state: "What domain knowledge am I lacking that could make these ground truths wrong?" List 2-3 areas where a domain expert should validate the analysis. This is not a weakness — it's intellectual honesty that makes the analysis more trustworthy.

**Reconstruct solutions using three techniques:**

1. **Function over form** — optimize what the solution *does*, ignoring what it currently *looks like*. The rolling suitcase was obvious in hindsight — wheels existed for millennia, but nobody questioned the suitcase's form.

2. **Cross-domain transfer** (Boyd's Snowmobile method) — actively search for analogues in unrelated industries. Ask: "What other fields face the same fundamental constraint?" Then borrow their solution mechanisms. This is the most underused technique and often produces the most surprising solutions. For each reconstructed solution, identify at least one cross-domain analogue and explain what you borrowed. Examples: Airbnb borrowed from eBay (trust via reviews for peer transactions). Netflix borrowed from SaaS (subscription for content). SpaceX borrowed from automotive (vertical integration for rockets).

3. **Theoretical minimum** — calculate the physics/math/logic floor. How close is the current solution to the theoretical minimum? If there's a large gap (SpaceX: 2% materials vs 100% rocket price), that gap is your opportunity space. If the gap is small, first principles thinking may not reveal much — the system is already near-optimal.

Generate 3-5 reconstructed solution paths, each built only from verified ground truths. Rank by:
- Distance from theoretical minimum (closer = more efficient)
- Number of soft constraints eliminated
- Feasibility given current resources
- Potential for non-linear improvement (10x, not 10%)

### Pass 4: Devil's Advocate

Challenge the analysis itself. This pass exists because first principles thinking has a blind spot: you need domain knowledge to identify the right fundamentals, and the analyst's own assumptions can survive undetected.

For each major conclusion, produce a structured challenge with three parts:

1. **Strongest counter-argument** — not a strawman, a genuinely compelling objection. Write it as if you're being paid to argue the other side.
2. **Falsification test** — name a specific, concrete experiment or data point that would disprove this conclusion. "Talk to users" is too vague. "If fewer than 3 of 10 users mention X in unstructured interviews, the conclusion fails" is concrete. Every conclusion should have at least one falsification test.
3. **Verdict** — does the conclusion survive? Strengthen it, add caveats, or demote it.

Also ask globally:
- **What did I assume was a hard constraint that might actually be soft?** And vice versa.
- **Am I confusing "novel" with "correct"?** First principles thinking biases toward contrarian solutions. Sometimes the conventional approach IS the first-principles answer — it's been refined by reality.
- **What would make a domain expert laugh at this analysis?** The paradox: sufficient expertise is required to decompose correctly, but expertise also brings entrenched assumptions.

---

## Deep Mode — Parallel Subagents

For high-stakes problems where being wrong is expensive.

### Phase 1: Decomposition (single agent)

Run Pass 1 as in Standard Mode. This produces the Assumptions Map that all subagents will work from.

### Phase 2: Parallel Lens Analysis

Launch 4 subagents simultaneously, one per lens (Constraints, Resources, Human, Context):

```
You are analyzing a problem from first principles through the [LENS NAME] lens.

Problem: [reframed problem essence from Phase 1]
Assumptions Map: [table from Phase 1]

Your task:
1. Examine each assumption through your lens
2. Identify which assumptions are hard constraints, soft constraints, or unvalidated from your perspective
3. Apply the lens-specific technique (Five Whys / Gap Analysis / Socratic Questioning / Counterfactual)
4. Surface ground truths visible only from this angle, with confidence levels
5. Propose solution components built from your ground truths

Lens-specific questions: [questions from the relevant lens section above]

Output format:
## [Lens Name] Analysis
### Assumptions Reassessed
[table: assumption | your classification | reasoning]
### Ground Truths Discovered
[numbered list with evidence and confidence: High/Medium/Low]
### Solution Components
[what this lens suggests, with cross-domain analogues]
### Blind Spots
[what this lens can't see — flag for other lenses]
```

### Phase 3: Synthesis & Reconstruction

Merge findings from all 4 lenses:
- Ground truths that appear in 3+ lenses -> high confidence
- Ground truths from 2 lenses -> medium confidence
- Single-lens ground truths -> flag for verification
- Contradictions between lenses -> investigate (this is where insight lives)

Reconstruct solutions using the merged ground truth set.

### Phase 4: Devil's Advocate (separate subagent)

Launch a dedicated contrarian subagent:

```
You are a skeptical expert. Your job is to find weaknesses in this first principles analysis.

[Insert full analysis so far]

For each major conclusion:
1. What's the strongest counter-argument?
2. What evidence would disprove this?
3. What assumptions survived unquestioned?
4. Is there a simpler explanation the analysts missed?
5. Where is the analysis confusing "novel" with "correct"?

Be specific — point to exact claims and explain why they're weak.
```

Integrate the contrarian feedback into the final report.

---

## Output Format

Write the final report as a structured markdown document:

```markdown
# First Principles Analysis: {Topic}

## Problem Essence
{The real problem, stripped of inherited framing}

## Assumptions Map

| # | Assumption | Type | Status | Challenge |
|---|-----------|------|--------|-----------|
| 1 | {assumption} | Hard/Soft/Unvalidated | Confirmed/Challenged/Eliminated | {one-line reasoning} |

## Ground Truths

| # | Ground Truth | Confidence | Basis |
|---|-------------|-----------|-------|
| 1 | {truth} | High/Medium/Low | {which lenses support it, what evidence} |

### Domain Blind Spots
{2-3 areas where domain expertise is lacking — what a specialist should verify}

## Multi-Lens Analysis

### Constraints
{Hard limits, theoretical minimum, Five Whys chain}

### Resources
{Fundamental costs, gap analysis, value vs. waste}

### Human
{Deep needs, Socratic Questioning sequence, job-to-be-done}

### Context
{Environment, counterfactual, timing, minimum viable version}

## Reconstructed Solutions

### Solution 1: {name}
- **Built from:** Ground truths #{numbers}
- **Eliminates:** Assumptions #{numbers}
- **Cross-domain analogue:** {what industry/product solved a similar fundamental problem, and what you borrowed}
- **Distance from theoretical minimum:** {assessment}
- **Feasibility:** {high/medium/low}
- **Potential:** {incremental/step-change/transformative}

### Solution 2: ...

## Devil's Advocate

### Challenge 1: {conclusion being challenged}
- **Counter-argument:** {strongest opposing case}
- **Falsification test:** {specific experiment or data point that would disprove this}
- **Verdict:** {survives/weakened/demoted}

### Challenge 2: ...

## Recommendations
{Prioritized, actionable next steps — what to do, not just what to think}

1. **{Action}** — {why, based on which ground truths}. *Reverse if:* {what data or outcome would invalidate this recommendation}
2. ...
```

## When NOT to Use This Skill

First principles thinking is expensive — it requires deep analysis and produces its value through thoroughness. It's the wrong tool when:

- **Time-critical**: You need an answer in minutes, not hours
- **Low stakes**: The cost of being wrong is trivial
- **Well-optimized domain**: The space has been heavily analyzed by rigorous thinkers (e.g., basic thermodynamics, established algorithms)
- **Insufficient domain knowledge**: Without enough context, you'll identify wrong fundamentals — garbage in, garbage out
- **Simple optimization needed**: If the current approach is sound and just needs tuning, reasoning by analogy or incremental improvement is faster and sufficient

If you're unsure whether first principles analysis is appropriate for a given problem, a quick heuristic: **Is there a large unexplained gap between the theoretical minimum and the current state?** If yes, first principles thinking will be valuable. If the gap is small or well-understood, conventional approaches are probably fine.

## References

- See `references/techniques.md` for detailed breakdowns of Socratic Questioning, Five Whys, and Counterfactual Thinking with worked examples
