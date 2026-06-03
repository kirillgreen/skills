---
name: tdd
description: >
  Spec-Driven TDD with a strict Red-Green-Refactor cycle using context-isolated
  subagents. Every feature starts with a structured spec; tests are generated from
  numbered acceptance criteria, with post-cycle three-dimension verification
  (Completeness + Traceability + Coherence), severity-tiered findings
  (CRITICAL/WARNING/SUGGESTION), and a spec-defect escape hatch that halts when the
  spec is internally contradictory or unimplementable instead of silently encoding it.
  Use when the user says "/tdd", "test first", "use tdd", "tdd approach",
  "write tests first", or when implementing new features/functionality.
  Trigger phrases: "implement", "add feature".
  Do NOT use for bug fixes without new tests, documentation changes,
  configuration-only changes, or refactoring existing code without new behavior.
---

# /tdd -- Spec-Driven Test-Driven Development

Enforce strict Red-Green-Refactor cycle with context-isolated subagents.
Every feature starts with a **specification** — numbered acceptance criteria that drive test generation and final verification.

Flow: **Spec → RED → GREEN → REFACTOR → Verify**

## Mode Behavior Matrix

The cycle has two modes, set during Step 1. Each step below behaves differently per mode:

| Step | `locked-spec` mode | `prompt-only` mode |
|------|--------------------|--------------------|
| Step 1 Spec phase | Find existing or write new spec; lock at 1c | User declines spec; pass raw feature requirement instead |
| Phase 1 RED inputs | `Locked spec` + AC-traceability instruction | Raw feature requirement + "name tests after behavior, no AC- prefix" |
| Phase 1 spec coverage check | Compare tests vs locked spec criteria | **SKIPPED** (no spec) |
| Phase 2 spec_defect signal | Implementer can raise `spec_defect: true` | **DISABLED** (no spec to be defective) |
| Step 4 Spec Verification | All three dimensions run | **SKIPPED** (no spec to verify against) |
| Final Report Spec line | "[N] criteria defined" | "prompt-only mode" |
| Final Report Verification block | Three-dim breakdown | "Verification: skipped (prompt-only mode)" |

**Maintenance note:** every mode-specific branch in this runbook is tagged `<!-- mode-fork -->` in the source. Grep that tag to enumerate all branches. If this matrix grows past ~8 rows or the branches become hard to keep in sync, that's the signal to split `/tdd-prompt-only` into its own skill.

## Severity Levels

Every check in this skill emits findings at one of three tiers:

- **[CRITICAL]** — blocks the phase transition by default. May be **acknowledged-overridden** only with explicit user confirmation, in which case the finding still appears in the final report tagged `(acknowledged)`. In Step 4 (the last phase, no next transition to block), CRITICAL findings do not stop the cycle from being reported, but they mandate a follow-up cycle and are listed prominently in the report.
- **[WARNING]** — should fix. Cycle continues; findings appear in the final report.
- **[SUGGESTION]** — informational. Surfaced once at the end, never blocks.

The final report tallies counts by tier. CRITICAL gates phase transitions (with optional acknowledged override); WARNING and SUGGESTION are advisory.

## Findings Ledger

A single mutable list `findings_ledger` is the source of truth for all findings emitted during the cycle. The Final Report MUST be generated from this ledger, not recounted from memory.

**Schema (one entry per finding):**

```yaml
- id: "F-001"                    # sequential, never reused
  tier: "CRITICAL"               # CRITICAL | WARNING | SUGGESTION
  phase: "post-red-lint"         # post-red-lint | post-green | post-refactor | step-4a | step-4b | step-4c | phase-3.5 | step-0.5 | step-1b
  check: "test-isolation"        # short identifier for the check that fired
  message: "Test imports utils/x.ts which doesn't exist"
  file: "src/utils/__tests__/x.test.ts:12"   # if applicable
  acknowledged: false            # true once the user explicitly approves the override
  acknowledged_reason: null      # user's stated reason if acknowledged
  acknowledged_at_phase: null    # phase where the override was approved
  carried_from_strike: 1         # null | 1 | 2 — for entries that survive a spec-defect cycle restart
```

**Append rules:**

- Every emitted `[CRITICAL]`, `[WARNING]`, `[SUGGESTION]` finding gets one ledger entry. No exceptions.
- IDs are sequential within a cycle, starting at F-001. Never renumber.
- Severity tier and check identifier are immutable once written.
- `acknowledged: true` is set ONLY when the user explicitly confirms an override (e.g., accepts an out-of-scope file). Never auto-flip.
- **Step 0.5 intent-check acknowledgements** also go in the ledger as `tier: "SUGGESTION"`, `check: "intent-check-bypass"`, `phase: "step-0.5"`, `acknowledged: true`, `acknowledged_reason: <user's reason or "user chose (b) proceed">`. This gives bug-fix-routed-acknowledgements a record so they appear in the Final Report.
- **Cycle restart stale-path scrub:** when a spec-defect strike discards a test file, on strike-N entry the orchestrator strips from the ledger any entry whose `file:` path references the discarded test file path (and whose `phase` is `post-red-lint`). Cross-phase findings (Post-GREEN, Step 4, Phase 3.5) are NOT stripped — they describe state that may persist. Stripped entries are logged as `(stripped on strike N — file discarded)` for audit but not surfaced in the Final Report.

**Cycle restart rules (spec-defect strike 1 → 2 transition):**

- When a `spec_defect: true` discards the test file and restarts RED, the ledger is **preserved** — not reset.
- Existing entries gain `carried_from_strike: 1` so they're distinguishable in the Final Report.
- New entries on strike 2 use the next sequential ID after the last strike-1 entry.

**Final Report rule:**

- The Final Report's `Findings: N CRITICAL · N WARNING · N SUGGESTION` line is computed by `count by tier` over the ledger.
- The `If any CRITICAL: list each with file:line and acknowledged-status` block is computed by `filter tier=CRITICAL` over the ledger.
- If the ledger and report disagree, the ledger wins.

**Cross-cycle ledger (acknowledged-CRITICAL debt):**

Project-level file `<project_root>/.tdd/debt.md` accumulates **acknowledged CRITICALs** across all `/tdd` cycles in the project. Each entry is one line: `YYYY-MM-DD <feature> <check>: <message> (reason: <user-supplied>)`.

**Read step (cycle start):**
1. Check whether `<project_root>/.tdd/debt.md` exists.
2. If missing → treat count as 0, do NOT create the file yet, do NOT print an error.
3. If present → count non-empty non-comment lines; surface in preamble: `"Note: this project has N previously-acknowledged CRITICAL findings — see .tdd/debt.md."` Suppress preamble if count is 0.

