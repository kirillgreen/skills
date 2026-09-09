# adapters/automation.md — the `automation` kind

Applies when `recipe.kind: automation` — a scheduled job or standalone script the operator
runs (a launchd agent, a cron line, a sync/backup script). "Shipping" = update the
script + reload its scheduler + **verify it actually runs**. A job being *loaded* is
not proof it *works* — this is the automation analogue of "getMe ≠ alive" and
"200 ≠ live".

## Mechanism (declared per recipe)

- **launchd** (`~/Library/LaunchAgents/<label>.plist` + `launchctl`),
- **cron** (`crontab`),
- a **plain script** invoked on demand or by another trigger.

## Phase 2 — shippability

- The script source is committed (if it lives in a repo) — clean tree on the release
  ref. If it lives **outside** a repo (a scripts dir, a config dir, …), confirm the source
  on disk matches what will be deployed.
- `verify_before`: the script's own test / `bash -n` syntax check / a `--dry-run` if it
  supports one.

## Phase 5 — confirm

One "ship it". Most automations don't merge to `main` → **no guard-cross**. (If the
script lives in a repo that releases via merge, the merge rules apply — once, with the
behind-main check.)

## Phase 6 — release (per `recipe.release_steps`)

1. Deploy the updated script to its location.
2. Reload the scheduler: launchd → `launchctl bootout`/`bootstrap` (or `unload`+`load`);
   cron → reinstall the line. A script with no scheduler → nothing to reload.
**Care with launchd:** a bad plist can leave the job *unloaded* with no error surfaced
— verify it's loaded after (next phase).

## Phase 7 — verify AFTER (loaded ≠ ran)

- **Loaded:** `launchctl list | grep <label>` (or `crontab -l` shows the line).
- AND **actually ran / works** (the real net): a heartbeat — the job's output file
  mtime is recent, a last-run log line, exit-0 from a forced run, or the side-effect it
  produces (a synced file, a backup tarball). **`loaded` alone is NOT proof.**
- UNKNOWN (loaded but no run yet within the window) → surface, don't claim "alive".

## Phase 8 — terminal

`redeployed-alive` → "<label> loaded + verified-ran ✓" **only after the run signal**.
Loaded-but-not-yet-run → say so (UNKNOWN); never dress a merely-loaded job as working.

## Phase 9 — record

CHANGELOG / tracker per recipe — many automations have neither → `changelog: none`,
and no tracker prefix.

## Recipe — seeded via discover on first ship

There is **no seeded automation recipe yet** (automations vary — launchd sync
jobs, Raycast/`~/Scripts`, backup). The first real automation ship runs **discover
mode** (recon → propose a recipe → `--dry-run`, no irreversible step) and persists the
recipe to the automation's home (its repo's `CLAUDE.md`, or a `## Release recipe` next
to the script / in the relevant META). Key fields: `release_trigger`
(launchd-reload | cron | script), `verify_before` (syntax / test / dry-run),
`verify_live` (the loaded-check **plus** the run/heartbeat signal), `test_safety: n/a`,
`rollback: surface-only`, `terminal: redeployed-alive`.
