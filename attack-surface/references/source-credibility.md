# Source Credibility — attack-surface

> **Read this before grading the dossier or writing any analysis.** It tells you how to judge a
> source's trustworthiness on two independent axes, how to keep low-trust sources from quietly
> becoming "facts" that drive a strategic bet, and how to deprioritize (not delete) them.
>
> **Sync note:** everything between `SHARED-CORE:BEGIN` and `SHARED-CORE:END` must stay
> byte-identical with `deep-research/references/source-credibility.md`. After editing the core,
> run `../../check-rubric-drift.sh` (the drift checker at the Skills repo root) to confirm the two
> copies are in sync — run it manually, or wire your own hook to run it on edit. The per-skill
> appendix below the core may differ.

<!-- SHARED-CORE:BEGIN — keep byte-identical across deep-research & attack-surface -->

## The core mistake this prevents

Grading the **container, not the claim** — and reading *production polish* as *authority*. A
glossy corporate blog looks authoritative and slides into the report as fact. It shouldn't.
Judge every source on two **independent** axes, then judge the specific claim separately.

## Axis 1 — Authority / provenance (how close to ground truth)

- **P (Primary):** original data, peer-reviewed research, official docs/specs, regulatory
  filings, court records, financial statements, first-party datasets.
- **S (Secondary):** named-author journalism with disclosed method, analyst reports that show
  their methodology, practitioner write-ups that link their primaries.
- **T (Tertiary / derivative):** aggregators, listicles, SEO content, summaries-of-summaries,
  undated or anonymous pages.

## Axis 2 — Independence / conflict-of-interest (stake in the claim being true)

- **Independent:** no financial/positional stake (academic, government, neutral journalism,
  disinterested practitioner).
- **Interested:** benefits if the claim is believed — vendor/competitor blog about its own
  category, sponsored/PR content, investor decks, affiliate reviews.
- **Unknown:** authorship or funding can't be determined.

**The rule that fixes the symptom:** *Production quality is not evidence of authority.* A
polished corporate blog is **Interested-Secondary at best**; treat its claims about its own
category as marketing until an Independent source corroborates them.

## Model patches (close the holes that otherwise let the symptom survive)

- **First-party-data carve-out (anti-over-demotion):** raw first-party data/benchmarks are
  **Primary regardless of author interest**. The Interested flag attaches to the *interpretation
  and generalizations drawn from* the data — never to the raw data. (A practitioner's own
  benchmark with real numbers stays high-value.)
- **Astroturf sub-flag:** reviews/forums (Reddit, G2, Trustpilot, App Store) are
  *covertly-interested-masquerading-as-Independent* — gamed by vendors/competitors. Tag them
  `manipulable`; they never count as an Independent corroboration chain on their own.
- **Unknown = Interested for gating:** burden of proof is on the source. An Unknown-only claim
  is treated like an interested-only claim.
- **All-interested-topic rule (anti-Goodhart):** if a topic genuinely has no Independent source
  (e.g. a brand-new category), draw the conclusion but stamp it **low-confidence with the
  conflict named**. Reclassifying an Interested source to "Independent" just to pass a gate is
  **forbidden**.
- **Competence caveat:** these axes catch conflict-of-interest, not incompetence. A
  disinterested-but-sloppy blog and a cherry-picked vendor primary both pass the axes — so
  **claim-binding** (below) must check the in-source data actually supports the *generalization*
  drawn from it, not merely that some data exists.

## Usage rules (the actionable part)

1. **No load-bearing claim rests solely on Interested/Unknown sources.** It needs ≥1 Independent
   corroboration **chain**, or it is flagged `interested-party, uncorroborated` and never stated
   as bare fact (write it as "X claims…").
2. **Corroboration counts independent evidence chains, not citations** (echo rule): if two
   sources trace to the same PR / dataset / wire story / original author, that's **one** chain.
   Conversely, **agreement across *opposing*-interest parties counts as near-independent**: two
   competitors agreeing on a fact neither benefits from, or a source conceding a point *against*
   its own interest, is strong corroboration — not an echo.
3. **Deprioritize ≠ delete.** Keep the source, annotate it, and rank Independent-Primary first
   in synthesis. Never silently drop a demoted source.
4. **Recency:** extract the publication date; flag claims past the domain's half-life (fast
   domains ≈ 1–2 years).
5. **Primary-chase is best-effort:** when a secondary cites a study/dataset, try to reach the
   primary. If you can't (paywall, opaque synthesis), default the claim to `secondary-only` /
   Tertiary — do not assume the chase succeeded.
6. **Confidence floor by independence — don't crush a lone strong source.** The independence
   axis, not chain-count alone, sets the floor. A single *Independent-Primary* chain (one
   peer-reviewed study, one official dataset, one disinterested first-party benchmark) warrants
   at least **medium** confidence — never force it to the same low/WEAK rating as a lone vendor
   blog. A single *Interested/Unknown* chain warrants **low**. "Single source" is only a
   high-skepticism trigger when that source is Interested/Unknown; a lone Independent-Primary is
   thin-but-trustworthy, not junk. (Two aligned Independent chains → high.)

## Claim-binding (judged per claim, not per source)

Even a Primary-Independent source can carry an over-extrapolated throwaway line. For each
load-bearing claim, confirm the cited source actually contains data that supports *this specific
generalization* — not just adjacent data. Also check the data isn't **selectively framed**: a
real-but-cherry-picked subset (favorable cohort, hand-picked time window, the single good metric)
fails claim-binding even when the numbers are genuine. A vendor's own benchmark that passes
claim-binding is still **Interested** — usable, flagged, corroborate before stating as fact.

<!-- SHARED-CORE:END -->

---

## Appendix — attack-surface specifics

**Inline trust tag:** attack-surface has no numbered-citation system — do **not** use `[N]`.
Tag inline, right after the quote/claim:
`"…quote…" (CompanyBlog — ⚠interested)`, `(Reddit thread — ⚠manipulable)`,
`(market-size figure — ⚠uncorroborated)`. Full provenance lives in the Source Credibility Ledger.

**Credibility is a SEPARATE axis from impact — do not fold it into the impact scores.** attack-surface's
1–5 scores are **fragility** and **leverage** (likelihood / impact). Never conflate "Leverage 5" with
"Primary-Independent." So credibility does **not** cap or lower Leverage/fragility — instead it rides
in its own **Evidence-confidence** field, and it gates *confidence*, not *impact*:

- **Opportunity Matrix:** keep Leverage as pure impact/effort (uncapped — a high-impact bet on thin
  evidence is *high-leverage, low-evidence*, not low-leverage). Add an **Evidence confidence** column
  = High / Medium / Low from the ledger. Interested-only → **Low**, and `Validation Needed` must begin
  "independent corroboration first." This keeps ranking meaningful even in all-interested markets
  (where capping Leverage would flatten everything to the floor).
- **Stress-test answer confidence** (this *is* a confidence axis, so credibility sets it): single
  *Interested/Unknown* chain → **WEAK**; single *Independent-Primary* chain → **MODERATE** (rubric
  rule 6 — don't crush a lone strong source); multiple independent chains → up to **STRONG**.
- **Fragile-assumption:** flag when its "evidence it's true" is interested-only; don't let interested
  evidence alone move the fragility score.

**Provocation discipline:** match assertion strength to evidence independence **in the prose**,
not only in a trailing tag. A thin, interested-only insight must read tentatively even when it is
provocative.
