# adapters/ios.md — the `ios` kind

Applies when `recipe.kind: ios`. iOS ships to the App Store via a **manual CLI
pipeline** (archive → export → upload, authenticated by the **ASC API key**) — no
Xcode UI, no computer-use, **never an Apple-ID password/2FA**. The final **Submit for
Review is a human step** (irreversible publish; the human writes the user-facing
"What's New"). The terminal is `uploaded-pending-submit`, **never "live to users"**.

## Phase 2 — shippability (iOS specifics)

- On the release ref (main or a release branch). If the change sits on a feature
  branch with a PR, Phase 6 lands it to main first — **the one guard-cross an iOS ship
  makes**, under the Phase-5 authorization — then archives main; the archive itself never
  touches main. That pre-archive merge is a real squash-merge to main, so it **must run
  the behind-main fast-forward check first** (SKILL Phase 2) — it carries the
  squash-chain risk (e.g. landing a long-lived Pro/paywall branch).
- `verify_before` (build + tests on the **pinned simulator** from the project META)
  green.
- Version: bump `MARKETING_VERSION` per recipe; **build# = max ASC build + 1** (check
  `/v1/builds?sort=-uploadedDate` — the repo's `CURRENT_PROJECT_VERSION` is often
  stale/behind ASC).
- **Released baseline (R9) — read it from ASC, never from commit dates.** iOS
  builds are routinely cut from a feature branch *before* its PR lands, so a
  merge commit dated after an upload can already be inside that build. Do:
  1. `GET /v1/apps/<id>/appStoreVersions` → the newest `READY_FOR_SALE` version.
  2. `GET /v1/appStoreVersions/<id>/appStoreVersionLocalizations` → its
     `whatsNew`. That text is the authoritative statement of what users last got.
  3. Reconcile against the changelog's last released heading. Disagreement is a
     finding to report (drift, or a build shipped off-branch) — not something to
     silently resolve by preferring git.

  A worked example — an iOS app at 1.5.11: build 216 uploaded 2026-08-03, the
  APP-549 merge commit dated 2026-08-04, and 1.5.10's `whatsNew` described that
  very fix. Git said unreleased; ASC said shipped; ASC was right.
- **No ASC app for this bundle** → archive+validate only, no upload (the ASC API can't
  create apps — `POST /v1/apps` 403s); terminal → **`built-upload-blocked`** ("archive
  validated; ASC app not set up — a human creates it").

## Phase 4 — verify BEFORE

iOS has no staging → the **pre-archive build + test on the pinned sim IS the gate**;
the post-upload net is "build VALID in ASC". Run `recipe.verify_before` exactly.

## Phase 5 — confirm

One authorization (SKILL Phase 5). If landing a feature branch to main, that merge crosses the guard
(under it). The archive+upload does not.

## Phase 6 — release (archive → export → upload via the ASC key)

Credentials from your secret store (`ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_PATH`) —
**never** an Apple-ID password, **never** computer-use (Xcode is click-only, the
browser is read-only).
1. `xcodebuild archive -scheme <S> -configuration Release -destination
   'generic/platform=iOS' -archivePath … -allowProvisioningUpdates
   -authenticationKeyPath $ASC_KEY_PATH -authenticationKeyID <id>
   -authenticationKeyIssuerID <issuer>` (auto-creates the Distribution cert/profile).
2. `xcodebuild -exportArchive` with an ExportOptions.plist (`method=app-store-connect`,
   `teamID`, `signingStyle=automatic`, `manageAppVersionAndBuildNumber=false`) → the
   App-Store-signed `.ipa`.
3. `xcrun altool --validate-app` then `--upload-app -t ios -f <ipa> --apiKey <id>
   --apiIssuer <issuer>`.
4. **ASC REST** (JWT ES256 — use a python with PyJWT; on this Mac `/usr/bin/python3`
   has it, brew python may not; **verify `python3 -c 'import jwt'` before first ship**):
   poll `/v1/builds` until `processingState==VALID`, `POST
   /v1/appStoreVersions` (versionString), `PATCH .../relationships/build`.
Resubmit after a REJECTED version → **rename** (`PATCH` versionString), don't delete
(409 if it has builds).

## Phase 7 — verify AFTER (`asc-build-valid`)

`asc-build-valid:<build#>` — poll `/v1/builds?filter[app]=<appId>&filter[version]=<v>`
until **the build THIS run uploaded** (build# identity) is `processingState==VALID`.
Still processing past `verify_timeout` → **UNKNOWN** (surface, don't claim shipped);
proof unreadable or build `INVALID` → **NO-GO**. This is NOT "live to users" — App
Store review + Submit are human/async.

## Phase 8 — terminal

`terminal: uploaded-pending-submit` → verdict "build <n> VALID in ASC, version prepared
— **Submit for Review is yours**". Never print "live".

## Phase 9 — record

- **Draft** the user-facing "What's New" + the in-app `whatsnew.json` slide (+ imageset
  1170×1435, light+dark) for the human's approval — **don't auto-finalize** (see the
  project's whatsnew workflow).
- ASC version notes: `whatsNew` + `promotionalText` on EVERY locale. **ASC does NOT
  auto-copy `promotionalText` when a version is created via the API** (localizations
  arrive with the field empty — learned the hard way on a 1.5.10 release) — read the prior version's
  per-locale values and PATCH them onto the new version's localizations explicitly;
  the project META may pin a canonical fallback text.
- CHANGELOG per recipe. **Tracker → "Pending Submit" / in-review, NOT Done** (Submit is
  human).

## Stay in lane

The human owns: Submit for Review (irreversible), the user-facing What's New copy, and
creating a not-yet-existing ASC app. `/ship` stops at "uploaded + VALID + version
prepared + notes drafted".
