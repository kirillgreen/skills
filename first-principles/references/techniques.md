# First Principles Techniques — Detailed Reference

## Socratic Questioning (6 Steps)

A disciplined questioning process that separates knowledge from assumption. Each step builds on the previous — don't skip ahead.

### The 6 Steps

1. **Clarify thinking** — "Why do I think this? What exactly do I believe? Where did this idea originate?"
2. **Challenge assumptions** — "How do I know this is true? What if the opposite were true?"
3. **Seek evidence** — "What data supports this? What's the quality of that evidence? Could I be cherry-picking?"
4. **Consider alternatives** — "What might someone from a different field/culture/era think? What perspectives am I missing?"
5. **Examine consequences** — "What follows if I'm right? What follows if I'm wrong? What are the second-order effects?"
6. **Question the questions** — "Was my questioning process sound? Did I avoid the hard questions? What did I not think to ask?"

### Worked Example: "We need to hire more engineers"

| Step | Question | Answer |
|------|----------|--------|
| Clarify | Why do I think we need more engineers? | Because features are shipping slowly |
| Challenge | Is headcount the only way to ship faster? | No — could be process, scope, tech debt, wrong priorities |
| Evidence | What data shows headcount = speed? | Actually, Brooks's Law says the opposite for late projects |
| Alternatives | How do small teams ship fast? (37signals, early Instagram) | Radical scope reduction, fewer features done better |
| Consequences | If we hire 5 engineers, what happens in 6 months? | 2 months onboarding, 2 months ramp, net -4 engineer-months short term |
| Meta | Am I asking the right question? | The real question is "why are features slow?" not "how to add capacity?" |

**Ground truth discovered:** The bottleneck is decision speed and scope, not engineering capacity.

---

## Five Whys

Developed by Sakichi Toyoda (Toyota). Drill from symptom to root cause through successive "Why?" questions. The rule: if you land on "that's just how it is" or "because we always have," you've found an assumption, not a ground truth. Keep going.

### Worked Example: "Our app has high churn"

| Why # | Question | Answer |
|-------|----------|--------|
| 1 | Why is churn high? | Users stop using the app after 2 weeks |
| 2 | Why do they stop after 2 weeks? | They complete the initial task and don't return |
| 3 | Why don't they return? | There's no recurring value — the app solves a one-time problem |
| 4 | Why is it a one-time problem? | We designed for the first use case, not the ongoing need |
| 5 | Why did we design for first use? | We assumed acquisition = retention. We optimized for "wow" not for habit |

**Ground truth discovered:** The product solves a one-time need. Churn isn't a bug — it's the correct behavior for the current design. The real question is: what recurring need exists for this user?

### When to go deeper than 5

Five is a guideline, not a rule. Stop when you reach a statement that is either:
- A verifiable fact (physics, data, math)
- An assumption you can explicitly test

If at "why #5" you're still in opinion territory, keep going.

---

## Counterfactual Thinking

Ask "What if the opposite were true?" for each major assumption. This technique is powerful because it breaks the frame — most assumptions feel inevitable until you imagine their negation.

### Worked Example: "Premium products need premium pricing"

**Assumption:** Our product is premium, so it must be priced high.

**Counterfactual:** "What if premium products should be priced LOW?"

**Analysis:**
- IKEA makes design-forward furniture affordable — premium design, mass-market price
- Tesla Model 3 brought premium EV to mass market — the goal was always volume
- Netflix disrupted HBO by being cheaper, not more expensive
- Premium ≠ expensive. Premium = better value at any price point.

**Ground truth discovered:** "Premium" describes quality, not price. High price is a positioning choice, not a fundamental requirement of quality products.

### How to apply effectively

1. State the assumption as a clear declarative sentence
2. Negate it completely — don't soften ("what if it were slightly less true")
3. Find 2-3 real examples where the opposite worked
4. Ask: is the original assumption physics (can't be negated) or convention (has been negated)?

---

## Assumption Mapping

Create a visual/tabular dependency graph of assumptions. Many assumptions depend on other assumptions — challenging a foundation-level assumption can collapse multiple dependent ones.

### Structure

```
Root Assumption: "Building software requires a large team"
├── Depends on: "Software is complex"
│   ├── Depends on: "We need many features"
│   │   └── CHALLENGE: Do users actually use most features?
│   └── Depends on: "Integration is hard"
│       └── CHALLENGE: With modern APIs, is it still?
├── Depends on: "Specialization is necessary"
│   └── CHALLENGE: Full-stack tools (Vercel, Supabase) reduce specialist needs
└── Depends on: "Coordination overhead is acceptable"
    └── GROUND TRUTH: Brooks's Law — coordination cost scales O(n²)
```

### How to build

1. List top-level assumptions
2. For each, ask: "This is only true if _____ is also true"
3. Map the dependencies — find the deepest assumptions
4. Challenge from the bottom up — if a root assumption falls, everything above it falls too

---

## Theoretical Minimum Analysis

Calculate the physics/math/logic floor for any metric. The gap between current state and theoretical minimum is your opportunity space.

### Framework

| Metric | Theoretical minimum | Current state | Gap | Gap driver |
|--------|-------------------|---------------|-----|------------|
| Cost | Raw materials + energy + irreducible labor | Market price | X% | Process inefficiency |
| Time | Sequential dependencies only | Current timeline | X% | Coordination overhead |
| Error rate | Information-theoretic limit | Current rate | X% | Process variance |

### Musk's version

"What are the material constituents of [thing]? What is each worth on the commodity market? That gives you the floor. Everything above the floor is a question of manufacturing and process."

This applies beyond physical products:
- **Software:** What is the minimum compute/storage for this function? Everything above is abstraction overhead.
- **Services:** What is the irreducible labor? Everything above is coordination and process.
- **Content:** What is the minimum information the user needs? Everything above is filler.
