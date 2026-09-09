# recipe-schema.md — the `## Release recipe` block

Every project that `/ship` releases declares a `## Release recipe` block in its
project META. The engine reads it; the recipe supplies the platform/language
truth so the engine stays platform-agnostic. **Any unknown or missing field is
fail-closed** — the engine treats it as NO-GO / no-irreversible-step, never as
"probably fine".

## The block

```
## Release recipe
kind:            web | bot | ios | android | automation
transport:       (bot only) bot-api | mtproto-session
vcs:             github | gitlab | none
release_trigger: merge-main-autodeploy | railway-up | archive-upload-asc | gradle-aab | ssh-deploy | script
release_steps:   [ explicit ordered steps; no generic "run convex deploy" ]
release_ref:     (non-merge kinds) the ref railway-up/script ships from, e.g. build/v1
scope:           <sub-repo/app path this recipe governs, e.g. webapp/web | acme-bot>   # omit for a single-repo project; engine picks the recipe whose scope is the INNERMOST match to cwd
staging:         <preview-url> | none | forbidden
verify_before:   [ exact declared commands — engine NEVER auto-detects npm test ]
known_failures:  [ "Suite.testFoo", ... ]   # OPTIONAL. Long-standing red tests, named. Gate passes only if the failure set is a SUBSET of this. Absent ⇒ ANY failure blocks.
verify_live:
  - <service>: <method:assertion-target> [when: diff-touches:<glob>] [requires: <field>]   # per-service; each fail-closed UNLESS skipped by `when`
verify_auth:     <how to mint/inject a real session/token>   # required if any authed-roundtrip
verify_timeout:  <deploy-time-aware ceiling, e.g. 15m>
test_safety:     connect_host_observed forbid_host=<rlwy.net|...>   # host the test process ACTUALLY connects with
migration:       none | deploy-time | additive-self-heal | human-db-push-required | expand-contract-human-gated
migration_glob:  <path>   # for human-gated / expand-contract / human-db-push-required kinds
rollback:        auto | surface-only | forbidden
rollback_confirm_probes: <int, default 3>   # (only if rollback: auto) consecutive proven-FAIL probes before an autonomous revert
deploy_hazard:   none | session-duplication
changelog:       <in-repo path> | external | none
tracker_prefix:  <issue-key prefix, e.g. ABC — omit if you have no tracker>
terminal:        live | uploaded-pending-submit | built-upload-blocked | redeployed-alive
blocked_steps:   [ e.g. "play-upload: keystore/console pending" ]
```

## Field semantics

- **kind** — selects the adapter (`references/adapters/<kind>.md`).
- **transport** (bot only) — `mtproto-session` (Telethon/GramJS userbot) ⇒ a
  redeploy duplicates the session ⇒ **must** set `deploy_hazard: session-duplication`.
  `bot-api` (grammY/Bot API) has only a recoverable poll-conflict overlap.
- **vcs** — `gitlab`/`none` means the `gh`-based merge path does not apply; the
  engine refuses with a clear message unless an ssh-deploy adapter exists.
- **release_trigger / release_steps** — how the change actually reaches prod.
  `merge-main-autodeploy` crosses the merge guard; `railway-up`/`script`/`ssh-deploy`
  do not. Steps are **explicit** — never assume a hidden deploy (e.g. Convex
  deployed by a Railway build is one declared fact, not an extra `convex deploy`).
- **release_ref** — for non-merge kinds, the exact ref shipped (e.g. `build/v1`).
  The `railway-up` adapter asserts working-tree-clean + on this ref + == `origin/<ref>`.
- **staging** — `<url>` selects staging-mode (verify-before-merge via `/deploy-verify`);
  `none` selects prod-only mode (pre-flight + review gate the merge; the net is
  post-merge verify). `--staging=<url>` overrides per run. **`forbidden`** = a preview
  deploy is itself destructive (e.g. `deploy_hazard: session-duplication`) → the engine
  **hard-refuses `--staging`** and runs prod-only; never spin a preview for it.
- **verify_before** — the EXACT commands the engine runs pre-release. It must
  declare a **DB-safe** test command where tests touch a DB; the engine never
  substitutes an auto-detected `npm test`. If none is safe → SKIP-with-WARN.
