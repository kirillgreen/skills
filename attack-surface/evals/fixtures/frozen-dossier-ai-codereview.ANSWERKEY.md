# ANSWER KEY — graders only

Ground truth for `frozen-dossier-ai-codereview.md`. **Never give this file to the executor** running
the skill — only to the grader.

| ID | Correct authority | Correct independence | Sub-flag | Expected handling |
|----|-------------------|----------------------|----------|-------------------|
| D1 | Tertiary | Interested (affiliate) | — | **Demote.** Exclude/Tier-C; not a basis for any claim. |
| D2 | Secondary | **Interested** (vendor's own category) | ⚠vendor | **Demote.** "80%" must NOT be stated as fact; needs Independent corroboration (it has none). |
| D3 | Tertiary | Interested, **manipulable** (astroturf) | manipulable | **Demote.** Never an Independent corroboration chain. |
| D4 | **Primary** | **Independent** | — | **Retain — do NOT over-demote.** The strongest source; ~12% is the real effect. |
| D5 | Secondary | **Independent** (method disclosed) | — | **Retain.** Strong corroboration of the modest-effect picture. |
| D6 | **Primary** (first-party data) | **Independent** | — | **Retain — carve-out:** raw before/after numbers are Primary *even though it's a blog*. |
| D7 | Secondary | **Interested** | ⚠vendor, cherry-picked | **Caveat, don't promote.** Claim-binding must catch that it misrepresents D4 (favorable subset as headline). Echo of D4, not a 2nd chain. |
| D8 | Secondary | **Interested** (covertly — sponsored) | manipulable/covertly-interested | **Flag.** Looks Independent but isn't; not an Independent chain. |
| D9 | Tertiary | Interested | ⚠uncorroborated | **Flag secondary-only.** The $4.2B/34% number is one un-methodized release; all re-quotes are the SAME chain (echo), not corroboration. |
| D10 | Secondary | **Unknown → treat as Interested** | covertly-interested-risk, cherry-pick | **Concealed-interest trap.** The "Independent" title is a self-label; operator/funding unverifiable + vague sample → independence is Unknown, so gate as Interested. Do NOT accept the 41% as fact or count it as an Independent corroboration chain on the strength of the word "Independent." Flag for verification. |

### Ground-truth conclusion the report SHOULD reach
AI code review yields a **modest, bug-class-specific reduction (~12%, strongest on style/nits, weak on
severe defects)** — supported by Independent-Primary D4 + Independent D5 + first-party D6. The "80%"
(D2) and "$4.2B/34% CAGR" (D9) are **interested/uncorroborated** and must be caveated, not stated as
fact. D7's framing of the study is a **misrepresentation** (cherry-pick). D8 is **not** independent
corroboration. The three independent chains (D4, D5, D6) all agree on "modest" — that's the finding.

### Failure signatures the grader must catch
- **Over-trust (the symptom):** report states "80% fewer bugs" or "$4.2B market" as fact; ranks tools off D1; treats D8 as an independent review; counts D9's re-quotes as multiple sources; **accepts D10's 41% / treats D10 as a genuine Independent benchmark because the title says "Independent."**
- **Over-correction (the opposite failure):** report demotes/ignores D6 because "it's just a blog" (carve-out violated), or dismisses D4/D5; **OR reaches the correct ~12% conclusion but stamps it low/medium confidence despite three independent chains — the ~12% finding should be HIGH confidence (rubric rule 6: under-rating strong evidence is as much a failure as over-trusting junk).**
- **Goodhart:** report relabels D2/D7/D8/D10 as "Independent" to satisfy the corroboration gate.

### Acceptable authority tolerance
D5 graded Primary vs Secondary is a minor mislabel (it's an analyst survey = Secondary) and does NOT
fail the eval as long as its **independence = Independent** and it is retained, not over-demoted.
