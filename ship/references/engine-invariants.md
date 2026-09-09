# engine-invariants.md — the rules the engine enforces regardless of platform

These are the invariants distilled from two dual-lead blast-radius passes against
a real multi-project fleet. They hold for every `kind`. When an invariant conflicts with
shipping faster, the invariant wins.

## R1 — Two honest modes, never a third "verify against prod"

`staging: <url>` → staging-mode (verify-before-merge via `/deploy-verify`).
`staging: none` (or `forbidden`) → prod-only mode (pre-flight + review gate the merge;
the net is post-merge verify-after). `forbidden` additionally hard-refuses `--staging`. The engine **announces the mode** and never silently
verifies against prod or localhost. In practice few projects have staging — most of the
fleet is prod-only by topology, and that's expected, not a defect.

## R2 — test_safety keys on the OBSERVED runtime host, not env-presence

Before any DB-touching test, observe the host the test process will **actually
connect with**. An env-var-presence check (`is TEST_DATABASE_URL set?`) fails
open — a project can inject a prod `DATABASE_URL` directly into the test env.
ERROR (name the cause) if the observed host is a forbidden prod host. Never run a
test that would DDL production.

## R3 — `gh pr checks` triage

Exit 8 (pending) → wait/poll (real suites take minutes; running `/ship` right
after a push must not read "still running" as failure). "No checks reported" →
WARN/skip (new repos, PoCs with no CI yet). Only a true `fail` → block. Never
"non-zero = red".

## R4 — Migration policy is per-recipe; the engine never reasons about contracts

`deploy-time` / `additive-self-heal` → a pending/additive migration is the normal
deploy path, NOT a blocker — but verify-after must assert it **applied** (a failed
deploy-time migration ships silently behind a 200). `human-db-push-required` →
block on any schema diff. `expand-contract-human-gated` + `migration_glob` → ANY
change under the glob ⇒ **refuse-and-ask-human**; the engine over-refuses rather
than guess whether a Convex/schema change is contract-breaking (false-positive
refusals are the accepted cost; expand-contract is permanently human-owned).

## R5 — verify_live is fail-closed, per-method, never "200 = ok"