**Write step (cycle end, only for completed cycles with acknowledged CRITICALs):**
1. Filter the findings_ledger to entries where `tier == "CRITICAL"` AND `acknowledged == true`.
2. If zero such entries → skip the write step entirely.
3. Otherwise: ensure `<project_root>/.tdd/` directory exists (`mkdir -p`); create `debt.md` if missing.
4. Append one line per qualifying ledger entry, formatted: `<YYYY-MM-DD> <feature_name> <check>: <message> (reason: <acknowledged_reason>)`.
5. Do NOT write debt entries for aborted cycles (Variant B) — they didn't complete with shipped code.
6. Do NOT write debt entries for Step 0.5 intent-check-bypass entries — they're not CRITICAL.

This write step is what prevents normalization-of-deviance: every acknowledged CRITICAL leaves an audit trail that future cycles surface in their preamble.

## Instructions

### Step 0: Stack Detection

Detect the test framework from project files:

| Signal | Framework | Run Command |
|--------|-----------|-------------|
| `vitest.config.*` or vitest in package.json | Vitest | `npx vitest run {file} --reporter=verbose` |
| `Package.swift` with test targets | Swift Testing | `swift test --filter {TestSuite}` |
| `*Tests/` Xcode dirs with XCTest imports | XCTest | `xcodebuild test -scheme {scheme} -only-testing:{target}/{class}` |
| `bun test` in package.json scripts | Bun | `bun test {file}` |

If **no test framework found** — STOP. Tell the user:

> No test framework detected in this project.
> Recommended setup: [suggest based on project stack — Vitest for Node/Vite, Swift Testing for iOS, Bun test for Bun projects].
> Please set up testing infrastructure before using TDD.

Do NOT auto-install dependencies.

### Step 0.5: Intent Check (bug fix vs feature)

`/tdd` is for **new features**, not bug fixes. If the user is reporting a bug, they should use `/bugfix` (the `bugfix-pipeline` skill), which traces the active code path before fixing.

**Trigger:** if the user's feature_requirement contains any of these keywords or framings:
- "fix", "bug", "broken", "regression", "doesn't work", "stops working", "crashes", "throws", "wrong output"
- "the [X] is wrong/broken/buggy"
- An existing function/feature name being reported as misbehaving

**Action:** ask the user once:
> Your prompt looks like a bug report rather than a new-feature spec. `/tdd` is optimized for new functionality (Spec → RED → GREEN). Bug fixes are better handled by `/bugfix`, which traces the existing code path first. Which is this?
> (a) Bug fix — switch to `/bugfix`
> (b) New feature that happens to use bug-fix-shaped vocabulary — proceed with `/tdd`

**If user picks (a) — switch to /bugfix:**
1. Print exact invocation: `Suggested: /bugfix <original user prompt verbatim>`
2. Emit Final Report Variant B with `Reason: "intent-check: routed to /bugfix"` and `NEXT: "Run the suggested /bugfix invocation above. No code or tests were created by /tdd."`
3. Stop. Do NOT invoke any subagent.

**If user picks (b) — proceed with /tdd:**
1. Append a ledger entry: `tier: SUGGESTION`, `check: "intent-check-bypass"`, `phase: "step-0.5"`, `acknowledged: true`, `acknowledged_reason: "user confirmed this is a new feature despite bug-fix vocabulary"`.
2. Continue to Step 1.

**Do not auto-route.** A spec that mentions "fix the validation logic" might be a new feature requiring revised validation. The user decides.

### Step 1: Spec Phase

The spec is the **source of truth** for the entire TDD cycle. Every test must trace back to a spec criterion. Every criterion must be verified at the end.

#### 1a. Find or Receive Spec

Check for existing specification in this priority order:

1. **User provided a doc reference** (via `@file` or explicit path) — read it, extract acceptance criteria
2. **Search project docs** for relevant specification:
   - Scan project root for documentation directories: `docs/`, `Documentation/`, `Documentation.docc/`, plus `*.md` at the root level
   - Check for project-level META files: `*_META.md`, `CLAUDE.md`
   - If a doc index exists in any of the above (commonly `INDEX.md`), read it first
   - Grep doc filenames and indices for keywords matching the feature topic
3. **No spec found** — proceed to 1b (write spec)

If existing doc is found but lacks structured acceptance criteria, extract them into the spec format below.

#### 1b. Write Spec (when no spec exists)

Write a structured spec and present it to the user for confirmation.

