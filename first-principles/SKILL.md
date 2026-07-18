---
name: first-principles
description: >
  Multi-pass first principles analysis for any domain — business, personal decisions, creative projects, career, health, relationships. Grounds the analysis in real evidence first, decomposes problems to fundamental truths, challenges assumptions through 4 universal lenses (Constraints, Resources, Human, Context), and reconstructs solutions from evidence-backed ground truths. Three depths: lite (quick inline sanity-check), standard, and deep (parallel subagents per lens).
  Use when the user says "first principles", "from first principles", "analyze fundamentals", "challenge assumptions", "decompose problem", "why does this cost so much", "is this the right approach fundamentally", "what are we really solving", "strip away assumptions", "should I really be doing this".
  Also use when the user is stuck on a problem that seems intractable, when conventional approaches have failed, when questioning whether the whole approach is wrong, or when facing a "we've always done it this way" situation — whether in business, life, or creative work.
  Do NOT use for quick factual questions, time-critical decisions, trivial/low-stakes choices, or domains already optimized through rigorous first-principles work. Do NOT use when the user just wants a simple opinion or recommendation without deep analysis.
---

# First Principles Analysis

Decompose any problem to its irreducible truths, challenge every assumption, rebuild solutions from verified fundamentals.

First principles thinking — tracing to Aristotle's concept of *archai* ("the first basis from which a thing is known") — is the practice of breaking a problem into fundamental truths that cannot be deduced from anything else, then reasoning upward from those truths to construct original solutions. It's the opposite of reasoning by analogy ("others do X, so we should do X").

This skill runs a structured multi-pass analysis, not a single-pass template. Each pass examines the problem through a different lens, building a progressively deeper understanding.

## Modes

| Mode | Invoke | Approach | Cost |
|------|--------|----------|------|
| **Lite** | `/first-principles lite` | Assumptions map + top-3 challenges + one reconstruction, inline | No subagents, no file save |
| **Standard** | `/first-principles` | Sequential passes; devil's advocate as subagent | 1 subagent |
| **Deep** | `/first-principles deep` | Parallel subagents per lens + contrarian subagent | 5 subagents |

Every mode starts with evidence intake (Pass 0). The depth of the intake scales with the mode, but no mode skips it — an analysis with no evidence base is a well-formatted guess.

---

## Standard Mode — Passes 0-4

### Pass 0: Evidence Intake

First principles analysis run on an empty evidence base produces confident fiction: the model challenges assumptions using its own assumptions, and invents the numbers the gap analysis depends on. Musk's battery insight ($80/kWh commodity floor vs $600/kWh market price) started with real commodity prices, not introspection. Before decomposing, gather the facts the analysis will stand on.

**1. Prior knowledge.** Search whatever prior-knowledge stores exist in your environment — project docs, a knowledge base, earlier research notes. If the problem concerns a project, read its core documentation. Prior research is priors, not gospel — but starting blind wastes work already done.

**2. External facts.** Identify the 3-5 load-bearing factual claims the analysis will rest on — costs, prices, market sizes, timings, physical limits — and fetch real numbers with sources using the web tools available (WebSearch/WebFetch or equivalent). A claim that can't be verified in reasonable time stays in the analysis but gets tagged `[unverified]`, so it can't silently harden into a High-confidence ground truth.

**3. User-held facts.** For personal, career, and life decisions, most of the evidence lives with the user. Ask 2-4 targeted questions (AskUserQuestion) before analyzing — "why do I believe this?" is the user's question to answer, and self-answering it produces a well-structured guess. When the user can't be asked (headless or subagent run), list the questions you would have asked and tag every conclusion that depends on the missing answers as Low confidence.

**Output: Evidence Base** — the facts the analysis builds on, each tagged by source type:

| Tag | Meaning |
|-----|---------|
| `[verified]` | Fetched this session with a source, or hard math/physics |
| `[user-stated]` | Provided by the user |
| `[model-knowledge]` | A general fact recalled from training data — plausible but not checked |
| `[unverified]` | A specific claim you tried to source this session and couldn't — caps at Low confidence |

Confidence levels in Pass 3 are computed from these tags. Evidence quality propagates upward; lens agreement does not.

