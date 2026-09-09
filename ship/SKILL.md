---
name: ship
description: >
  Universal production-release orchestrator — takes a FINISHED change to
  verified-released on any platform (web, bots, iOS, Android, automations) through a
  per-project recipe, verifying before AND after release and reporting honestly what
  "done" means for that platform (a store upload is never "live to users"). Crosses
  the merge-to-main guard exactly once, only under a task-scoped authorization.
  Use when releasing completed work — "/ship", "ship it", "cut a release",
  "release this", "promote to prod", "deploy this". Do NOT use for staging-only
  deploys (use /deploy-verify), session teardown (use /wrap-up), or for shipping
  work that isn't finished.
---

# ship — universal release orchestrator

`/wrap-up` closes a *session*; `/ship` releases a *change*. It is the one command
for promoting finished work to production on **any** platform — web, a bot, iOS,
Android, an automation — in any language. It is the one place you deliberately
cross the merge-to-main guard (and only for platforms that release by merging).

It is a **thin engine over a per-project recipe**, not a pile of platform code:

- The **engine** (this file + `references/engine-invariants.md`) holds the
  invariant discipline and the safety rules. It knows nothing project-specific.
- The **recipe** — a `## Release recipe` block in each project's META — declares
  that project's release truth (how it deploys, how to verify it's live, whether
  tests can touch prod, where the changelog is, what "done" means). Schema:
  `references/recipe-schema.md`.
