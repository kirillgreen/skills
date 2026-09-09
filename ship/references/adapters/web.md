# adapters/web.md — the `web` kind

Applies when `recipe.kind: web`. The engine (SKILL.md) runs the invariant ritual;
this adapter supplies the web mechanics, driven by the recipe's values. It
composes `/deploy-verify` for staging — it does not reimplement verification.

## Phase 2 — shippability (web specifics)

- merge-vcs (`vcs: github`): a feature branch with a PR.
  `gh pr view --json number,state,mergeable,headRefOid,baseRefName,title`.
- `gh pr checks` triage (R3): exit 8 (pending) → wait/poll; "no checks reported"
  → WARN/skip; only a true `fail` → block.
- behind-main ff-check (merge-vcs): `git fetch origin main`, then block unless HEAD
  is a fast-forward descendant of `origin/main` (squash-chain trap). Stale base →
  advise re-branch from origin/main + cherry-pick.
- `vcs: gitlab`/`none` → **unsupported by the gh-path; refuse** with a clear message
  (no ssh-deploy adapter yet).

## Phase 4 — verify BEFORE (mode by `recipe.staging`)

- **staging-mode** (`staging: <url>` or `--staging`): invoke `/deploy-verify` **with a
  generated `--run-id=<nonce>`** — the engine mints the nonce and passes it so it reads
  exactly its own artifact (a caller cannot learn a callee-chosen nonce). Read the
  artifact at that exact path and proceed ONLY if `verdict == PASS` AND `verified_sha
  == <current HEAD to ship>` AND `run_id ==` the nonce passed AND the timestamp is
  newer than this ship's start and within `verify_timeout`. Anything else
  (WARN/FAIL/ERROR/stale/mismatch/missing) → NO-GO. **This gates the merge.**
  (`--staging` is refused when `staging: forbidden` — never spin a preview there.)
- **prod-only mode** (`staging: none`): run `recipe.verify_before` **exactly** (the
  engine NEVER falls back to an auto-detected `npm test` — a recipe with a DB-unsafe
  default test would DDL prod). + the Phase-3 review. These gate the merge. Announce
  "prod-only mode" in the report.
- Before any DB-touching test, the connect-host guard (R2, enforced inside
  `/deploy-verify` Step 1) must pass — observe the runtime driver host, ERROR if it's
  a forbidden prod host with no safe override.

## Phase 6 — release (only under the Phase-5 authorization)

- **SHA pin:** immediately before merge, re-assert PR `headRefOid` == the verified
  SHA AND `baseRefName == main`. A concurrent session's push changes `headRefOid` →
  NO-GO.
- **Changelog (pre-merge):** if `recipe.changelog` is an in-repo path, commit the
  release entry to the **feature branch now**, before the merge, so it rides the
  squash (merged == verified). `external`/`none` → handled post-merge / skipped;
  never invent a file.
- **Merge:**
  ```bash
  ALLOW_MAIN_MERGE=1 gh pr merge <N> --squash --delete-branch
  ```
  The Phase-5 authorization (task-scoped) IS the instruction the guard requires — never
  pre-stage the token. From a worktree, `gh pr merge` **errors but the merge still
  succeeds** → confirm via `gh pr view --json state,mergedAt`, do not retry.
- **Deploy:** merging `main` triggers the platform auto-deploy (Railway/Vercel).
  Where `recipe.release_steps` says Convex is deployed by the Railway backend build,
  the merge deploys it — **NEVER run a separate `convex deploy`** (it would ship the
  local tree, not merged main). Confirm the target is **production**.

## Phase 7 — verify AFTER (fail-closed, per-service)

For each `recipe.verify_live` entry (per-service), poll on the **condition** with
`recipe.verify_timeout` as the ceiling. An entry with `when: diff-touches:<glob>` is
**skipped-with-WARN** when the `main...HEAD` diff doesn't touch it; one with
`requires:<field>` whose prerequisite is a placeholder **caps at NO-GO**, never
silent-skip-to-PASS. PASS needs every *applicable* entry green. Gate on deploy STATE first: BUILDING/queued
= **still deploying → keep waiting** (UNKNOWN at the ceiling, never rollback);
SUCCESS + SHA-match → run the probes; FAILED → proven FAIL.

- `railway-meta-sha` — `railway status --json` → `meta.commitHash == <merged SHA>`,
  or `railway ssh --service <svc> "printenv RAILWAY_GIT_COMMIT_SHA"`. Read
  **per-service**, never the repo aggregate (a sibling cron flips it).
- `bundle-marker:<literal>` — `curl -s <prod>/<bundle> -o /tmp/ship-bundle.<run-id>.js
  && grep -c "<literal>" /tmp/ship-bundle.<run-id>.js` (write to a **run-unique file**,
  never var-capture — >1 MB truncates, hashes contain `-`; the run-id keeps concurrent
  ships from clobbering each other). Fresh literal present == new bundle live. **Needs
  `curl`** — for a project whose session blocks curl (context-mode sessions, for instance) the
  recipe must use `railway-meta-sha` for the SPA instead.
- `convex-function-spec:<fn:arg:expected>` — `bunx convex function-spec --prod` (or
  per recipe); assert the named function's arg matches `expected` (the **contract**,
  not "spec returned").
- `authed-roundtrip:<route>` — mint a session per `recipe.verify_auth`; GET `<route>`
  carrying it; assert **200 + a user object**; `503`/`500` = the drift signature
  (proven FAIL). An unauth probe does NOT count.
- `worker-route:<route> + migration-sentinel:<query>` — hit the public route that
  hard-fails if the worker is dead; run the sentinel to assert the deploy-time
  migration actually applied (a 200 on `/` proves neither).
- `worker-health-internal:<port>:<assertion> + migration-sentinel:<query>` — when no
  public route hard-fails on a dead worker: `railway ssh <svc> "curl -s
  localhost:<port>/health"` → assert the field (e.g. `gramjsConnected:true`). This
  hits the running container (session-safe). An UNRECOGNIZED `verify_live` method must
  **fail-closed (NO-GO)**, never silently downgrade to another service's method.

Outcomes: PASS (new SHA live + all probes green) → proceed; proven FAIL → rollback
flow; UNKNOWN (ceiling / still-deploying / unreadable) → **surface, never rollback.**
Unreadable proof → NO-GO, never a bare 200.

**Rollback (only on proven FAIL, only per the policy):** gated by `recipe.rollback`
(master gate `rollback: auto`; `surface-only`/`forbidden` never auto-revert) + the
master-gate + six-condition carve-out in `engine-invariants.md` — **but autonomous
revert is currently DISABLED** (the guard has no `ALLOW_ROLLBACK` token), so in
practice **surface + offer + await a fresh same-turn human confirm**.
`deploy_hazard: session-duplication` → forbidden. Mechanics (for the human-confirmed
revert): `git revert --no-edit <squashSHA>` (SHA via `gh pr view <N> --json
mergeCommit`); `git stash -u` first; do **not** `checkout main` if another worktree
holds it; verify the rollback live; on its failure hard-stop + escalate (never
revert-the-revert).

## Phase 8–9 — terminal + record

`terminal: live` → verdict "live in prod ✓"; tracker → Done (by `tracker_prefix`),
comment with squash SHA + live URL. Changelog already rode the squash (above). If
verify-after was UNKNOWN/FAIL, say so plainly — and note the changelog shipped ahead
(prod-only).