Scale the intake to the problem: a strategic business analysis deserves real market numbers; a personal decision deserves real user answers; neither deserves invented figures.

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
- **Calculate the theoretical minimum where the problem has a computable floor** — the absolute floor for time, cost, energy, or effort, built from the real numbers gathered in Pass 0, never invented (a fabricated floor poisons every conclusion stacked on it). The gap between this floor and the current state is the opportunity space. For personal decisions, the floor might be the minimum time/energy a path requires if everything goes perfectly. If the problem has no meaningful floor, say so in one line and move on.
- Which "limitations" are really just current implementation choices, habits, or social conventions?
- Apply **Five Whys** to the most important soft constraint — the real root cause is often 3-4 levels below the stated problem. Show the chain in the output when it lands somewhere non-obvious; if it merely restates the problem, compress it to its conclusion.

**Resources Lens** (money, time, energy, relationships, attention):
- What is the fundamental cost — in money, time, energy, and relationships?
- Apply **Gap Analysis** — explicitly calculate and show: (1) the fundamental/irreducible cost and (2) the current actual cost, using the Pass 0 numbers. For business: commodity cost vs market price (Musk's battery insight: $80/kWh vs $600/kWh — real commodity prices, not estimates). For personal decisions: minimum time/effort required vs what you're currently spending. For creative work: core skill/tools needed vs accumulated overhead. The ratio is your signal — a large gap means opportunity or waste. Where no real numbers exist, present the gap qualitatively and tag it `[unverified]` rather than inventing figures.
- What are you actually paying for — genuine value, or process inefficiency / convention / fear?
- What would this look like if designed from scratch today with zero legacy, zero sunk cost?

**Human Lens** (needs, psychology, behavior, values):
- What does the person (user, customer, or yourself) fundamentally need at the deepest level? Not the stated want, but the underlying need. (Not "a faster horse" but "get somewhere quickly." Not "a better job" but "feel competent and valued.")
- Apply **Socratic Questioning** — all 6 steps; this is the heart of the human lens. Work through every step, but show in the output only the steps that changed your understanding, compressing the rest to a line each — a fully transcribed sequence that surfaces nothing is ritual, not analysis. For personal decisions, steps 1-3 are questions for the user (Pass 0), not for the model to self-answer:
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

Not every lens applies equally to every problem. Spend proportional effort — a pure engineering problem needs deep constraints and light context analysis. A life decision may need heavy human and resource lenses. A business problem may need all four equally. The deliverable is insight, not completed templates: a lens that yields nothing for this problem gets one line saying so, and fabricated quantification is worse than honest absence.

After the lens challenge, update each assumption's Status in the Assumptions Map — Confirmed / Challenged / Eliminated. The Status column in the Output Format is this pass's result.

### Pass 3: Ground Truths & Reconstruction

**Identify ground truths** — what survives all four lenses:
- Physical laws and mathematical truths
- Verified empirical data (not projections or opinions)
- Irreducible functional requirements
- Fundamental human needs

Tag each ground truth with a confidence level derived from its evidence, not from how many lenses endorse it — the four lenses are one analyst in four framings, so cross-lens agreement measures coherence, not truth:

- **High** — backed by `[verified]` evidence from the Evidence Base (a fetched source, hard math/physics)
- **Medium** — a sound logical derivation from High truths, or `[user-stated]` facts taken at face value
- **Low** — `[model-knowledge]`, `[unverified]`, or analyst inference without external support

Low-confidence ground truths are hypotheses worth testing, not facts to build on. If a Low-confidence truth turns out to be load-bearing for a reconstruction, go back and verify it — a quick search now is cheaper than a wrong reconstruction later — or carry it forward explicitly labeled as an assumption.

These are the "Lego blocks" — the irreducible pieces that can be reassembled into something new.

**Surface domain blind spots.** Before reconstruction, explicitly state: "What domain knowledge am I lacking that could make these ground truths wrong?" List 2-3 areas where a domain expert should validate the analysis. This is not a weakness — it's intellectual honesty that makes the analysis more trustworthy.

**Reconstruct solutions using three techniques:**

1. **Function over form** — optimize what the solution *does*, ignoring what it currently *looks like*. The rolling suitcase was obvious in hindsight — wheels existed for millennia, but nobody questioned the suitcase's form.

2. **Cross-domain transfer** (Boyd's Snowmobile method) — actively search for analogues in unrelated industries. Ask: "What other fields face the same fundamental constraint?" Then borrow their solution mechanisms. This is the most underused technique and often produces the most surprising solutions. For each reconstructed solution, identify at least one cross-domain analogue and explain what you borrowed. Examples: Airbnb borrowed from eBay (trust via reviews for peer transactions). Netflix borrowed from SaaS (subscription for content). SpaceX borrowed from automotive (vertical integration for rockets).

3. **Theoretical minimum** — calculate the physics/math/logic floor. How close is the current solution to the theoretical minimum? If there's a large gap (SpaceX: 2% materials vs 100% rocket price), that gap is your opportunity space. If the gap is small, first principles thinking may not reveal much — the system is already near-optimal.

Generate 3-5 reconstructed solution paths, each built from verified ground truths (plus any Low-confidence truths explicitly carried forward as labeled assumptions, per above). Rank by:
- Distance from theoretical minimum (closer = more efficient)
- Number of soft constraints eliminated
- Feasibility given current resources
- Potential for non-linear improvement (10x, not 10%)

### Pass 4: Devil's Advocate

Challenge the analysis itself. This pass exists because first principles thinking has a blind spot: you need domain knowledge to identify the right fundamentals, and the analyst's own assumptions can survive undetected.

**Run this pass as a fresh subagent, not as in-context self-critique.** The analyst who just built the analysis reviews it while sitting on all of its own anchors — same-context self-critique predictably produces soft challenges and "survives" verdicts. A context-isolated contrarian costs one agent call and is the cheapest real decorrelation available. Send it the full draft report plus the Evidence Base, using the contrarian prompt from Deep Mode Phase 4. Fall back to in-context self-critique only when subagents are unavailable, and note the fallback in the report ("devil's advocate ran in-context — treat its blessing skeptically").

For each major conclusion, the contrarian produces a structured challenge with three parts:

1. **Strongest counter-argument** — not a strawman, a genuinely compelling objection. Write it as if you're being paid to argue the other side.
2. **Falsification test** — name a specific, concrete experiment or data point that would disprove this conclusion. "Talk to users" is too vague. "If fewer than 3 of 10 users mention X in unstructured interviews, the conclusion fails" is concrete. Every conclusion should have at least one falsification test. If the test is executable right now — a web search, a number sitting in the codebase or analytics, a document check — run it and report the result instead of just naming it. Defer only tests that genuinely need time, money, or other people; those become first steps in Recommendations.
3. **Verdict** — `survives`, `weakened` (survives with caveats), or `demoted`.

Also ask globally:
- **What did I assume was a hard constraint that might actually be soft?** And vice versa.
- **Am I confusing "novel" with "correct"?** First principles thinking biases toward contrarian solutions. Sometimes the conventional approach IS the first-principles answer — it's been refined by reality.
- **What would make a domain expert laugh at this analysis?** The paradox: sufficient expertise is required to decompose correctly, but expertise also brings entrenched assumptions.

---

## Lite Mode — Quick Sanity Check

For conversational use — "is this approach fundamentally sound?" — where a full report would be ceremony. Lite is a compression of the standard passes, not a different method:

1. **Minimal evidence intake** — check existing prior research; for personal decisions ask the user the 2-3 questions that matter. Skip web research unless one number is clearly load-bearing.
2. **Assumptions Map** (Pass 1, in full — this is the highest-value artifact per token).
3. **Challenge the top 3 assumptions only**, picked by dependency depth — roots first, not the easiest targets. Use whichever lens fits each assumption; skip the rest.
4. **One reconstruction** built from what survived.
5. **Five-line devil's advocate, in-context** — lite is the exception to the subagent rule; the point is speed.

Output inline in the conversation: the assumptions table, the 3 challenges, one reconstruction, caveats. No file save unless asked. If the lite pass hits something big — a root assumption that doesn't survive — say so and offer standard or deep mode.

---

## Deep Mode — Parallel Subagents

For high-stakes problems where being wrong is expensive.

### Phase 1: Evidence & Decomposition (single agent)

Run Pass 0 and Pass 1 as in Standard Mode. This produces the Evidence Base and Assumptions Map that all subagents will work from.

### Phase 2: Parallel Lens Analysis

Launch 4 subagents simultaneously, one per lens (Constraints, Resources, Human, Context). Invoking deep mode is the user's explicit confirmation for this 4-agent fan-out.

**Feed each subagent a full brief.** Subagents share none of your context — no conversation history, no files you've read, no Evidence Base. A lens agent briefed with only "problem + assumptions table" returns parallel banalities. Every lens prompt must carry: the full problem statement with background, the complete Evidence Base (with source tags), the Assumptions Map, relevant file excerpts or data, the user's stated constraints and answers, and the lens-specific questions from Standard Mode Pass 2. When in doubt, include it — a fat brief costs tokens; a thin one costs the analysis.

**Require structured records.** Each ground truth comes back as a structured record (statement, evidence, evidence tag, confidence, related assumption numbers) so Phase 3 can match findings across lenses mechanically instead of eyeballing paraphrases.

Full prompt template and the ground-truth record format: `references/deep-mode.md` — read it before launching the agents.

### Phase 3: Synthesis & Reconstruction

Merge findings from all 4 lenses (full merge procedure in `references/deep-mode.md`):
- Match ground truths across lenses by their related assumption numbers and statement meaning — the structured records make this mechanical rather than vibes
- Confidence comes from evidence tags, exactly as in Standard Pass 3 — cross-lens agreement raises coherence, not confidence; four framings of one model agreeing is not four independent sources
- A ground truth found by only one lens is not weaker for it — judge its evidence, not its popularity
- Contradictions between lenses → investigate (this is where insight lives)

Reconstruct solutions using the merged ground truth set.

### Phase 4: Devil's Advocate (separate subagent)

Launch a dedicated contrarian subagent (this same prompt serves Standard Mode Pass 4):

```
You are a skeptical expert reviewing a first principles analysis. Your job is to find what's wrong with it, not to bless it.

[Insert the full analysis draft AND the Evidence Base with source tags]

For each major conclusion:
1. What's the strongest counter-argument? Not a strawman — argue it as if paid to win.
2. What specific, concrete evidence would disprove this? Name a falsification test with a measurable threshold. If the test is executable right now (a web search, a data lookup), RUN it and report the result.
3. What assumptions survived unquestioned?
4. Is there a simpler explanation the analysts missed?
5. Where is the analysis confusing "novel" with "correct"?

Also check: does every High-confidence ground truth actually have [verified] evidence behind it? Flag any that don't.

Return a verdict per conclusion: survives / weakened / demoted, with reasoning. An analysis where everything "survives" untouched is a rubber stamp — if that's genuinely the case, prove it by pointing at the evidence that withstood your strongest attacks.
```

Integrate the contrarian feedback into the final report.

---

## Output Format

Write the final report as a structured markdown document:

```markdown
# First Principles Analysis: {Topic}

## Problem Essence
{The real problem, stripped of inherited framing}

## Evidence Base

| # | Fact | Source | Tag |
|---|------|--------|-----|
| E1 | {fact} | {URL / KB entry / user / training data} | [verified] / [user-stated] / [model-knowledge] / [unverified] |

## Assumptions Map

| # | Assumption | Type | Status | Challenge |
|---|-----------|------|--------|-----------|
| 1 | {assumption} | Hard/Soft/Unvalidated | Confirmed/Challenged/Eliminated | {one-line reasoning} |

## Ground Truths

| # | Ground Truth | Confidence | Basis |
|---|-------------|-----------|-------|
| 1 | {truth} | High/Medium/Low | {E# refs from the Evidence Base or the derivation — evidence, not lens count} |

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
- **Test result:** {what it showed if run this session; otherwise "deferred → Recommendations"}
- **Verdict:** {survives/weakened/demoted}

### Challenge 2: ...

### Global checks
- **Assumptions that survived unquestioned:** {what the contrarian found untouched}
- **Hard ↔ soft reclassifications:** {constraints the analysis put in the wrong tier}
- **Simpler explanation:** {a simpler account the analysis missed, if any}
- **Novel vs. correct:** {where the analysis confuses contrarian with true}

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
- See `references/deep-mode.md` for the deep-mode subagent brief template, ground-truth record format, and merge procedure
