# adapters/android.md — the `android` kind

Applies when `recipe.kind: android`. Android **lands code by squash-merge to a
protected `main`** (like web), then ships to Google Play via a **signed release AAB**
uploaded to a Play track. The Play rollout/submit is a **human step**, and for an app
not yet set up, **signing + Play Console + listing are human-blocked**. Terminal
honesty: `built-upload-blocked` until the AAB actually reaches a Play track;
`uploaded-pending-submit` once it does. Never "live".

## Phase 2 — shippability

- Feature branch → PR → CI green → **squash-merge to protected `main`**. The
  behind-main fast-forward check **applies** (this merge is the squash-chain surface).
- `verify_before` = the **gradle gate** (assemble + unit tests + ktlint + detekt +
  Roborazzi screenshot verify).

## Phase 4 — verify BEFORE

Run the gradle gate exactly (including `:app:assembleRelease`, which exercises
release-DI / R8 minification). No staging → the gate IS the pre-merge net.

## Phase 5 — confirm

One authorization (SKILL Phase 5: the operator's `/ship` or trigger word, else "ship it"). The merge to `main` crosses the guard **once** (under it,
after the behind-main check). The AAB build / Play upload never cross the guard.

## Phase 6 — release

1. `gh pr merge <N> --squash --delete-branch` (`ALLOW_MAIN_MERGE=1` under the Phase-5
   authorization; `main` is protected).
2. Build the **signed release AAB**: `./gradlew :app:bundleRelease` — **BLOCKED** until
   a signing keystore is wired (`keystore.properties` / Play App Signing). The gate's
   `:app:assembleRelease` proves the release variant *compiles*; a *signed AAB* needs
   the keystore.
3. Upload the AAB to a Play **track** (internal/closed/production) via the Play
   Developer API / `bundletool` — **BLOCKED** until Play Console registration + the
   listing exist.

Until the blocked steps are lifted, the release **stops after the merge + gate** and
reports honestly — it does not pretend a Play release happened.

## Phase 7 — verify AFTER

- While `blocked_steps` cover the AAB/Play steps there is **no live remote surface to
  probe** → `verify_live: n/a`, and the verdict is the gate-green + merge-landed →
  terminal `built-upload-blocked`. (The engine must NOT claim "live"; the terminal
  carries the truth — `n/a` here is honest, not fail-open, *because* the terminal is
  `built-upload-blocked`.)
- When unblocked: `play-track:<track>:<versionCode>` — poll the Play API that the
  uploaded AAB (versionCode identity) is on the target track → terminal
  `uploaded-pending-submit` (Play review/rollout is human). Unreadable → NO-GO;
  still-processing → UNKNOWN.

## Phase 8 — terminal

`built-upload-blocked` → "merged to `main` + gate green; signed-AAB + Play upload
blocked on keystore + Play Console (human)". Once unblocked → `uploaded-pending-submit`.

## Phase 9 — record

CHANGELOG per recipe. Tracker → **stays in-progress** while `built-upload-blocked`;
"Pending Submit" once on a Play track. (Android "What's New" = Play listing release
notes — human, like the iOS Submit.)

## Blocked-steps honesty

List the human-blocked steps explicitly in `recipe.blocked_steps` (keystore / Play
Console / OAuth / listing). The verdict must **name what's blocked**, never imply a
Play release happened. This is the Android generalization of the iOS stop-at-Submit
discipline.