Each `verify_live` entry carries a declared assertion target (a SHA, a literal, a
function:arg:expected, a build#, an authed user object). A method with no readable
proof → **NO-GO**, never accept a bare 200. A reverted/old deploy serves 200; a
store upload is not "live"; getMe answers for a dead bot.

An entry may be **conditional** (`when: diff-touches:<glob>` → runs only if the diff
touches it, else **skip-with-WARN**, not NO-GO) or **deferred** (`requires: <field>` →
if the prerequisite is a placeholder/unset, the entry is **NOT skippable-to-PASS**; it
caps the ship at NO-GO or an honest non-`live` terminal — it must never silently pass
via a sibling baseline entry). `PASS` requires every *applicable* entry green. Express
optional/conditional through these fields — never a prose comment.

## R6 — Per-service status, never the aggregate — including the rollback trigger

Read each service's status independently. A repo's aggregate GitHub deployment
status is flipped by sibling crons (e.g. a `canary-recall` job) — using it for
verify **or** for a rollback trigger causes wrongful FAILs on a healthy ship.

## R7 — Authed round-trip on auth-bearing projects

Drift that only breaks signed-in users (a 503 on session lookup) is invisible to
an unauthenticated 200. Where the recipe says `authed-roundtrip`, carry
`verify_auth` (a real session/token) and assert `200 + user object`; treat
`503`/`500` as the drift signature.

## R8 — The verdict artifact must prove freshness + ownership

`/deploy-verify` ends by writing its verdict to a **file artifact** (not a grepped
narrative line — an LLM skill's prose is not a machine contract). The artifact
carries `{verified-SHA, branch, run-id, ISO-timestamp}`, written atomically
(temp → rename). **`/ship` mints the `run-id` and passes it (`--run-id=<nonce>`)**;
`/deploy-verify` writes to exactly that path; `/ship` reads exactly that path — a
caller cannot otherwise learn a callee-chosen nonce, and two runs on the *same* SHA
can't be disambiguated without it. The engine trusts a `PASS` only after asserting:
SHA == the SHA it is about to ship, `run-id` == the nonce it passed, AND the
timestamp is **newer than this ship's start and within `verify_timeout`**. Otherwise
a stale PASS, a sibling run on the same SHA, or a concurrent-session clobber becomes a
false-GO. Missing artifact → NO-GO.

## R9 — The shipped baseline comes from the RELEASE SURFACE, not commit chronology

"What ships in this release" = the diff between what is **already released** and
what is on the release ref. The engine must derive the *already released* half
from the **release surface itself** (ASC/Play version + its attached build,
the live SHA a `verify_live` probe reads, the changelog's last released heading)
— **never** by comparing git commit dates against a deploy/upload timestamp.

Commit chronology lies, routinely and silently:

- A store build is cut from a **feature branch** and uploaded *before* the PR
  squash-lands on `main`, so the merge commit's date is **after** the upload of
  the build that already contains it.
- A squash-merge stamps a **new** commit date on months-old work.
- A hotfix branched from a tag ships code whose commits predate the previous
  release entirely.

Observed on an iOS app at 1.5.11 (2026-09-01): the engine reported the reader
text-selection fix (APP-549) as unreleased and asked the operator whether to
include it, because its merge commit was dated one day *after* build 216's
upload. ASC's own release notes for 1.5.10 described that exact fix — it had
shipped a month earlier. A release report is a factual claim about what reaches
users; getting it from the wrong source produces a confident, wrong claim, and
the operator answered a question that should never have been asked.

**Rule:** before writing the Phase-5 report, read the released baseline from the
platform's release surface (the adapter says how for its `kind`) and reconcile
it against the changelog. If the two disagree, say so in the report rather than
picking one — a disagreement is itself a finding (it means the changelog drifted,
or a build shipped off-branch). Only if the surface is genuinely unreadable may
the engine fall back to git, and it must then **label the scope as UNVERIFIED**
in the report instead of stating it as fact.

## Verify-after: FAIL vs UNKNOWN (opposite safe-defaults)

- **PASS** — new SHA live AND all per-service probes green → proceed.
- **proven FAIL** — new SHA live AND a known failure signature → eligible for the
  rollback flow.
- **UNKNOWN** — `verify_timeout` ceiling hit, or the new SHA is not yet live
  (**still deploying** — slow ≠ broken), or proof unreadable → **surface "could
  not confirm", NEVER auto-rollback.** Poll on the condition, with the timeout as
  a ceiling that yields UNKNOWN.

## Auto-rollback policy (the single most dangerous mechanism)

**Default: surface-and-offer the revert; do NOT auto-execute.** The net the operator
needs in prod-only mode is fast detection + a one-keystroke revert, not autonomous
reverts on a noisy signal.

> **Autonomous revert is currently DISABLED.** The merge guard
> (`pre-main-merge-guard.sh`) recognizes only `ALLOW_MAIN_MERGE=1` — there is **no
> `ALLOW_ROLLBACK` token** — so an autonomous revert can't push without either being
> blocked or illegally self-prefixing `ALLOW_MAIN_MERGE=1`. Until the guard learns a
> dedicated token, **every revert requires a fresh same-turn human confirm** and no
> recipe should set `rollback: auto`. The carve-out below is the design for when the
> token exists.

When (and only when) the guard supports it, autonomous revert is permitted ONLY when
the **master gate (0) plus the six conditions (1–6)** all hold:

0. **`rollback: auto`** — a `surface-only` or `forbidden` recipe is **never**
   eligible for autonomous revert, regardless of the other conditions
   (surface-and-offer, always). This is the master gate.
1. `migration == none` AND not Convex-coupled — because `git revert` is **not** an
   undo once a deploy moved schema/Convex state forward (the revert redeploys old
   functions against migrated/forward state = the exact skew the expand-contract
   dance avoids).
2. `deploy_hazard != session-duplication` — a redeploy of a session-coupled
   service (GramJS/Telethon) can permanently revoke the prod session
   (AUTH_KEY_DUPLICATED). `forbidden` recipes are surface-only, always.
3. verify-after returned a **proven FAIL** (not UNKNOWN/timeout) across **≥3
   consecutive** probes ≥60s apart, all past `verify_timeout`. One flaky probe
   never rolls back. (A project may override the count via `rollback_confirm_probes`.)
4. The revert push uses a **dedicated `ALLOW_ROLLBACK` token, never a
   self-prefixed `ALLOW_MAIN_MERGE=1`** — autonomously crossing the merge guard
   violates its stated contract (the guard exists precisely to stop autonomous
   pushes to main the human never saw).
5. `git stash -u` before any tree mutation; **never `reset --hard` a shared
   checkout held by another worktree** — STOP and surface instead.
6. Check no auto-revert watchdog has already reverted, if you run one (take a lock;
   avoid double-revert /
   revert-of-revert). The rollback has its **own verify** (revert deployed +
   healthy); on failure it **hard-stops and escalates** — never auto-reverts-the-revert.

Rollback mechanics: `git revert --no-edit <squashSHA>` (SHA via
`gh pr view <N> --json mergeCommit`).

## Discover mode — no release authority on first encounter

An un-recipe'd project: the engine may recon, propose/write a recipe, and run a
read-only `--dry-run`. It may **NOT** merge, push-to-main, `railway up`, deploy,
or upload. The terminal verdict is hard-capped at `"reconned, UNVERIFIED — recipe
required"` (never `live`/`done`). For an **unknown-kind bot, do not spawn any
verify client** until kind/transport is known (an MTProto verify client can kill
the prod session). Release authority unlocks only once a recipe exists with the
minimum-viable fields (see `recipe-schema.md`) — because every project hides a
non-obvious irreversibility the engine cannot infer.

## Fail-closed default

For **any** field the recipe leaves `unknown`/missing, the engine defaults to the
safe side: NO-GO, or skip-the-irreversible-step, never "probably fine".

## Cross-cutting git/worktree facts

- **behind-main (merge-vcs only):** `git fetch`, then block unless HEAD is a
  fast-forward descendant of `origin/main` — neutralizes the squash-chain trap.
  Skip for `railway-up`/`script` kinds. On a stale base, re-branch from
  origin/main + cherry-pick, never blind rebase+force-push.
- `gh pr merge` from a worktree **errors but the merge still succeeds** — confirm
  via `gh pr view --json state,mergedAt`, don't retry. The rollback path must not
  `checkout main` if another worktree holds it.
- `railway up`/`script` kinds bypass git, CI and branch protection entirely → the adapter
  asserts working-tree-clean + on `release_ref` + == `origin/<ref>` before shipping.