**Spec format (what to write — fill in the bracketed sections, don't copy this guidance text into the spec itself):**

> **Description guidance** (write this into the spec body, do NOT include this guidance line): 1-4 paragraphs of 40-80 words each describing the system behavior the user wants and the approach for implementation.
>
> **Section guidance:**
> - Each AC/EC/ERR is one bullet. One behavior per bullet. Concrete inputs and expected outputs, no "etc." or "and similar".
> - 3-7 ACs total, plus 1-3 ECs and 1 ERR when applicable.
> - Constraints = technical limits (performance, compatibility, security).
> - Out of Scope = what this feature does NOT do (prevents gold-plating).

```markdown
## Spec: [Feature Name]

[1-4 paragraphs describing system behavior and approach]

### Acceptance Criteria
- AC-1: [behavior, concrete]
- AC-2: [behavior, concrete]
- AC-3: [behavior, concrete]

### Edge Cases
- EC-1: [boundary value, empty input, etc.]

### Error Cases
- ERR-1: [what happens when things go wrong]

### Constraints
- [technical constraint]

### Out of Scope
- [what this feature does NOT do]
```

**Concrete example** (what a good filled-in spec looks like):

```markdown
## Spec: File size formatter utility

A pure utility that converts byte counts to human-readable strings ("1024 → 1 KB"). Used in the upload UI to show file sizes in dialogs and tooltips. No formatting locale support in v1.

### Acceptance Criteria
- AC-1: formatFileSize(1024) returns "1 KB"
- AC-2: formatFileSize(1048576) returns "1 MB"
- AC-3: uses binary units (1024-based, not 1000-based decimal)

### Edge Cases
- EC-1: formatFileSize(0) returns "0 B"

### Error Cases
- ERR-1: formatFileSize(-1) throws RangeError

### Constraints
- Pure function, no I/O, no global state
- English output only (no Intl in v1)

### Out of Scope
- Localized output (deferred to v2)
```

**Rules for writing criteria:**
- Each criterion must be **independently testable** (one behavior = one criterion)
- Use concrete values in examples: "formats 1024 bytes as '1 KB'" not "formats bytes nicely"
- Total: 3-7 acceptance criteria + 1-3 edge cases + 1 error case (same as test count target)
- Prefix with AC/EC/ERR for traceability

**Spec Quality Check — run before presenting to user:**

Validate each criterion against DETAIL:
- **D**eterministic: Could two developers disagree on the expected assertion?
- **E**xample-based: Does it include concrete input→output pairs?
- **T**estable in isolation: Can it be verified without other criteria?
- **A**tomic: Does it contain "and" joining two behaviors? → split
- **I**nput-complete: Are all preconditions explicit?
- **L**imit-specified: Are boundaries enumerated, not implied?

Grep spec text for smell patterns:
- Subjective language: "fast", "robust", "efficiently", "properly", "handle", "manage"
- Open-ended lists: "etc.", "and so on", "and more"
- Comparatives without baseline: "faster", "better", "more reliable"
- Negative-only: "should not X" without saying what SHOULD happen
- Compound criteria: "X and Y" in a single AC → split into AC-N and AC-N+1

If smells found → fix them before presenting to the user.

**Page-Level AC Detection** — find criteria that unit tests cannot truly verify.

Some ACs describe runtime page behavior (server rendering, client hydration, browser navigation, cross-tab state) that unit tests can only approximate. The `/tdd` cycle's static checks (RED tests, Phase 3.5 build, Traceability grep) can all pass while the actual feature is broken at the browser level. This was the RAD-207 lesson: "GET /url renders X" passed every gate, but cold-load `useSearchParams()` returned empty params and the UI rendered the default state.

Scan every AC/EC/ERR for these page-level trigger phrases:

- `GET /url` / `navigate to` / `open in (a new tab|browser)` / `deep-link`
- `at mount` / `on (initial|first) (render|paint|load)` / `cold (load|start)`
- `no (flicker|flash)` / `before hydration` / `during SSR`
- `browser (back|forward|reload|refresh)` / `history (entry|stack)`
- `shareable` / `bookmarkable` / `round-trip` (in a URL/state context)
- `copy URL` / `paste in (new tab|fresh session)`
- `page reload preserves` / `survives refresh`

For each matched AC — emit a finding and surface it at lock time:

> **[WARNING] AC-N is page-level**: "[verbatim text]". Trigger phrase: "[matched substring]".
> Unit tests with mocked `useSearchParams`/`useRouter` will PASS even if the real Server Component → Client hydration path is broken (the RAD-207 failure mode). Phase 3.5 build success ≠ feature works in the browser.
>
> Choose one before locking the spec:
> - **(a)** Add E2E test coverage in this cycle. Specify framework (Playwright/Cypress/etc.). The test-writer agent will include an E2E test file in RED.
> - **(b)** Acknowledge that unit tests + Phase 3.5 are insufficient verification. Final Report's NEXT line will mandate browser-side verification (`/real-browser` or manual UI check) before merge. Cycle still completes; the page-level ACs are flagged as `unverified-at-cycle-end` in the ledger.
> - **(c)** Re-scope the AC to a unit-testable form (e.g., rewrite "GET /url renders X" as "given URLSearchParams Y, hook returns state Z"). Often the right move when the underlying logic is the real concern.

Record user choice in cycle state as `page_level_ac_resolution: "e2e-added" | "acknowledged" | "rescoped" | "none"` (`none` only when no page-level ACs were detected). Append findings to the ledger with `tier: WARNING`, `check: "page-level-ac"`, `phase: "step-1b"`. If user picks `acknowledged`, mark each finding `acknowledged: true` with reason.

**Present the spec to the user and wait for confirmation before proceeding.**

If user modifies the spec — incorporate changes. If user says "proceed" — lock the spec.

<!-- mode-fork -->
**Prompt-only escape:** If the user says "skip the spec", "prompt-only", "just code it", or otherwise declines a structured spec, accept prompt-only mode:
- Set `spec_traceability: "prompt-only"`
- Skip Step 1c (no `locked_spec`)
- Pass the user's raw feature requirement to the test-writer in place of the locked spec
- Skip Step 4 (Spec Verification) — note "prompt-only mode" in the Final Report

Use prompt-only when the feature is small enough that writing a structured spec adds more friction than value (e.g., a one-off animation, CSS tweak, or developer utility). Phase Violations rule "NEVER write tests before spec is confirmed" is satisfied by the user's explicit prompt-only choice.

#### 1c. Locked Spec

After user confirmation, the spec is **locked** for this TDD cycle. Store the full spec text as `locked_spec` — it will be passed to the test-writer and used for final verification.

The locked spec contains:
- Numbered criteria (AC-1, AC-2, ... EC-1, ... ERR-1, ...)
- Total criterion count (for verification tracking)

### Phase 1: RED -- Write Failing Tests

Invoke `tdd-test-writer` agent via Task tool with `subagent_type: "tdd-test-writer"`.

The exact agent inputs depend on `spec_traceability` mode (see Step 1b). The two modes share most inputs but differ on traceability instructions:

<!-- mode-fork -->
**Pass to agent (locked-spec mode — `spec_traceability: "spec-based"`):**
- Feature requirement (from user's prompt)
- **Locked spec** (full text with numbered criteria)
- Project path
- Test framework name and run command (from Step 0)
- **Traceability instruction:** "Each test MUST reference its spec criterion in the test name or description (e.g., 'AC-1: formats bytes to human-readable string'). Every AC/EC/ERR criterion must have at least one corresponding test. Output tests in priority order: happy path AC first, then edge cases EC, then error cases ERR."

**Pass to agent (prompt-only mode — `spec_traceability: "prompt-only"`):**
- Feature requirement (from user's prompt — passed in place of locked spec)
- Project path
- Test framework name and run command (from Step 0)
- **Traceability instruction:** "Name each test after the behavior it verifies. No AC- prefix required (no spec to trace to). Pick 3-7 behaviors that cover the feature's happy path, 1-3 edge cases, and 1 error case if applicable."

**Test-level hint** (both modes — add if keywords detected in feature requirement or locked spec):
  - If mentions "endpoint", "API", "route", "HTTP" → add: "Write integration-style tests. Use Supertest/MSW if available in the project."
  - If mentions "user flow", "journey", "workflow" → add: "Consider E2E-level tests if the project has Playwright."
  - Default (no keywords): unit tests (no extra instruction needed)

**Receive from agent:**
- Test file path
- Test failure output (stderr/stdout proving tests fail)
- Summary: what each test verifies, mapped to spec criteria
- Spec traceability: list of which criteria are covered by which tests

**GATE: Do NOT proceed to Phase 2 until test failure is confirmed in the agent's output.**

If agent returns success (tests pass) — something is wrong. The tests should fail because the feature doesn't exist yet. Ask the agent to rewrite tests that cover new behavior.

<!-- mode-fork -->
**Spec coverage check** (skip entirely in prompt-only mode — there is no spec to compare against):

Read the agent's structured `criteria_coverage` field (a map of criterion ID → test name) directly — do NOT re-parse the prose `summary` text. Compute missing criteria as: locked spec's `{AC-*, EC-*, ERR-*}` set MINUS keys present in `criteria_coverage`.

If the set of missing criteria is non-empty — warn the user:

> Spec criteria without tests: [list missing criteria]
> (a) Re-invoke test-writer to add missing tests
> (b) Accept partial coverage and proceed

Wait for user decision. If user picks (a), re-invoke `tdd-test-writer` with instruction: "Add tests for ONLY these missing criteria: [list]. Do NOT rewrite, rename, or reorder existing tests in this file — append the new tests at the bottom."

### Post-RED Lint

Before proceeding to GREEN, verify test quality. Each finding is tagged with its severity tier.

1. **Over-mocking check** [WARNING]: If the feature targets a pure module (`utils/`, `lib/`, `helpers/`, `domain/`, `models/`), grep the test file for mocking patterns:
   - TypeScript: `vi.mock`, `vi.spyOn`, `jest.mock`, `jest.spyOn`
   - Swift: `Mock`, `Stub`, `@Mock`

   If mocking found in a pure-module test — emit:
   > "[WARNING] Test for pure utility uses mocking. Consider testing via inputs->outputs instead. Proceed anyway?"

   Wait for user confirmation before continuing.

2. **Test isolation check** [CRITICAL]: Grep the test file's import paths. If any imported module doesn't exist on disk — the test fails on import errors, not assertions. This is CRITICAL because the RED gate is meaningless: the test isn't proving the feature is missing, it's failing on a broken import. Emit:
   > "[CRITICAL] Test imports [path] which doesn't exist. Tests will fail on missing module, not assertion mismatch. Re-invoke test-writer to add stubs?"

   If user says yes — re-invoke `tdd-test-writer` with instruction to create minimal stubs (empty exports) for imported modules. If user explicitly acknowledges the override (per Severity Levels, Step `Severity Levels`) — record the acknowledgement and continue (the CRITICAL finding remains in the final report tagged `(acknowledged)`).

3. **Assertion strength check** [WARNING]: Grep the test file for weak-only assertion patterns. The test-writer agent performs its own "What bug would this miss?" self-review; this step catches what the agent may have missed. Patterns to flag:
   - TypeScript: tests asserting only via `toBeDefined()`, `toBeTruthy()`, `not.toBeNull()`, `not.toBeUndefined()`, OR only via loose comparisons like `> 0`, `!== null`, `.length` without an exact expected value
   - Swift: tests asserting only via `#expect(result != nil)`, `XCTAssertNotNil`

   If a test has NO exact-value assertion — emit:
   > "[WARNING] Test [name] has only weak assertions. Consider asserting specific values."

4. **Implementation leakage check** [SUGGESTION]: Grep test file for references to private/internal names (`_private`, `.__`, `internal`, `#private`). If found — emit:
   > "[SUGGESTION] Test references internal/private name [name]. Consider testing through the public API instead."

5. **Mock count check** [SUGGESTION]: Count mocking calls (`vi.mock`, `vi.spyOn`, `jest.mock`, `Mock(`, `Stub(`) in the test file. If >3 mocks — emit:
   > "[SUGGESTION] Test uses [N] mocks. Consider whether an integration test would be more appropriate."

### Phase 2: GREEN -- Make Tests Pass

**Pre-GREEN: Define implementation scope**

Analyze the test file to determine expected implementation scope:
1. Extract project-local import paths from the test file (skip test framework imports like `vitest`, `@testing-library`, `XCTest`, `Testing`)
2. Check feature requirement for additional files mentioned
3. Build an allowed-files list:
   ```
   Implementation scope:
   - src/utils/formatFileSize.ts (new — imported by test)
   - src/types/file.ts (modify — type used in test)
   ```

Invoke `tdd-implementer` agent via Task tool with `subagent_type: "tdd-implementer"`:

**Pass to agent (typed inputs per `tdd-implementer.md` Input schema):**
- `test_file_path`: absolute path to the failing test file (from Phase 1)
- `feature_requirement`: brief description (1-2 sentences)
- `test_run_command`: e.g. `"npx vitest run {file}"`
- `implementation_scope`: structured array `[{path: string, action: "create" | "modify"}]` derived from the test file imports + feature requirement. Example:
  ```yaml
  implementation_scope:
    - {path: "src/utils/formatFileSize.ts", action: "create"}
    - {path: "src/types/file.ts", action: "modify"}
  ```
  This is the typed field the agent reads; do NOT pass scope as prose in the prompt body.
- `mode`: literal string `"spec-based"` or `"prompt-only"` — explicit so the agent's Step 3.5 can branch. <!-- mode-fork -->
- `locked_spec` (spec-based mode only): the locked spec text as input to the agent's Step 3.5 trigger detection.

**Receive from agent (matches `tdd-implementer.md` Output schema):**
- `files_modified`: array of `{path, action: "created" | "modified", description}`
- `test_success_output`: required when `status: complete`; empty when `status: spec_defect`
- `summary`: implementation summary (or "no implementation attempted — spec_defect" if escalating)
- `new_dependencies`: any new packages noted but NOT installed
- `spec_defect`: boolean
- `spec_defect_reason`: required when `spec_defect: true`
- `status`: `"complete" | "failed" | "spec_defect"`

**Invariant:** `status: "spec_defect"` ⇔ `spec_defect: true`. If you receive `status: "spec_defect"` with `spec_defect: false` (or vice versa), treat it as agent error and surface to the user. Branch routing decisions read `status` first, then `spec_defect` as the reason carrier.

**Post-GREEN validation:**
1. **Scope check** [CRITICAL]: Verify all `files_modified` are within the defined scope. If implementer touched files outside scope — emit `[CRITICAL]` with the list of out-of-scope files and ask the user to accept or revert. If user accepts → record explicit acknowledgement, finding remains in final report tagged `(acknowledged)`. If user rejects → revert out-of-scope changes and re-run GREEN.
2. **Test integrity** [CRITICAL]: Verify no test files were modified. If any test file was modified during GREEN — emit `[CRITICAL]` and revert/re-run. This finding is **not** acknowledged-overridable (existing hard rule "NEVER modify test files during GREEN").
3. **Import scan** [WARNING]: Grep newly created/modified files for imports. Emit `[WARNING]` if any new file imports:
   - Test utilities (`vitest`, `@testing-library`, `XCTest`, `Testing`)
   - Unrelated feature modules not in the implementation scope

**GATE: Do NOT proceed to Phase 3 until ALL tests pass AND scope validation passes (or user-acknowledged the scope override).**

**Spec-defect handling (auto-route, independent of iteration count):**

If agent returns `spec_defect: true` at any point — even on the first attempt — do NOT enter the iteration loop and do NOT show the post-5-attempts menu. Auto-route as follows:

1. Surface the implementer's reason to the user.
2. **Discard the current test file:** delete it with `rm <test_file_path>`. Strip stale Post-RED-Lint ledger entries that reference this path (per Findings Ledger "Cycle restart stale-path scrub" rule).
3. **Return to Phase 1b** (Write Spec) seeded with: (a) the current locked spec text, (b) the implementer's defect reason, (c) instruction to the user: "The implementer flagged a spec defect. Revise the spec to resolve it." When the user finishes editing, re-lock at Phase 1c.
   - When re-invoking `tdd-test-writer` for strike-N RED, pass instruction: "Previous test file at `<discarded path>` was discarded on strike N-1. Write a fresh test file from the revised spec — do NOT attempt to read or update the discarded file."
4. After the revised spec is re-locked, restart RED with the fresh spec.
5. **2-strike bound:** if `spec_defect: true` is raised twice in the same `/tdd` cycle, abort and escalate to the user with both reasons. Discard the second-attempt test file before escalating. Do NOT auto-loop a third time — the spec is fundamentally ambiguous and needs human resolution. Use the Aborted Final Report template (see Final Report section).
6. **Strike counter scope:** the counter `spec_defect_strikes` persists for the entire `/tdd` cycle. It increments on every `spec_defect: true` signal, including (d) re-classifications from the iteration menu below. It does NOT reset between menu loops. Initial value = 0 at cycle start.

**Iteration loop (test-failure-driven, not spec-driven):**

The agent runs its own 5-attempt internal fix loop (see `tdd-implementer.md` Step 4). When that budget is exhausted without spec_defect, the agent returns `status: "failed"`. The orchestrator does NOT re-invoke the agent for more attempts — there is no orchestrator-side outer loop. Instead, on `status: "failed"`:
1. Re-run the test command to get current pass/fail breakdown (agent may not return per-test results)
2. Report: "Partial progress: X/Y tests passing. Failing: [list]"
3. Ask user:
   - (a) Accept partial — proceed to REFACTOR with passing tests, follow-up cycle for rest
   - (b) Simplify/split the failing tests and retry RED for them
   - (c) Abort cycle entirely
   - (d) Re-classify as spec defect — increment `spec_defect_strikes` and invoke "Spec-defect handling" above (subject to the 2-strike bound)

Choose (d) when failures cluster around a single criterion that turns out to be ambiguous or self-contradictory. Choose (b) when the criterion is clear but tests are over-specified.

**Note** [SUGGESTION]: When the project has mutation testing infrastructure (Stryker, mutmut), consider running it post-GREEN to verify test effectiveness.

### Phase 3: REFACTOR -- Improve Code

Invoke `tdd-refactorer` agent via Task tool with `subagent_type: "tdd-refactorer"`:

**Pass to agent:**
- Test file path
- Implementation file paths (from Phase 2)
- Test run command
- **Refactoring guideline:** "Check dependency directions — lower layers must not import from higher layers."

**Receive from agent:**
- Changes made + test success output, OR
- "No refactoring needed" + reasoning

**Post-REFACTOR validation:**

1. **Tests still pass** [CRITICAL]: existing gate. If any test fails after refactor — emit `[CRITICAL]` and revert.
2. **Dependency direction check** [SUGGESTION] (TypeScript/Node projects only — skip for Swift):
   For each modified file, verify its imports follow the project's layer direction:
   - `utils/`, `lib/` → should not import from `services/`, `routes/`, `components/`
   - `services/` → should not import from `routes/`, `handlers/`, `pages/`
   - `models/`, `types/` → should not import from anything except other types/models

   If violations found — emit `[SUGGESTION]` (may be intentional).

### Phase 3.5: Final Quality Gate (Orchestrator)

After REFACTOR completes and before Spec Verification, run the full quality gate
using the project's actual tooling. This catches regressions that `--changed` missed.

**Detect package manager:** check for `bun.lock`/`bun.lockb` → use `bunx`, otherwise `npx`.

**Run these checks sequentially:**

1. **Full test suite** — ALL tests, not just targeted:
   - Vitest: `npx vitest run` (or `bunx vitest run`)
   - Bun: `bun test`
   - Swift: `swift test`

2. **Type check** (TypeScript projects only):
   - `npx tsc --noEmit` (or `bunx tsc --noEmit`)

3. **Lint** — only if a `lint` script exists in `package.json`:
   - `npm run lint` (or `bun run lint`)
   - Skip silently if no lint script. Do NOT install or configure a linter.

4. **Build** (Next.js projects only):
   - `npx next build` (or `bunx next build`)

**GATE: Tests + type check + build must all pass. Lint is advisory (warn but don't block).**

On pass: `touch .tdd-gate-passed` in the project root so the Stop hook skips redundant verification.

**Report the gate result:**
```
Quality Gate: PASS/FAIL
  Tests:      X/Y passing
  Type check: pass/fail
  Lint:       pass/fail/skipped (no lint script)
  Build:      pass/fail/skipped (not Next.js)
```

**On failure**, the orchestrator fixes by routing to the appropriate subagent:
- **Test failure** in a test that was passing earlier → re-invoke `tdd-implementer` with the failure output and instruction "These previously-passing tests now fail after refactor. Restore them without modifying the test file." Scope is the same `files_modified` from Phase 2/3.
- **Type check failure** → if it's in implementation files, re-invoke `tdd-implementer` with the `tsc` output and instruction "Fix these type errors without changing test files or runtime behavior." If it's in test files (rare), surface to the user — do not modify tests autonomously.
- **Build failure** (Next.js) → re-invoke `tdd-implementer` with the build output, same scope rule.
- **Lint failure** (advisory only) → report but do NOT auto-fix or block.

If any required gate (tests, type check, build) still fails after one fix iteration — surface to the user with the failing output and ask whether to abort the cycle or accept the failure with `(acknowledged)`. Do NOT loop the fix attempt indefinitely.

**Tier of Phase 3.5 failures:** all Phase 3.5 gate failures (tests / type check / build) are `[CRITICAL]` findings appended to the ledger with `phase: "phase-3.5"`, `check: "quality-gate-tests" | "quality-gate-typecheck" | "quality-gate-build"`. If the user acknowledges the failure, the ledger entry gets `acknowledged: true` (consistent with all other CRITICAL acks), AND the Quality Gate line in Variant A renders as `acknowledged-failure ([list of failed checks])` instead of `PASS`. Because these are CRITICAL acks, they DO flow through to the `.tdd/debt.md` write step at cycle end. Lint failures (advisory only) are emitted as `[WARNING]`, never CRITICAL, and never write to debt.md.

### Step 4: Spec Verification

**Ledger reminder:** every `[CRITICAL]`/`[WARNING]`/`[SUGGESTION]` emitted in 4a/4b/4c MUST be appended to `findings_ledger` as a new entry with `phase: "step-4a"` / `"step-4b"` / `"step-4c"` per the Findings Ledger section. This is the step most likely to be forgotten — do not.

After REFACTOR completes, verify the locked spec against actual results across **three dimensions**: Completeness (does a test exist for each criterion?), Traceability (can we find code in the implementation files that maps to each criterion?), and Coherence (does the code respect stated constraints and project patterns?).

**Honest limits of this step:**

This is a static heuristic check, not a correctness proof. It catches:
- Missing tests for declared criteria (Completeness)
- Implementations that have no plausibly-matching code for a criterion (Traceability)
- Implementations that violate stated constraints or diverge wildly from neighboring patterns (Coherence)

It does **not** catch:
- "Shallow green" via lookup tables, hardcoded values, or any implementation where the keywords appear but the logic is fake. A criterion with `formatFileSize` and `KB` in scope is "MATCHED" even if the function body is `return "1 KB"` unconditionally.
- Implementations that satisfy the test inputs but not the *intent* of the criterion.
- Semantic correctness in any rigorous sense.

For real correctness verification, the project needs mutation testing (Stryker / mutmut) or property-based tests — see the `[SUGGESTION]` note in Phase 2.

Treat this step as **spec ↔ code traceability**, not as a quality gate.

#### 4a. Completeness (criterion → test exists & passes)

```
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: formats bytes to human-readable string | formatFileSize > AC-1: formats bytes... | PASS |
| AC-2: supports binary units (1024-based) | formatFileSize > AC-2: uses binary... | PASS |
| EC-1: handles zero bytes | formatFileSize > EC-1: handles zero... | PASS |
| ERR-1: throws on negative input | formatFileSize > ERR-1: throws on... | PASS |
```

How to build:
1. List all criteria from the locked spec (AC-*, EC-*, ERR-*)
2. For each criterion, find the corresponding test(s) by matching the criterion ID in test names
3. Mark each as PASS (test exists and passes), FAIL (test exists but fails — see note below), or MISSING (no test)

**Note on FAIL:** under normal flow, a FAIL here is structurally impossible — Phase 2 GATE blocks Phase 3 until all tests pass, and Phase 3.5 re-runs the full suite. FAIL would only appear if a Step 4 re-run revealed a regression introduced after Phase 3.5 (rare). Treat as a re-run sanity check rather than an expected outcome; if it fires, route to the Phase 3.5 failure-fix flow before continuing.

Findings:
- MISSING criterion → `[WARNING]` "AC-N has no test"
- FAIL criterion → `[CRITICAL]` (should have been caught by GREEN gate, but flag it here too)

**User-facing coverage report (always emit one of these):**
- 100% coverage → "Completeness: N/N criteria covered."
- <100% coverage → surface gaps explicitly:
  > "Completeness: 5/7 criteria covered. Missing: AC-4 (concurrent access handling), ERR-2 (network timeout). Consider a follow-up cycle to add tests for these."

#### 4b. Traceability (criterion → implementation file:line)

For each AC/EC/ERR criterion, locate **at least one place** in the implementation files where the criterion is plausibly addressed. This is a low-confidence keyword grep, not a correctness check (see Step 4 caveats above). The point is to surface criteria with **zero** traceable code — those are the ones worth investigating.

**Keyword extraction rule:**
1. Take only nouns and verbs from the criterion text (skip articles, prepositions, conjunctions)
2. Drop stopwords: `the`, `a`, `an`, `is`, `are`, `should`, `must`, `when`, `then`, `with`, `of`, `to`, `for`
3. Prefer identifier-shaped tokens (camelCase, snake_case, function-like names mentioned in the criterion)
4. Pick the 2-3 most distinguishing tokens. Examples:
   - "AC-1: formatFileSize(1024) returns '1 KB'" → `formatFileSize`, `KB`
   - "AC-4: locale-aware formatting" → `locale`, `format` (or `Intl`, `toLocaleString` if those identifier-shaped names appear)
   - "ERR-1: throws RangeError on negative input" → `RangeError`, `negative`

**Grep + match threshold:**
1. Grep the implementer's `files_modified` (NOT the entire codebase) for those keywords
2. ≥1 match in `files_modified` → status `MATCHED`, record `file:line-range` of the best (most token-dense) match
3. 0 matches → status `UNMATCHED`

```
| Criterion | Implementation | Status |
|-----------|----------------|--------|
| AC-1: formats bytes to human-readable string | utils/formatFileSize.ts:12-30 | MATCHED |
| AC-3: binary units (1024-based) | utils/formatFileSize.ts:18 | MATCHED |
| AC-4: locale-aware formatting | (no keyword match) | UNMATCHED |
```

**MATCHED is a low bar.** It means "code mentioning the criterion's keywords exists" — not "the criterion is correctly implemented." A `1024`-only implementation of "binary units" likely matches on `1024` (if extracted) but fails on `binary` if no `binary` token appears in code; conversely an `Intl.NumberFormat`-only implementation of "locale-aware" likely matches on `Intl` only if the extractor picks it up. False UNMATCHED is common when implementation uses different vocabulary than the spec.

Findings:
- UNMATCHED → `[SUGGESTION]`. The criterion has no keyword-matching code in `files_modified`. This may indicate (a) the implementation uses different vocabulary than the spec, (b) the criterion is satisfied implicitly by another piece of code, or (c) the criterion was not implemented in this cycle. Investigate before treating as an issue.

This is intentionally `[SUGGESTION]`, not `[WARNING]` — the false-positive rate is too high for the finding to carry stronger weight. If you want stronger correctness evidence, run mutation testing or add property-based tests.

#### 4c. Coherence (constraints + project patterns)

- **Stated constraints** (from spec's Constraints / Out of Scope sections): for each constraint, verify the implementation honors it. Violation → `[CRITICAL]`.
- **Neighboring-file pattern check**: pick 1-2 sibling files in the same directory as each new implementation file (use the **alphabetically first 1-2 siblings**, for determinism across runs). Compare on these axes only:
  1. **Export style** — default export vs named exports (and how many)
  2. **Error handling** — `throw` vs `Result`/`Either` vs error callback vs return-null
  3. **Filename casing** — `camelCase.ts` vs `kebab-case.ts` vs `PascalCase.ts`
  4. **Top-level structure** — function-style module vs class-style vs object-with-methods

  *Why these four axes:* they're the surface-level patterns that show up in a 10-second `git diff` review and that future readers expect to match neighbors. Deeper patterns (indentation, JSDoc style, async/sync conventions, naming inside files) belong in REFACTOR phase or lint config — not in a runbook heuristic.

  Flag explicit deviations on any of these axes → `[SUGGESTION]`. If sibling files disagree among themselves on an axis, skip that axis (no consistent pattern to enforce). If the directory has no siblings (file is first of its kind), skip the whole check.
- **Dependency direction** (re-surface from Post-REFACTOR): → `[SUGGESTION]`.

#### Final Verification Summary

```
Spec Verification Report
========================
Completeness: X/Y criteria tested, M PASS / 0 FAIL / 0 MISSING
Traceability: X/Y criteria with implementation file:line match (Z UNMATCHED)
Coherence:    [N stated constraints honored] · [P pattern deviations]

Findings: 0 CRITICAL · 2 WARNING · 3 SUGGESTION
```

**Spec Feedback** (informational — append to verification report):
- If implementation includes behavior not in spec → "DERIVED: [description]. Consider adding to spec."
- If any spec criterion was hard to test or had multiple interpretations → "AMBIGUOUS: [criterion]. Consider clarifying."
- If tests assume something unstated → "IMPLICIT: [assumption]. Consider adding to Constraints."

**GATE: Cycle complete after spec verification is reported.**

Verification is informational (does not block completion) — but CRITICAL findings here mean the implementation diverges from the locked spec and **mandate a follow-up cycle** (consistent with the Severity Levels definition for last-phase CRITICAL).

### Final Report

Pick the variant matching how the cycle ended. **Both variants lead with the verdict and the next action — these are what the user needs to see first.**

**Variant A — Completed cycle:**

```
STATUS:    COMPLETE  ✓ ([N] CRITICAL · [N] WARNING · [N] SUGGESTION)
NEXT:      [one-sentence recommendation — pick the FIRST that applies:
            1. If page_level_ac_resolution == "acknowledged":
               "Browser-test required before merge — N page-level AC(s) not
                covered by automated tests. Run /real-browser or manual UI check
                for: AC-X, AC-Y."
            2. If any CRITICAL findings were acknowledged-overridden:
               "[N] acknowledged CRITICAL(s) added to project debt ledger."
            3. If any WARNING findings:
               "Address [N] WARNING findings before merging."
            4. Otherwise:
               "Cycle clean — ready to commit."]

────────────────────────────────────────
Feature: [feature name]
Spec: [N criteria defined | prompt-only mode]
Tests: [count] in [file path]
Implementation: [list of files]
Refactoring: [applied/skipped] — [reasoning]
Quality Gate: [PASS | acknowledged-failure ([list of acknowledged failures])]

Verification (3 dimensions):
  Completeness: [X/N] criteria tested ([percentage]%)
  Traceability: [X/N] criteria with implementation evidence
  Coherence:    [stated constraints honored] · [N pattern deviations]
[If MISSING criteria: "  Missing: [comma-separated list of criterion IDs]"]
[If UNMATCHED criteria: "  Unmatched (no impl evidence found): [comma-separated list]"]

Findings (grouped by tier):
  CRITICAL ([N]):
    [F-id] [check] file:line — message [acknowledged: yes/no (reason)] {if carried_from_strike non-null: " [carried_from_strike: <N>]"}
    ...
  WARNING ([N]):
    [F-id] [check] file:line — message {if carried_from_strike non-null: " [carried_from_strike: <N>]"}
    ...
  SUGGESTION ([N]):
    [F-id] [check] file:line — message {if carried_from_strike non-null: " [carried_from_strike: <N>]"}
    ...
```

The `[carried_from_strike: <N>]` suffix renders only when the ledger entry's `carried_from_strike` field is non-null. Omit the whole bracket otherwise — don't render `[carried_from_strike: null]`.

Notes on Variant A:
- **STATUS line — exact templates** (pick one based on cycle state):
  - `STATUS:    COMPLETE  ✓  ([N] CRITICAL · [N] WARNING · [N] SUGGESTION)` — when 0 unacknowledged CRITICAL findings AND no debt added this cycle.
  - `STATUS:    COMPLETE  ⚠  (with [N] acknowledged-CRITICAL debt) — ([N] CRITICAL · [N] WARNING · [N] SUGGESTION)` — when at least 1 CRITICAL was acknowledged-overridden (which then writes to `.tdd/debt.md`).
  - Tier counts in parentheses always render, even when zero, for log-grep consistency.
  - Quality Gate line shows `acknowledged-failure` if Phase 3.5 was let through with `(acknowledged)`.
- WARNINGs and SUGGESTIONs are advisory but listed in full — no truncation. The user can scan and skip.
- If prompt-only mode was used: the Verification block is replaced with `Verification: skipped (prompt-only mode)`.
- All findings come from the `findings_ledger` (see Findings Ledger section). Never recount from memory.

**Variant B — Aborted (spec-defect 2-strike, user abort, post-5-attempts choice (c), or intent-check routed to /bugfix):**

```
STATUS:    ABORTED  ✗  ([reason: spec-defect 2-strike | user-abort | iteration-exhausted | intent-check-routed])
NEXT:      [one-sentence concrete action: e.g., "Human review of spec required — see strike reasons below."
            OR "Working tree may have partial implementation — `git status` to review."]

────────────────────────────────────────
Feature: [feature name]
Spec: [N criteria defined | prompt-only mode]

[If spec-defect 2-strike, list both reasons up-front:]
  Strike 1: [implementer's reason on first attempt]
  Strike 2: [implementer's reason on second attempt]

State at abort:
  Tests: [count or "discarded"]  (file: [path or "—"])
  Implementation: [list or "none"]
  Iteration attempts used: [N/5]
  Working tree: [clean | partial changes present, run `git status`]

Findings so far (grouped by tier, includes carried-from-strike-1 if any):
  CRITICAL ([N]):
    [F-id] [check] file:line — message [carried_from_strike: 1/2/null]
    ...
  WARNING ([N]):
    ...
  SUGGESTION ([N]):
    ...
```

The aborted variant is emitted even when partial work was discarded — the user needs visibility into what state the working tree is in. NEXT line must give a concrete action, not just "human review required" — name the file or command the user should run next.

### Multi-Feature Handling

If the user's request involves multiple features, complete the FULL cycle for each before starting the next:

```
Feature 1: SPEC -> RED -> GREEN -> REFACTOR -> VERIFY (complete)
Feature 2: SPEC -> RED -> GREEN -> REFACTOR -> VERIFY (complete)
```

### Phase Violations

These are HARD rules — never break them:

- NEVER write tests before spec is confirmed (or user explicitly chose prompt-only)
- NEVER write implementation before tests exist and fail
- NEVER modify test files during GREEN phase
- NEVER skip REFACTOR evaluation
- NEVER proceed to next phase without verified gate condition
- NEVER let the implementer weaken test assertions
- NEVER work around an unclear or contradictory spec by guessing — raise `spec_defect: true` and return to Phase 1c
- NEVER skip spec verification at the end
- NEVER provide existing implementation source code to the RED agent (tests must be independent of implementation)

## Examples

### User says: "/tdd add file size formatting utility"

1. Stack detected: Vitest (vitest.config.ts found)
2. Spec phase: no existing spec found → write spec:
   ```
   AC-1: formatFileSize(1024) returns "1 KB"
   AC-2: formatFileSize(1048576) returns "1 MB"
   AC-3: uses binary units (1024-based, not 1000)
   EC-1: formatFileSize(0) returns "0 B"
   ERR-1: formatFileSize(-1) throws RangeError
   ```
   User confirms → spec locked (5 criteria)
3. RED: test-writer creates `__tests__/formatFileSize.test.ts` with 5 tests (AC-1 through ERR-1) — all FAIL
4. Spec coverage check: 5/5 criteria have tests — proceed
5. GREEN: implementer creates `utils/formatFileSize.ts` — all tests PASS, `spec_defect: false`
6. REFACTOR: refactorer extracts shared number formatting — tests still PASS
7. Spec verification (3 dimensions): Completeness 5/5 · Traceability 5/5 MATCHED · Coherence: constraints honored, no pattern deviations
8. Report: "TDD cycle complete. Findings: 0 CRITICAL · 0 WARNING · 0 SUGGESTION."

### User says: "/tdd implement yacht search filtering" (existing spec doc)

1. Stack detected: Vitest
2. Spec phase: found `docs/vector-search.md` in the project — extracts 7 acceptance criteria from the doc
   User confirms extracted criteria → spec locked
3. RED: tests generated from spec criteria (AC-1 through AC-7)
4. Spec coverage check: 7/7 — proceed
5. GREEN → REFACTOR → 3-dim verification: Completeness 7/7 · Traceability 6/7 (AC-5 UNMATCHED [SUGGESTION] — investigate whether impl uses different vocabulary) · Coherence: 1 pattern deviation [SUGGESTION]
6. Report includes follow-up suggestion to investigate AC-5.

### User says: "/tdd add card flip animation" (user chooses prompt-only)

1. Stack detected: Vitest
2. Spec phase: no relevant doc found → offer to write spec
3. User says "skip the spec, just code it" → prompt-only mode accepted, `spec_traceability: "prompt-only"`, Step 4 skipped
4. RED → GREEN → REFACTOR → cycle complete (no spec verification)
5. Report: "Verification: skipped (prompt-only mode)"

### User says: "/tdd add user avatar upload" (spec written, partial coverage)

1. Stack detected: Vitest
2. Spec phase: write spec with 6 criteria → user confirms
3. RED: test-writer creates 4 tests (covers AC-1, AC-2, EC-1, ERR-1)
4. Spec coverage check: 4/6 — warn user: "Missing: AC-3 (resize to 200x200), AC-4 (reject files >5MB)"
5. User says "proceed anyway" → continue with 4 tests
6. GREEN → REFACTOR → 3-dim verification:
   - Completeness: 4/6 (67%). Missing: AC-3, AC-4 [WARNING ×2]
   - Traceability: 4/4 MATCHED (only counts criteria that have tests)
   - Coherence: clean
7. Report: "Findings: 0 CRITICAL · 2 WARNING · 0 SUGGESTION. Missing: AC-3, AC-4. Consider follow-up cycle."

### User says: "/tdd URL-backed filter state for /posts" (page-level AC, learned from RAD-207)

1. Stack detected: Vitest (no Playwright in this project)
2. Spec phase: write spec with 6 criteria. Smell check passes. **Page-Level AC Detection** scans:
   - AC-1 "GET /posts?status=approved renders APPROVED at mount" → matches `GET /url`, `at mount` → flagged
   - AC-5 "Clicking chip pushes URL without page reload" → matches `page reload` → flagged
   - AC-7 "Browser back restores filter state" → matches `browser back` → flagged
3. Surfaced to user: 3 page-level ACs found. Unit tests with mocked `useSearchParams` will pass even if the real server/client hydration path is broken. Choose: (a) add E2E, (b) acknowledge + browser-test before merge, (c) re-scope.
4. User picks **(b)** — no Playwright infrastructure, will browser-test manually. `page_level_ac_resolution: "acknowledged"`. 3 WARNING ledger entries with `acknowledged: true`.
5. Spec locked → RED → GREEN → REFACTOR → 3-dim verification: Completeness 6/6 · Traceability 6/6 MATCHED · Coherence clean
6. Final Report STATUS: `COMPLETE ✓ (0 CRITICAL · 3 WARNING · 0 SUGGESTION)`. NEXT: **"Browser-test required before merge — 3 page-level AC(s) not covered by automated tests. Run /real-browser or manual UI check for: AC-1, AC-5, AC-7."**
7. User runs `/real-browser`, finds AC-1 cold-load broken, opens a follow-up cycle to wire server-side `searchParams`. The page-level detector did its job: the user knew to verify before merge, and the cycle's "COMPLETE ✓" didn't mislead.

## See Also

- `references/anti_patterns.md` — TDD anti-patterns with code examples (phase violations, over-mocking, structural, dependency)
- `references/framework_configs.md` — detection rules, run commands, and test skeletons per framework
- `testing-patterns` skill — broader testing strategy (Testing Trophy, MSW, golden file testing)
- `tdd-test-writer` agent — RED phase details
- `tdd-implementer` agent — GREEN phase details
- `tdd-refactorer` agent — REFACTOR phase details
