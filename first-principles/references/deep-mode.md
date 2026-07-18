# Deep Mode — Subagent Briefs & Record Format

Read this before launching Phase 2 agents. It prevents the two failure modes that quietly ruin deep mode: thin briefs (subagents share none of your context, so anything not in the prompt does not exist for them) and unmergeable output (free-prose ground truths from 4 agents can't be matched in Phase 3).

## Phase 2: Lens Agent Prompt Template

Fill every bracketed section. If the brief feels long, that's correct — a fat brief costs tokens; a thin one costs the analysis.

```
You are analyzing a problem from first principles through the [LENS NAME] lens.

## Problem
[Full problem statement WITH background: who is asking, what project or situation,
what prompted the question. Not the one-line essence — the full picture.]

## Evidence Base
[The complete Evidence Base from Pass 0, with source tags
[verified] / [user-stated] / [model-knowledge]. Include the actual numbers and sources.]

## Assumptions Map
[The full table from Phase 1, including dependency chains.]

## Additional context
[Relevant file excerpts, data, prior research findings, the user's answers to intake
questions, constraints the user stated. When in doubt, include it.]

## Your task
1. Examine each assumption through your lens
2. Reclassify from your perspective: hard constraint, soft constraint, or unvalidated
3. Apply the lens-specific technique (Five Whys / Gap Analysis / Socratic Questioning / Counterfactual)
4. Surface ground truths visible only from this angle — as structured records (format below)
5. Propose solution components built from your ground truths

Rules:
- Confidence comes from evidence, not conviction: High needs [verified] backing;
  Medium is a sound derivation or [user-stated]; Low is inference or [model-knowledge]
- Do not invent numbers. A claim you can't source gets tagged [unverified], not a plausible figure
- A lens that has nothing to say about an assumption says so in one line and moves on

## Lens-specific questions
[Paste the questions from the relevant lens section of SKILL.md Pass 2]

## Output format
### Assumptions Reassessed
[table: assumption # | your classification | reasoning]
### Ground Truth Records
[one record per truth, format below]
### Solution Components
[what this lens suggests, with cross-domain analogues]
### Blind Spots
[what this lens can't see — flag for other lenses]
```

## Ground-Truth Record Format

Each ground truth returns as a structured record:

```
GT-[lens]-[n]:
  statement: <one falsifiable sentence>
  evidence: <the specific fact, source, or derivation backing it>
  evidence_tag: verified | user-stated | model-knowledge | unverified | derived
  confidence: High | Medium | Low
  assumptions: [#s from the Assumptions Map this truth confirms, weakens, or eliminates]
```

`derived` marks a logical derivation from other ground truths — name them in `evidence`. Under the Pass 3 confidence map, a derivation is at most Medium and never stronger than its weakest input; `unverified` caps at Low.

## Phase 3: Merge Procedure

1. Group records by the assumption numbers they reference — records touching the same assumptions are merge candidates.
2. Within a group, merge records whose statements say the same thing; keep the strongest evidence and the union of assumption refs.
3. Set merged confidence from the best evidence tag present — NOT from how many lenses found it. Four framings of one model agreeing is coherence, not corroboration.
4. A single-lens truth with `verified` evidence outranks a four-lens truth resting on `model-knowledge`.
5. Records that contradict each other → investigate before reconstruction. The contradiction usually marks either a framing error in the brief or the most interesting insight in the analysis.