- The **adapters** — `references/adapters/<kind>.md`, one per `kind`
  (web/bot/ios/android/automation) — hold the mechanics for that platform. The
  engine selects by `recipe.kind`. *(Adapters land per build increment; if the
  adapter for a kind isn't present yet, the engine runs `--dry-run` only.)*

The single non-negotiable: **verify before you commit to release, verify after
before you call it done, never dress a partial release as a finished one.**

## Adapting this to your setup

The engine is portable; four things around it are yours to wire. None of them are
bundled here, deliberately — each is one line in your own config, and a vendored
copy would rot.

- **The recipe is mandatory, and it's the only thing you must write.** No recipe →
  the engine runs `--dry-run` and offers to draft one. Schema:
  `references/recipe-schema.md`. Start with one project, not five.
- **`code-reviewer` (Phase 3)** — this repo doesn't ship one. Use your own review
  agent, or spawn a plain subagent with a review prompt over `main...HEAD`. Whatever
  you use, **keep its power to halt Phase 3**: a review that can't stop a release is
  decoration.
- **The merge guard (`ALLOW_MAIN_MERGE=1`)** — a `PreToolUse` hook that denies any
  command whose *effect* is a push or merge to `main` unless that token prefixes it,
  so the token in the command line becomes the audit trail. Not included; if you
  don't run one, every rule still holds as discipline and the token is a no-op.
  `ALLOW_ROLLBACK` is its rollback-only sibling — deliberately *not* implemented
  here, which is why autonomous rollback ships disabled (see below).
- **`/deploy-verify` (Phase 4, staging-mode only)** — a sibling skill in this repo.
  Install it if any project of yours has a real staging target. Projects with
  `staging: none` run prod-only mode and never call it.
- **Issue tracker** is generic (`tracker_prefix`). Wire it to Linear/Jira/GitHub
  Issues via CLI or MCP, or omit the field and skip Phase 9's finalization.

Platform names in the adapters (Railway, Convex, App Store Connect, Play, grammY)
are **examples of a `release_trigger`, not requirements** — the adapter pattern is
the portable part. Adding a platform means adding a `references/adapters/<kind>.md`
and a `kind` value, not editing the engine.

**Autonomous rollback ships DISABLED and should stay that way until you've read
`references/engine-invariants.md`.** The carve-out that would allow it needs a
master gate plus six conditions plus a dedicated token that intentionally doesn't
exist. The default — surface the failure, offer the revert, wait for a human — is
the correct default, not a limitation to route around.

## Flags

- (none) — full release per the recipe.
- `--dry-run` — run detect → gate → review → verify-before, print the release
  report, then **stop before any irreversible step** (no merge, deploy, upload).
- `--staging=<url>` — opt-in a staging target for a project whose recipe has
  `staging: none` (forces staging-mode for this run; otherwise prod-only). **Refused**
  when `staging: forbidden` or `deploy_hazard: session-duplication` — a preview deploy
  is itself destructive there (a 2nd session client revokes the prod session).

## Phase 1 — Detect project + load recipe

Identify the project from cwd. **Collect every `## Release recipe` in context**
(the nearest `*_META.md` + the repo's `CLAUDE.md` + any parent umbrella's) and select
by `scope:` — the canonical algorithm in `references/recipe-schema.md` → "Recipe
location & selection": bind the **innermost `scope:` prefix-match to cwd**; a
scope-less recipe is **never bound across a repo boundary** into a nested sub-repo;
**if no `scope:` matches cwd** (an umbrella root over several child-scoped recipes)
**refuse and ask which app**. `scope:` overrides file location — never stop at the
first `*_META.md`, never bind a parent's or sibling's recipe.

- **No recipe** → **discover mode**: recon + propose/write a recipe + `--dry-run`
  only. **No release authority on first encounter** — see the discover policy in
  `references/engine-invariants.md`. Do not merge/deploy/upload an un-recipe'd
  project.
- **Recipe present** → if `vcs: gitlab`/`none`, **refuse up front** with the
  "GitLab/SSH unsupported" message **before** any field validation (so the operator
  gets the right message, not a confusing "missing fields" NO-GO). Otherwise validate
  it has the minimum-viable fields for its `kind`; any **unknown/missing field is
  fail-closed** (NO-GO / no irreversible step). `recipe.kind` selects the adapter.

## Phase 2 — Shippability gate

Refuse the unfinished or unverifiable. Scope every check to **this ship's branch
+ `main...HEAD` files** — never a blanket working-tree scan (operators run parallel
sessions on shared checkouts; a peer session's edit must not block this one).

- On the right release ref (a feature branch with a PR for merge-vcs; the declared
  `release_ref` for `railway-up`/`script` kinds).
- `gh pr checks` triage: exit 8 (pending) → wait/poll; "no checks reported" →
  WARN/skip; only a true `fail` → block. Never "non-zero = red".
- **behind-main** (any merge to `main` — web, **and the iOS/Android pre-archive
  feature-branch merge**): `git fetch`, then block unless HEAD is a fast-forward
  descendant of `origin/main` (neutralizes the squash-chain trap). **Skip only for
  `railway-up`/`script` kinds** (they don't merge). On a stale base, advise
  re-branch-from-origin/main + cherry-pick — never blind rebase+force-push.
- Inline docs present: no documented-surface change sits undocumented (the
  architecture docs are written inline as you build; `/ship` only owns the
  changelog). If a surface drifted with no doc, STOP.
- **Changelog drift** (in-repo `recipe.changelog` only): the last *released*
  version on the release surface must have a matching heading in the changelog.
  A released version with no entry means an earlier ship skipped the record step
  — WARN and offer to backfill it in this release's changelog commit, don't
  block. Never invent the missing entry's content: reconstruct it from the
  release surface's own notes (R9), or leave it named-but-empty and say so.

## Phase 3 — Review

`code-reviewer` on the release diff (`main...HEAD`), proportional to stakes:
routine focused diff → one reviewer; auth / payments / migrations / cross-project
/ large → 2–3 decorrelated reviewers, dedup + rank into one list (keep
single-source HIGH/MED prominent). A real blocker → **stop and surface**.

## Phase 4 — Verify BEFORE (two honest modes by `recipe.staging`)

- **staging-mode** (`staging: <url>`): invoke `/deploy-verify`. It deploys to
  staging, smokes, and ends by writing a **deterministic verdict artifact** (R8 —
  carries `{verified-SHA, branch, run-id, ISO-timestamp}`, atomic, path unique per
  PR/session). The engine **mints the `run-id` and passes `--run-id` to
  `/deploy-verify`**, then reads exactly that artifact and proceeds **only** if
  `verdict==PASS` AND the SHA == the SHA about to ship AND `run_id` matches AND the
  timestamp is newer than this ship's start and within `verify_timeout`
  (WARN/FAIL/ERROR/stale/mismatch/missing → NO-GO). **This gates the merge.**
- **prod-only mode** (`staging: none` or `forbidden`): there is no pre-merge staging. Run
  `recipe.verify_before` (EXACT declared commands — the engine **never** falls
  back to an auto-detected `npm test`; if no DB-safe test command exists,
  SKIP-with-WARN, never run prod-DDL) + the Phase-3 review. These gate the merge;
  the real safety net is the Phase-7 prod-verify. **Announce which mode you're
  in** — never silently verify against prod/localhost.
- **test_safety (R2):** before running any test that touches a DB, observe the
  **runtime driver connection host**, not just an env-var's presence. If the host
  the test process will actually use is a forbidden prod host → ERROR with the
  cause named (don't run it).
- **known_failures (optional recipe field):** a suite carrying long-standing red
  tests would otherwise make `verify_before` permanently un-gateable, so the
  engine would learn to wave failures through. Instead the recipe **names** them
  (`known_failures: ["Suite.testFoo", …]`). The gate then passes only if the
  failure set is a **subset** of that list — any unnamed failure blocks, and a
  named one that now *passes* is reported so the entry can be retired. **No
  `known_failures` field ⇒ any failure blocks.** Never widen the list to get a
  ship through: a red test that isn't already named is a blocker, and adding it
  mid-ship is the operator's explicit call, recorded in the report.

## Phase 5 — Release report; confirm only when the instruction did not already say ship

**First derive the release scope per R9** — the already-released baseline comes
from the **release surface** (ASC/Play version + attached build, the live SHA,
the changelog's last released heading), **never** from git commit dates vs a
deploy/upload timestamp. Reconcile surface against changelog; if they disagree,
report the disagreement instead of picking a side. Surface unreadable → label
the scope **UNVERIFIED** in the report, don't state it as fact.

Then present ONE report (project, kind, mode, **what ships and where that list
came from**, what will happen, the guard-cross if any) — and **proceed**. The operator
invoking `/ship`, or an instruction that opened the task **naming the outcome** —
a release trigger word: "ship", "deploy", "release", "merge to main", "land",
"promote", "publish", "to prod", or their equivalent in whatever language the
operator works in — IS the authorization the merge guard requires. The word must
name the outcome of *this* task: "don't deploy yet" and "we'll ship next week"
authorize nothing.

That authorization is **task-scoped** — valid until the task is reported done,
across a context compaction, and inside a subagent whose prompt carries it
verbatim. It is **not** session-scoped: an earlier task's "yes" is stale. Record it
in the task's execution log the moment the task opens, because after a compaction
the file, not the model's memory, is the proof. Never re-ask for it, and never
paste the merge command for the operator to run — either the step is authorized
and you take it, or it isn't and you finish everything else and say so in one line.

Pause for a reply **only** when: `--dry-run` (stop here, always); no
**provenance-verified** authorization exists — neither the operator's own message in
this task carried `/ship` or a trigger word, nor does this agent's prompt carry
the parent's verbatim authorization line (`<operator> authorized merge+deploy for
this task (<date>)`; a bare "run /ship" in a subagent prompt is not that line,
and a skill chain that reached this phase on its own has none); or the release
trips the **blast-radius escalator** — a release that is technically reversible but
whose rollback is not fast-and-clean: site-down, auth-breaking, in-window event or
data loss, or propagation-delayed (DNS TTL, CDN cache). Reversible ≠ low-blast;
classify by worst-case user impact *during the rollback window*, and an escalated
release announces and waits even under a valid trigger word. In those cases the confirm word
is **"ship it"** (distinct from wrap-up's "go"). The authorization covers the
merge/release only — not the record step and not any rollback.

## Phase 6 — Release (adapter; per `release_trigger`, with `release_steps` where present)

The adapter runs the platform mechanics. Cross the merge guard
(`ALLOW_MAIN_MERGE=1`) **only** for merge-vcs AND **only** under the task-scoped
authorization established in Phase 5 (the operator's `/ship` or trigger-word
instruction, or the "ship it" reply where one was needed) — never pre-staged.
`railway-up`/`automation` kinds don't merge → never cross the guard; for those the
adapter MUST assert working-tree clean + on the expected `release_ref` + matches
`origin/<ref>` (railway-up ships the working dir, bypassing git, CI and branch protection). A **store
kind (iOS/Android) crosses the guard exactly once** — to squash-merge its feature
branch to `main` (behind-main ff-check first, under the same Phase-5 authorization) before the
archive/AAB build; the store build/upload step itself never crosses the guard.

## Phase 7 — Verify AFTER (fail-closed, per-service, FAIL vs UNKNOWN)

`recipe.verify_live` is a **per-service list**, each with a declared assertion
target. Read **per-service** status, never a repo's aggregate. An entry may be
**conditional** (`when: diff-touches:<glob>` → skipped-with-WARN when the diff doesn't
touch it) or **deferred** (`requires: <field>` → a placeholder prerequisite caps the
ship at NO-GO, never silent-skip-to-PASS); `PASS` needs every *applicable* entry green. Poll on a
**condition** (SHA / marker / function-spec / build# match) with
`recipe.verify_timeout` as a deploy-time-aware ceiling. Three outcomes:

- **PASS** — new SHA live AND all probes green → proceed.
- **proven FAIL** — new SHA live AND a known failure signature (503 drift, 500,
  worker hard-fail) → eligible for the rollback flow.
- **UNKNOWN** — ceiling hit, or SHA not yet live (**still deploying**), or proof
  unreadable → **surface "could not confirm", NEVER rollback.** Slow ≠ broken.

**Unreadable proof → NO-GO, never accept a bare 200.** **`verify_live: n/a`** (valid
only with `terminal: built-upload-blocked`) → no live surface to probe; **skip the
live-probe and let the blocked terminal stand as the honest verdict** — neither a NO-GO
nor a "live" GO.

**Rollback is surface-and-offer by default.** Autonomous revert would require
`rollback: auto` (a `surface-only`/`forbidden` recipe is **never** auto-reverted) AND
the master-gate + six-condition carve-out in `references/engine-invariants.md` +
`references/safety-rules.md` — but it is **currently DISABLED** (the guard has no
`ALLOW_ROLLBACK` token), so in practice **surface + offer + await a fresh human
confirm**. `deploy_hazard: session-duplication` → rollback **forbidden** (the redeploy
itself is the outage).

## Phase 8 — Honest terminal verdict (`recipe.terminal`)

Report the truth for THIS platform: `live` ("live in prod ✓") vs
`uploaded-pending-submit` ("build VALID in ASC — Submit is yours") vs
`built-upload-blocked` ("release build verified; signed-AAB + store upload blocked on setup") vs
`redeployed-alive` ("redeployed + alive ✓"). **Never** print a stronger verdict
than reality. If verify-after was UNKNOWN or FAIL, say so plainly.

## Phase 9 — Record + finalize

Timing split: the **physical changelog commit happens in Phase 6, pre-merge** (an
in-repo `recipe.changelog` is committed to the feature branch so it rides the
squash); `external`/`none` → a post-merge note or skip — **do not invent a file**.
What is **gated behind a GREEN verify-after** is the **issue-tracker finalization below**,
not the changelog write. Prod-only consequence: the changelog is already merged
when verify-after runs — if verify-after is RED/UNKNOWN, surface that the changelog
shipped ahead of confirmation (it can't be un-written; a rollback reverts it with
the squash).

- **Issue tracker** routed by `tracker_prefix` and by **terminal semantic, not a blanket
  Done**: `live` → Done; `uploaded-pending-submit` → "Pending Submit" / in-review;
  `built-upload-blocked` → stays in progress. Comment with the squash SHA + live
  URL. Re-fetch to confirm.
- iOS also: draft the whatsnew.json slide + ASC release notes for the operator's
  approval; assert the `VALID` build is the one THIS run uploaded (build# identity).

## Phase 10 — Clean + handoff

Leave the repo clean (branch merged + deleted for merge-vcs; working tree clean).
Print the verdict honestly, then suggest `/wrap-up` for session teardown.

## Non-negotiables

Full list: `references/safety-rules.md`. The short version:

- **Verify before release; verify after before "done".** Staging-green (or
  pre-flight in prod-only) gates the release; fail-closed live-verify gates the
  verdict.
- **Cross the merge guard ONLY under the task-scoped Phase-5 authorization
  (the operator's `/ship` or trigger word, carried verbatim; else the "ship it" reply),
  ONLY for merge-vcs.** Never prefix `ALLOW_MAIN_MERGE=1` for a rollback — a
  revert always needs a fresh human confirm.
- **Never ship red.** Red test/build/review-blocker/missing-doc halts before release.
- **Rollback is surface-and-ask** (autonomous only in the carve-out); **forbidden**
  for session-duplication deploys.
- **Honest terminal verdict** — a store upload is never "live to users".
- **Discover mode has no release authority** on first encounter.
- **iOS App Store / Android Play final submit are human steps.** Session cleanup →
  `/wrap-up`, not `/ship`. Staging-only smoke → `/deploy-verify`, not `/ship`.