- **known_failures** (optional) — the named, long-standing red tests a suite
  already carries. Without it a project with chronic red has no gateable
  `verify_before` at all, and the engine drifts into eyeballing "N failures, 0
  unexpected" and waving them through. With it the gate is exact: **pass iff the
  observed failure set ⊆ `known_failures`**. Any unnamed failure blocks; a named
  test that starts passing is reported so the entry can be retired. Each entry
  should carry the ticket that will remove it. Never widen the list mid-ship to
  get a release through — that's the operator's explicit call, and it belongs in
  the report.
- **verify_live** — a **per-service list**; each entry a method + a **declared
  assertion target** so the check can never degrade to "200 = ok":
  - `railway-meta-sha` — `railway status --json` commitHash (or `railway ssh …
    printenv RAILWAY_GIT_COMMIT_SHA`) == the merged SHA.
  - `bundle-marker:<literal>` — grep a fresh literal in the SPA bundle written to
    a file (never var-capture — truncates >1 MB; hashes contain `-`).
  - `convex-function-spec:<fn:arg:expected>` — assert the deployed contract, not
    "spec returned".
  - `asc-build-valid:<build#>` — the build THIS run uploaded reached `VALID`. `<build#>`
    is **resolved at release time** (= max-ASC-build + 1), not a static target — like
    `railway-meta-sha`; a recipe may write bare `asc-build-valid`.
  - `bot-getme + heartbeat:<signal>` — getMe is necessary but **not sufficient**
    (Telegram answers it for any valid token); pair with a process heartbeat /
    boot log line within N seconds.
  - `authed-roundtrip:<route>` — carries `verify_auth`; assert `200 + user object`,
    treat `503`/`500` as the drift signature (unauth probes miss authed-only drift).
  - `worker-route:<public route that hard-fails if worker dead> + migration-sentinel:<query>`
    — a 200 on `/` does not prove a backgrounded worker is alive or a deploy-time
    migration applied.
  - `worker-health-internal:<port>:<assertion> + migration-sentinel:<query>` — when NO
    public route hard-fails on a dead worker: reach the worker's **internal** health port
    via `railway ssh <svc> "curl -s localhost:<port>/health"` → assert the field (e.g.
    `gramjsConnected:true`). **Session-safe** — queries the running container, starts no
    new client (unlike a preview deploy). An unrecognized method must NOT degrade to the
    other services' methods — fail-closed.
- **Conditional / deferred verify_live entries.** A recipe must express "optional",
  "deferred", or "conditional" through fields — **never a prose comment** (the engine
  does not read intent from comments). An entry may carry:
  - `when: diff-touches:<glob>` — runs ONLY if the ship's `main...HEAD` diff touches
    `<glob>`; otherwise **skipped-with-WARN** (NOT a NO-GO). PASS needs every
    *applicable* entry green; a skipped entry doesn't block. (e.g. Convex
    `function-spec` only when `convex/**` changed; an authed-drift check only on
    schema/auth diffs.)
  - `requires: <field>` — depends on another recipe field (e.g. `authed-roundtrip
    requires: verify_auth`). If that field is unset or a **placeholder** (`TODO-*`,
    `<...>`, empty), the entry is **NOT skippable-to-PASS** — it caps the ship at NO-GO
    or an honest non-`live` terminal ("<surface> UNVERIFIED"). A deferred check must
    never silently pass via a sibling baseline entry.
- **`verify_live: n/a`** is allowed **only** when `terminal: built-upload-blocked` (a
  store kind whose upload is human-blocked → there is no live surface to probe; the
  blocked terminal is the honest verdict). **Never** `n/a` for `web`/`bot` kinds — that
  would be a fail-open false-GO.
- **verify_auth** — required wherever `authed-roundtrip` is used; how to obtain a
  real session/token for the round-trip. A placeholder (`TODO-provision`) = **unset**.
- **verify_timeout** — a deploy-time-aware ceiling. Hitting it yields **UNKNOWN**
  (surface, never rollback), not FAIL. Set above the project's real build+boot
  time (e.g. a ~13-min Bun build ⇒ ≥ 15m).
- **test_safety** — `forbid_host` checked against the **observed runtime driver
  connection host** (an env-var-presence check fails open — a project can inject a
  prod `DATABASE_URL` directly). For a kind that touches **no DB** (iOS / Android /
  most bots) the explicit value is **`n/a`** — required to be stated, never left blank
  (blank / `<...>` = MISSING).
