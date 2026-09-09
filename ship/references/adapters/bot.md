# adapters/bot.md — the `bot` kind

Applies when `recipe.kind: bot`. Bots ship by **redeploying a running service**
(`railway up` / equivalent), not by merging to main — so the merge guard is NOT
crossed. But `railway up` ships the **working directory**, bypassing git / CI /
a green deploy log, and a bot that answers `getMe` or returns 200 on `/health` is **not**
proof its update loop is running. The adapter makes the redeploy safe and proves
the bot is actually alive afterward.

## transport — the safety axis

- **`bot-api`** (grammY / Bot API): a redeploy causes at most a
  transient poll-conflict (409) or an idempotent `setWebhook` — **recoverable**.
  ⇒ `deploy_hazard: none`, `rollback: surface-only`.
- **`mtproto-session`** (Telethon / GramJS userbot): a redeploy puts a 2nd client
  on the same session → **AUTH_KEY_DUPLICATED permanently revokes it** (interactive
  re-login to recover). ⇒ `deploy_hazard: session-duplication`, `rollback:
  forbidden`, and a verify client must **never** be spawned for it (discover rule).

## Phase 2 — shippability (bot specifics)

- On the declared `release_ref` (e.g. `build/v1`), not necessarily main. **Skip the
  behind-main ff-check** (railway-up kinds don't merge to main).
- `gh pr checks` triage applies only if a PR exists; otherwise rely on `verify_before`.

## Phase 4 — verify BEFORE

Run `recipe.verify_before` exactly (typecheck + tests + lint). Bots usually have no
staging → prod-only mode; the real net is the post-deploy liveness check.

## Phase 5 — confirm

One "ship it". **No merge-guard cross** (railway-up doesn't touch main).

## Phase 6 — release (railway-up dirty-tree + ref guard — MANDATORY)

`railway up` ships the working dir, bypassing git, CI and branch protection. Before it, assert:
- working tree clean (`git status --porcelain` empty),
- on the expected `release_ref` (`git branch --show-current` == `recipe.release_ref`),
- `git fetch` then HEAD == `origin/<ref>` (refuse if ahead / behind / dirty).

Confirm the exact Railway `--service` name from `railway status` (persist it into the
recipe on first ship). Then:
```bash
railway up --service <svc>
```
For `mtproto-session` bots the redeploy is itself the session-duplication hazard —
proceed only with explicit awareness; rollback is forbidden.

## Phase 7 — verify AFTER (getMe ≠ alive)

`bot-getme + heartbeat:<signal>`:
- `getMe` — Telegram answers for any valid token (**necessary, not sufficient**);
- AND a **process-liveness heartbeat**: a log line printed **after** the update loop
  is established — e.g. grammY's `onStart` line (`@<bot> online`), or "…online via
  webhook" after `setWebhook` — within N seconds. **NOT** a pre-loop "starting…" line
  and **not** a bare `/health` that comes up before the loop: both can print over a
  bot that then crashes on startup (the exact false-"alive" this guard exists to stop).

A "delivered brief" / message-send is **observational only, never a gate** (too
stochastic) and must target a **test chat, never real subscribers**. UNKNOWN (no
heartbeat yet) → keep waiting to `verify_timeout`, then surface — never rollback.

`migration`: if the deploy doesn't run migrations (railway up + a `start` with no
migrate step), a schema diff must be `human-db-push-required` — railway-up of new
code against an unmigrated DB breaks silently.

## Phase 8–9 — terminal + record

`terminal: redeployed-alive` → verdict "redeployed + alive ✓" **only after the
heartbeat**, never on `getMe` alone. Changelog / tracker per recipe.

## Rollback

- `bot-api` (`surface-only`): surface + offer; the recoverable poll-conflict means no
  auto-revert urgency. Mechanics = re-`railway up` the prior good ref (checkout the
  prior tag/commit → `railway up`), **not** a main revert.
- `mtproto-session` (`forbidden`): surface only.

## Recipe location for a repo with no `*_META.md`

A standalone bot repo has no `*_META.md`. Put its `## Release
recipe` in the repo's auto-loaded entrypoint — its `CLAUDE.md` (or a `## Release
recipe` section in the README). The engine reads it from there.
