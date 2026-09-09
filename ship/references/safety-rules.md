# safety-rules.md — the do-not-cross list for /ship

`/ship` crosses the merge guard and touches production across platforms. These
override speed and convenience every time. When a rule conflicts with shipping
faster, the rule wins. (Mechanics + per-recipe nuance: `engine-invariants.md`.)

## 1. Verify before release; verify prod before "done"

Staging-green (staging-mode) or pre-flight + review (prod-only) **gates the
release**. Fail-closed live-verify **gates the verdict**. Skipping or faking
either defeats the skill. A method with no readable proof is NO-GO — never accept
a bare 200, a store upload, or a `getMe` as proof of "live".

## 2. Cross the merge guard ONLY under the task-scoped authorization, ONLY for merge-vcs

This assumes a **merge guard** — a `PreToolUse` hook that denies any command whose
*effect* is a push or merge to `main`, unless an explicit token (`ALLOW_MAIN_MERGE=1`)
prefixes it. The token in the command line is the audit trail. If you don't run such
a guard, every rule below still applies as discipline; the token is simply a no-op.

The guard is fail-closed and it does **not** know what the operator said. Crossing it
requires BOTH the token on the exact command AND the task carrying the operator's
authorization: their own `/ship`, or an instruction that opened this task with a
release trigger word (SKILL.md Phase 5), or — when neither exists — their "ship it"
reply to the Phase-5 report. That authorization is
**task-scoped**: valid until the task is reported done, after compaction (record
it in the execution log), and inside a subagent whose prompt carries it verbatim.
It is **not** session-scoped: never merge on an earlier task's "yes", never
pre-stage the token, never infer authorization from a subagent prompt that lacks
the line. `railway-up`/automation kinds don't merge → they never cross the guard.
A **store kind (iOS/Android) may cross the guard exactly once** — to land a feature
branch to `main` *before* the store build/upload, under the same authorization,
and only after the behind-main ff-check; the store build/upload itself never
crosses the guard.

## 3. NEVER prefix `ALLOW_MAIN_MERGE=1` for a rollback

The task's authorization covers the release, not a revert. An auto-rollback that
self-prefixes the token to push a revert the human never saw is the precise
failure mode the guard was built after. A rollback push **never** uses `ALLOW_MAIN_MERGE=1`. It would
be autonomous only inside the carve-out (master gate + six conditions,
`engine-invariants.md`) via a dedicated `ALLOW_ROLLBACK` token — **which the guard does
not yet recognize, so autonomous revert is currently DISABLED**. Until then **every
revert requires a fresh same-turn human confirm** — never the original "ship it",
never `ALLOW_MAIN_MERGE=1`.

## 4. Confirm the deploy target is production

Never deploy prod code against a dev backend or vice versa; verify the environment
before the prod step. The verify-after must hit the **production** target from the
recipe — not staging, not a preview, not localhost.

## 5. Never ship red

Any red gate halts before release: failing tests, failing build, an open
code-review blocker, a missing inline doc for a changed surface, leaked secrets,
or a `migration_glob` hit that hasn't been human-cleared. Red → fix or stop.

## 6. Rollback is surface-and-ask; forbidden for session-duplication

Default: surface the failure + offer the revert; do not auto-execute. Autonomous
revert only in the carve-out (master gate + the six conditions in
`engine-invariants.md`) — and **currently DISABLED** (no `ALLOW_ROLLBACK` token in the
guard); until then every revert needs a fresh same-turn human confirm.
**`deploy_hazard: session-duplication` → rollback forbidden** — the redeploy
itself is the outage (a GramJS/Telethon redeploy can permanently revoke the prod
session). Never `reset --hard` a shared checkout held by another worktree; `git
stash -u` first; check any auto-revert watchdog first. A false "shipped ✓" over a red prod — or a
self-inflicted outage from a wrongful revert — is worse than not shipping.

## 7. Honest terminal verdict — never overstate "done"

Report the truth for THIS platform. A store upload is `uploaded-pending-submit`,
not "live to users". A blocked Play upload is `built-upload-blocked`. A bot is
`redeployed-alive` only after a heartbeat, not on `getMe` alone. If verify-after
was UNKNOWN or FAIL, say so — never dress it as a clean ship. Tracker status
follows the terminal semantic (iOS → "Pending Submit", not Done).

## 8. Discover mode has no release authority

An un-recipe'd project gets recon + a proposed recipe + `--dry-run` only — no
merge/deploy/upload, terminal capped at "deployed, UNVERIFIED". Don't spawn a
verify client for an unknown-kind bot (MTProto session-kill risk). Release unlocks
only once the recipe (which encodes the landmines) exists.

## 9. Stay in lane

- **iOS App Store / Android Play final Submit are human steps** — `/ship` stops at
  upload (iOS) / blocked-upload (Android) and drafts the notes for approval.
- **Session cleanup / teardown → `/wrap-up`**, not `/ship`.
- **Staging-only smoke → `/deploy-verify`** directly.
- **GitLab/SSH-hosted projects are unsupported** by the gh-path — refuse
  with a clear message, don't pretend.

## 10. Don't ship another session's work

Operators run parallel sessions on shared checkouts. Scope every gate to this ship's
branch + `main...HEAD`; confirm the branch + PR in the Phase-5 report; re-check
just-before-merge — a concurrent session's branch switch must not redirect the
merge to the wrong work. `railway up` ships the working dir — assert it's clean +
on the expected `release_ref` + matches `origin/<ref>` first.