- **migration** — `deploy-time`/`additive-self-heal` ⇒ a pending/additive
  migration is the normal path, NOT a blocker (but verify-after must assert it
  applied). `human-db-push-required` ⇒ block on any schema diff until a human
  pushes. `expand-contract-human-gated` ⇒ see `migration_glob`.
- **migration_glob** — for `human-gated`/`expand-contract`/`human-db-push-required`
  kinds: ANY change under it ⇒ **refuse-and-ask-human** (for `human-db-push-required`,
  block until a human runs `db:push`). The engine does NOT reason about whether a change is
  contract-breaking — it over-refuses (a comment-only edit refusing is the accepted
  cost). Expand-contract is permanently out of engine scope.
- **rollback** — `auto` (eligible for the carve-out) | `surface-only` (always
  surface, never auto-execute) | `forbidden`. Does **not** derive from `staging`.
  **Convex-coupled projects MUST set `surface-only`** — a `git revert` can't undo a
  Convex deploy that already ran. `rollback_confirm_probes` (default 3) sets the
  consecutive-FAIL count. **NOTE: autonomous revert is currently DISABLED** — the merge
  guard has no `ALLOW_ROLLBACK` token, so every revert needs a fresh same-turn human
  confirm regardless of `rollback: auto`. Keep recipes off `auto` until the guard
  learns a dedicated token.
- **deploy_hazard** — `session-duplication` ⇒ `rollback: forbidden` (the redeploy
  itself can permanently break a stateful session, e.g. AUTH_KEY_DUPLICATED).
- **changelog** — in-repo path (written pre-merge so it rides the squash) |
  `external` (post-merge note) | `none`. Never invent a file.
- **terminal** — what "done" means; drives Phase-8 verdict + Phase-9 issue-tracker state.

## Recipe location & selection (canonical algorithm)

The engine does **not** stop at the first file it finds. It **collects every
`## Release recipe` block in context** — across the nearest `*_META.md`, the repo's
`CLAUDE.md`, and any parent umbrella's META/CLAUDE.md the harness loaded — then selects
by `scope:`, which **overrides** file location. (A naive "first `*_META.md` wins"
ladder is WRONG: in `acme/acme-bot/` the nearest `*_META.md` walking up is the
**parent web** `ACME_META.md`, and stopping there would bind the web recipe to the
bot — crossing the merge guard. The algorithm below prevents that.)

1. Determine cwd's project (the innermost git repo / sub-app at cwd).
2. Keep the recipes whose `scope:` is a **path-prefix of cwd**. A recipe with **no
   `scope:`** is scoped to its own repo root; it is a **non-match** for a cwd inside a
   *nested* sub-repo and is **never bound across a repo boundary** — a nested repo with
   its own `.git`/`CLAUDE.md` (e.g. `acme-bot`) binds **only** its own-scope recipe,
   never the parent umbrella's.
3. Bind the **innermost (longest-prefix) match**.
4. **If no `scope:` matches cwd** — cwd is at/above an umbrella root holding several
   child-scoped recipes (e.g. `acme/` over web + iOS + android) — **refuse and ask
   which app**; never auto-bind one.
5. No recipe at all → discover mode.

**Prefix-matching is on path *segments*, not raw string** — `Bookv-iOS-29` does not
match `Bookv-iOS-29-beta`. A relative `scope:` anchors to the directory of the
`*_META.md`/`CLAUDE.md` that declares it.

## Minimum-viable recipe (before any irreversible step)

The engine may not merge/deploy/upload until the recipe declares at least:
`kind`, `vcs`, `release_trigger`, `staging`, `verify_live` (a real fail-closed
method, not "200"), `migration` (+ `migration_glob` if human-gated), `rollback`,
`deploy_hazard`, `test_safety`, and `verify_auth` (if any `authed-roundtrip`).
Missing any → discover mode: `--dry-run` + propose-recipe only. **A placeholder value
(`TODO-*`, `<...>`, empty) counts as MISSING, not present** — `verify_auth:
TODO-provision` does not satisfy the requirement (fail-closed, not fail-open).

## Where the per-project recipes go

A recipe lives in the project it describes — a `## Release recipe` block in that
project's META (or its `CLAUDE.md`, or a standalone repo's own doc), never in this
file. **This file is the schema, not the data.** One project with three shippable
apps carries three `scope:`-qualified recipes; a single-repo project carries one
with no `scope:` at all.
