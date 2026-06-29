# Frozen Dossier Fixture — "Do AI code-review tools actually reduce bugs?"

Shared calibration fixture for BOTH `deep-research` and `attack-surface`. Pointing a skill at this
frozen dossier (instead of live Exa search) makes the eval reproducible — it tests vetting +
synthesis, not live collection. Same fixture across both skills surfaces behavioral drift between
the two rubric copies.

The topic deliberately mixes obvious-junk, obvious-strong, and the **ambiguous middle** (a polished
vendor blog citing a real-but-cherry-picked study; a sponsored-but-unmarked "independent" review; a
thin-methodology industry report) — the middle is where the real symptom lives.

**Grader answer key is a SEPARATE file** (`frozen-dossier-ai-codereview.ANSWERKEY.md`) so it can
never leak into the executor's context. This file contains only what the skill is allowed to see.

---

## DOSSIER — the sources the skill sees

**[D1]** *"The 12 Best AI Code Review Tools in 2026"* — bestdevtools-deals.com. No author byline, no
date visible. Affiliate "Buy now" buttons next to each tool. Ranks tools, light on evidence.

**[D2]** *"AI code review cuts bugs by 80% — our data"* — blog.codereviewai.com (CodeReviewAI Inc.,
which sells an AI code-review product). Marketing post. States "teams using our tool ship 80% fewer
production bugs." No methodology, no raw dataset linked.

**[D3]** Reddit r/programming thread — a dozen enthusiastic comments praising one specific tool
("ReviewBot changed my life"), several accounts created the same week, similar phrasing.

**[D4]** *"Automated Code Review and Defect Density: A Randomized Controlled Trial"* — Empirical
Software Engineering journal (peer-reviewed), 2025, named academic authors, full method + dataset
appendix. Finds a **modest** defect-density reduction (~12%) concentrated in specific bug classes.

**[D5]** *"State of Code Review 2026"* — independent analyst (named researcher, no vendor funding
disclosed-or-found), survey of 540 engineering teams, methodology section published, raw aggregates
shared. Reports mixed results: helps review throughput, weak signal on escaped defects.

**[D6]** Personal engineering blog — a senior engineer publishing **their own team's before/after
defect data** (12 months, real numbers in a table) after adopting AI review. Not selling anything.
Concludes "helped on style/nits, no measurable change in severe bugs for us."

**[D7]** *"Why AI Review Is a Game-Changer — backed by research"* — blog.codereviewai.com (same
vendor as D2). Cites the D4 journal study, but quotes **only** the favorable sub-result and presents
the ~12% as if it were the headline effect across all bug types.

**[D8]** *"AI Code Review Tools — Honest Reviews"* — devtoolreviews.net. Reads neutral and
editorial. Fine print at the very bottom: "This site receives compensation from featured vendors."
Top-ranked tool is the site's highest-paying advertiser.

**[D9]** *"AI Code Review Market to hit $4.2B by 2030, 34% CAGR"* — marketreports-pro.com press
release. Big headline number. Methodology is one sentence ("based on proprietary analysis"); no
sample, no basis shown. Number is widely re-quoted by other blogs (all citing this same release).

**[D10]** *"The Independent 2026 Benchmark: AI Review Cuts Escaped Defects 41%"* —
airev-insights.org. A clean, neutral-looking research microsite with a named "Research Director"
and a methodology section; presents the 41% figure as an independent industry benchmark. The page
gives no information about who funds or operates the site, and the sample is described only as
"leading engineering teams." (Concealed-interest test: the word "Independent" is a self-label, not
proof — independence cannot actually be verified from anything on the page.)
