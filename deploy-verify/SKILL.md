---
name: deploy-verify
description: >
  Deploy to staging/preview and prove it works before anything reaches users — runs
  pre-flight gates (types, tests, env, migrations, build), deploys, smoke-tests the
  live URL, diagnoses failures, and ends by writing a machine-readable verdict
  artifact that a release orchestrator can trust. Use for "/deploy-verify", "deploy
  and test", "deploy to staging", "verify deployment", "pre-flight check". Do NOT use
  for a plain git push with no verification, or for a production release (use /ship).
---

# /deploy-verify — Deploy and Verify Workflow

Pre-flight checks → deploy to staging/preview → smoke test → diagnose failures → report.

## Adapting this to your setup

- **"Project META"** below means whatever file your setup keeps per-project facts in
  — a `*_META.md`, a `CLAUDE.md`, a `README`. The skill needs three things from it:
  the deploy platform, the staging/preview URL pattern, and the list of endpoints
  worth smoke-testing. Anything that answers those works.
- **Platforms** (Railway, Vercel, Convex, Replit) are the ones wired here; the
  detection table is data, not logic — add a row for yours.
- **Step 6's verdict artifact is the contract with `/ship`.** If you use this skill
  standalone you can ignore it; if you use `/ship`, do not change the filename shape
  or the field names — `/ship` matches on SHA, `run_id` and timestamp, and a mismatch
  is treated as NO-GO by design.

## Instructions

### Step 0: Project & Platform Detection

Detect from cwd and project META file:

| Signal | Platform | Deploy Method | Preview URL |
|--------|----------|---------------|-------------|
| `railway.toml` or Railway in META | Railway | `railway up` or `git push` | `*.up.railway.app` |
| `vercel.json` or `.vercel/` | Vercel | `vercel deploy` | `*.vercel.app` |
| `convex/` directory | Convex | `npx convex deploy` | N/A (backend only) |
| Replit in META | Replit | `git push origin main` | Replit URL from META |

Read the project META to find:
- Production/staging URLs
- Health check endpoints
- Critical API routes
- Database type (Drizzle / Prisma)

### Step 1: Pre-Flight Checks

Run all checks and collect into a results table:

1. **TypeScript compilation:** `npx tsc --noEmit` — CRITICAL (must pass)
2. **Test suite (DB-safety gate FIRST):** Before running any DB-touching test,
   observe the **runtime driver connection host** the test process will actually use
   (resolve `DATABASE_URL`/equivalent *as the test config injects it* — an
   env-var-*presence* check fails open; a config can inject a prod `DATABASE_URL`
   directly). If that host is a forbidden prod host (`rlwy.net`, a Railway-internal
   host, the project's prod DB) with no safe `TEST_DATABASE_URL`/override actually
   wired into the test process, **ERROR — do not run** (name the cause). When invoked
   by `/ship` with a recipe, run the recipe's **exact** `verify_before` command;
   never fall back to an auto-detected `npm test`. Then run the framework's tests — CRITICAL
   *(Standalone behavior change: this gate may now ERROR a standalone `/deploy-verify`
   whose tests connect to a forbidden prod host — a safety win, not a regression.)*
3. **Environment variables:** Compare `.env.example` keys vs deployed config
   - Railway: `railway variables`
   - Vercel: `vercel env ls`
   - Convex: `npx convex env ls`
4. **Database migration status:**
   - Drizzle: `npx drizzle-kit check`
   - Prisma: `npx prisma migrate status`
5. **Build:** `npm run build` or `bun run build` — CRITICAL
6. **Secrets scan:** Run `secrets-leak-detector` agent on staged changes

**GATE:** If any CRITICAL check fails (tsc, tests, build), STOP and report. For non-critical (env gaps, pending migrations), warn and ask user whether to proceed.

### Step 2: Deploy to Staging/Preview

Based on detected platform:

- **Railway:** `railway up --environment staging` or push to PR branch for PR environment
- **Vercel:** `vercel deploy` (automatically creates preview URL, output includes it)
- **Convex:** `npx convex deploy --preview <branch-name>`

Wait for deployment URL to be live:
```bash
# Poll every 5s, max 120s
for i in $(seq 1 24); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DEPLOY_URL")
  if [ "$STATUS" = "200" ] || [ "$STATUS" = "301" ] || [ "$STATUS" = "302" ]; then
    break
  fi
  sleep 5
done
```

### Step 3: Smoke Test

For each endpoint, run a curl check:

```bash
# Health check
curl -s -w "\n%{http_code} %{time_total}s" "$DEPLOY_URL/api/health"

# Critical API endpoints (from META)
curl -s -w "\n%{http_code} %{time_total}s" "$DEPLOY_URL/api/..."
```

Validate:
- Response status code (expect 200)
- Response body has expected fields (basic JSON structure)
- Response time is reasonable (<5s)
- No error strings in response ("undefined", "ECONNREFUSED", "relation does not exist")

### Step 4: Diagnose Failures

If any smoke test fails, check common causes:

| Symptom | Likely Cause | Diagnostic Command |
|---------|-------------|-------------------|
| 502/504 | DNS not propagated or service not ready | Wait 60s, retry |
| 500 with "undefined" | Missing env var | `railway variables` / `vercel env ls` |
| 500 with "relation does not exist" | Unmigrated DB | `prisma migrate status` / `drizzle-kit check` |
| 500 with stack trace | Runtime error | `railway logs --tail 50` / `vercel logs <url>` |
| 429 | Rate limiting | Check API quotas |
| Connection refused | Service didn't start | Check build logs |

### Step 5: Report

Output a markdown report:

```markdown
## Deploy Verification Report

**Project:** [name] | **Platform:** [Railway/Vercel/...] | **URL:** [deployed URL]

### Pre-Flight
| Check | Status | Details |
|-------|--------|---------|
| TypeScript | PASS/FAIL | N errors |
| Tests | PASS/FAIL | N tests, N failures |
| Env Vars | PASS/WARN | Missing: KEY_NAME |
| Migrations | PASS/WARN | N pending |
| Build | PASS/FAIL | time |
| Secrets | PASS/WARN | N issues |

### Smoke Tests
| Endpoint | Status | Time | Notes |
|----------|--------|------|-------|
| /api/health | 200 | 340ms | OK |
| /api/... | 500 | 1.2s | Missing JWT_SECRET |

### Diagnosis (if failures)
[Root cause and fix recommendation]
```

### Step 6: Verdict artifact (deterministic machine contract for /ship)

The markdown report above is for humans. `/ship` must not grep narrative prose (an
LLM report is not a machine contract). So **also** end by writing a deterministic
verdict **file artifact**, written atomically (temp file → `mv`/rename), to a path
**unique per PR/session** so a parallel session can't read a stale or clobbered one.
**When invoked by `/ship`, it passes `--run-id=<nonce>` — use THAT exact run-id in the
path** so `/ship` reads exactly this file (a caller can't learn a callee-chosen nonce);
standalone, generate your own run-id:

```
<scratchpad-or-tmp>/deploy-verify-verdict.<repo>.<pr-or-branch>.<run-id>.json
```
```json
{
  "verdict": "PASS|WARN|FAIL|ERROR",
  "verified_sha": "<full SHA that was verified>",
  "branch": "<branch>",
  "run_id": "<unique nonce for this run>",
  "timestamp": "<ISO-8601>",
  "gates": { "tsc": "PASS", "tests": "PASS", "env": "WARN", "migrations": "PASS", "build": "PASS", "secrets": "PASS" },
  "smoke": { "<endpoint>": "PASS|FAIL" },
  "notes": "<short>"
}
```

`verdict` rules: `PASS` only if every CRITICAL gate passed and smoke is green;
`WARN` if green but with env-gap / pending-migration; `FAIL` if a CRITICAL gate or
smoke failed; `ERROR` if verification couldn't complete (incl. the DB-safety gate
firing). `/ship` trusts a `PASS` only after asserting `verified_sha` == the SHA it
is about to ship AND `timestamp` is within a recency window AND the path is this
run's; stale/mismatched/missing → NO-GO. Standalone runs write it too (harmless;
useful for audit).

## Troubleshooting

### Deployment timed out
**Cause:** Build taking too long or deployment stuck.
**Solution:** Check build logs (`railway logs` / `vercel logs`). Increase poll timeout if build is large.

### Health check returns 502
**Cause:** DNS propagation delay or service still starting.
**Solution:** Wait 60 seconds and retry. For Railway, check service health in dashboard.

### 500 after deploy but works locally
**Cause:** Environment mismatch — different env vars, missing DB migration, or wrong Node version.
**Solution:** Compare `railway variables` with local `.env`. Check `prisma migrate status`. Verify Node version in runtime config.

### Tests pass locally but endpoint fails
**Cause:** Tests mock external dependencies that fail in staging.
**Solution:** Check if staging has access to all required services (Redis, external APIs, etc.).

## Examples

### Example 1: a Railway-hosted web app
User says: `/deploy-verify`
1. Detects Railway from cwd + the project's META
2. Pre-flight: tsc ✅, vitest ✅, env vars ✅, drizzle check ✅, build ✅
3. Deploy: `git push` triggers Railway, polls PR environment URL
4. Smoke: `/api/health` 200, `/api/yachts` 200, `/api/search` 200
5. Report: all green

### Example 2: a Vercel app with a pending migration
User says: "deploy and verify"
1. Detects Vercel from cwd
2. Pre-flight: tsc ✅, tests ✅, build ✅, **prisma: 1 pending migration** ⚠️
3. Asks user: "1 pending Prisma migration. Apply before deploy?"
4. User confirms → runs migration → continues deploy

