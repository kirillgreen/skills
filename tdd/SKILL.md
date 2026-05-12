---
name: tdd
description: >
  Spec-Driven TDD with strict Red-Green-Refactor cycle using isolated subagents.
  Every feature starts with a structured spec. Tests are generated from spec acceptance
  criteria. Post-cycle verification ensures all criteria are implemented.
  Use when user says "/tdd", "test first", "use tdd", "tdd approach",
  "write tests first", or when implementing new features/functionality.
  Trigger phrases: "implement", "add feature".
  Do NOT use for bug fixes without new tests, documentation changes,
  configuration-only changes, or refactoring existing code without new behavior.
---

# /tdd -- Spec-Driven Test-Driven Development

Enforce strict Red-Green-Refactor cycle with context-isolated subagents.
Every feature starts with a **specification** — numbered acceptance criteria that drive test generation and final verification.

Flow: **Spec → RED → GREEN → REFACTOR → Verify**

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

### Step 1: Spec Phase

The spec is the **source of truth** for the entire TDD cycle. Every test must trace back to a spec criterion. Every criterion must be verified at the end.

#### 1a. Find or Receive Spec

Check for existing specification in this priority order:

1. **User provided a doc reference** (via `@file` or explicit path) — read it, extract acceptance criteria
2. **Search project docs** for relevant specification:
   - Scan common doc locations: `docs/`, `Documentation/`, `Documentation.docc/`, `spec/`, `specs/`, top-level `*.md` files
   - Look for an index file (`INDEX.md`, `README.md`, `TOC.md`) inside those folders
   - Grep file names and headings for keywords matching the feature topic
3. **No spec found** — proceed to 1b (write spec)

If existing doc is found but lacks structured acceptance criteria, extract them into the spec format below.

#### 1b. Write Spec (when no spec exists)

Write a structured spec and present it to the user for confirmation.

**Spec format:**

```markdown
## Spec: [Feature Name]

## A general description of the task, where we explain what kind of system behavior we want to achieve and how we plan to implement it. The description is up to four paragraphs of 40-80 words each.

### Acceptance Criteria
- AC-1: [First criterion — concrete, testable behavior]
- AC-2: [Second criterion]
- AC-3: [Third criterion]
...

### Edge Cases
- EC-1: [Edge case — boundary value, empty input, etc.]
- EC-2: [Edge case]

### Error Cases
- ERR-1: [Error case — what happens when things go wrong]

### Constraints
- [Technical constraint, if any — performance, compatibility, etc.]

### Out of Scope
- [What this feature does NOT do — prevents gold-plating]
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

**Present the spec to the user and wait for confirmation before proceeding.**

If user modifies the spec — incorporate changes. If user says "proceed" — lock the spec.

#### 1c. Locked Spec

After user confirmation, the spec is **locked** for this TDD cycle. Store the full spec text as `locked_spec` — it will be passed to the test-writer and used for final verification.

The locked spec contains:
- Numbered criteria (AC-1, AC-2, ... EC-1, ... ERR-1, ...)
- Total criterion count (for verification tracking)

### Phase 1: RED -- Write Failing Tests

Invoke `tdd-test-writer` agent via Task tool with `subagent_type: "tdd-test-writer"`:

**Pass to agent:**
- Feature requirement (from user's prompt)
- **Locked spec** (full text with numbered criteria)
- Project path
- Test framework name and run command (from Step 0)
- **Instruction:** "Each test MUST reference its spec criterion in the test name or description (e.g., 'AC-1: formats bytes to human-readable string'). Every AC/EC/ERR criterion must have at least one corresponding test. Output tests in priority order: happy path AC first, then edge cases EC, then error cases ERR."
- **Test-level hint** (add if keywords detected in locked spec or feature requirement):
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

**Spec coverage check:** Compare the test summary against the locked spec. If any AC/EC/ERR criterion has no corresponding test — warn the user:

> Spec criteria without tests: [list missing criteria]
> (a) Re-invoke test-writer to add missing tests
> (b) Accept partial coverage and proceed

Wait for user decision.

### Post-RED Lint

Before proceeding to GREEN, verify test quality:

1. **Over-mocking check:** If the feature targets a pure module (`utils/`, `lib/`, `helpers/`, `domain/`, `models/`), grep the test file for mocking patterns:
   - TypeScript: `vi.mock`, `vi.spyOn`, `jest.mock`, `jest.spyOn`
   - Swift: `Mock`, `Stub`, `@Mock`

   If mocking found in a pure-module test — warn the user:
   > "Test for pure utility uses mocking. Consider testing via inputs->outputs instead. Proceed anyway?"

   Wait for user confirmation before continuing.

2. **Test isolation check:** Grep the test file's import paths. If any imported module doesn't exist on disk — the test fails on import errors, not assertions. Warn the user:
   > "Test imports [path] which doesn't exist. Tests will fail on missing module, not assertion mismatch. Re-invoke test-writer to add stubs?"

   If user says yes — re-invoke `tdd-test-writer` with instruction to create minimal stubs (empty exports) for imported modules. If user says proceed anyway — continue.

3. **Assertion strength check:** Grep the test file for weak-only assertion patterns:
   - TypeScript: tests with only `toBeDefined()`, `toBeTruthy()`, `not.toBeNull()`, `not.toBeUndefined()`
   - Swift: tests with only `#expect(result != nil)`, `XCTAssertNotNil`

   If a test has NO exact-value assertion — warn:
   > "Test [name] has only weak assertions. Consider asserting specific values."

4. **Assertion quality fallback:** The test-writer agent performs its own "What bug would this miss?" self-review. This step catches patterns the agent may have missed — grep for tests where assertions use only comparisons like `> 0`, `!== null`, `.length` without exact expected values. If found, warn alongside check #3.

5. **Implementation leakage check:** Grep test file for references to private/internal names (`_private`, `.__`, `internal`, `#private`). If found — warn:
   > "Test references internal/private name [name]. Consider testing through the public API instead."

6. **Mock count check:** Count mocking calls (`vi.mock`, `vi.spyOn`, `jest.mock`, `Mock(`, `Stub(`) in the test file. If >3 mocks — suggest:
   > "Test uses [N] mocks. Consider whether an integration test would be more appropriate."

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

**Pass to agent:**
- Test file path (from Phase 1)
- Feature requirement (brief — 1-2 sentences)
- Test run command
- **Implementation scope constraint:** "Create/modify only these files: [list]. Do NOT modify files outside this scope."

**Receive from agent:**
- Files modified/created with descriptions
- Test success output (all tests pass)
- Implementation summary

**Post-GREEN validation:**
1. **Scope check:** Verify all `files_modified` are within the defined scope. If implementer touched files outside scope — warn user with the list of out-of-scope files and ask whether to accept.
2. **Test integrity:** Verify no test files were modified (existing hard rule).
3. **Import scan:** Grep newly created/modified files for imports. Flag if any new file imports:
   - Test utilities (`vitest`, `@testing-library`, `XCTest`, `Testing`)
   - Unrelated feature modules not in the implementation scope

**GATE: Do NOT proceed to Phase 3 until ALL tests pass AND scope validation passes.**

If agent returns failure after max iterations (5 attempts):
1. Re-run the test command to get current pass/fail breakdown (agent may not return per-test results)
2. Report: "Partial progress: X/Y tests passing. Failing: [list]"
3. Ask user:
   - (a) Accept partial — proceed to REFACTOR with passing tests, follow-up cycle for rest
   - (b) Simplify/split the failing tests and retry RED for them
   - (c) Abort cycle

If GREEN fails all 5 attempts, the problem may be in the tests, not the implementation. Consider revising tests.

**Note:** When the project has mutation testing infrastructure (Stryker, mutmut), consider running it post-GREEN to verify test effectiveness.

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

1. **Tests still pass** (existing gate)
2. **Dependency direction check** (TypeScript/Node projects only — skip for Swift):
   For each modified file, verify its imports follow the project's layer direction:
   - `utils/`, `lib/` → should not import from `services/`, `routes/`, `components/`
   - `services/` → should not import from `routes/`, `handlers/`, `pages/`
   - `models/`, `types/` → should not import from anything except other types/models

   If violations found — report to user but don't block (may be intentional).

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

**Report the gate result:**
```
Quality Gate: PASS/FAIL
  Tests:      X/Y passing
  Type check: pass/fail
  Lint:       pass/fail/skipped (no lint script)
  Build:      pass/fail/skipped (not Next.js)
```

If any required gate fails — fix before proceeding to Spec Verification.

### Step 4: Spec Verification

After REFACTOR completes, verify the locked spec against actual results.

**Build a traceability matrix:**

```
Spec Verification Report
========================
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: formats bytes to human-readable string | formatFileSize > AC-1: formats bytes... | PASS |
| AC-2: supports binary units (1024-based) | formatFileSize > AC-2: uses binary... | PASS |
| EC-1: handles zero bytes | formatFileSize > EC-1: handles zero... | PASS |
| ERR-1: throws on negative input | formatFileSize > ERR-1: throws on... | PASS |
========================
Coverage: 4/4 criteria verified (100%)
```

**How to build the matrix:**
1. List all criteria from the locked spec (AC-*, EC-*, ERR-*)
2. For each criterion, find the corresponding test(s) by matching the criterion ID in test names
3. Mark each as PASS (test exists and passes), FAIL (test exists but fails), or MISSING (no test)

**Report to user:**
- If **100% coverage** — report success with the matrix
- If **<100% coverage** — report with gaps highlighted:
  > Spec verification: 5/7 criteria verified.
  > Missing: AC-4 (concurrent access handling), ERR-2 (network timeout)
  > These criteria have no corresponding tests. Consider adding them in a follow-up TDD cycle.

**Spec Feedback** (informational — append to verification report):
- If implementation includes behavior not in spec → "DERIVED: [description]. Consider adding to spec."
- If any spec criterion was hard to test or had multiple interpretations → "AMBIGUOUS: [criterion]. Consider clarifying."
- If tests assume something unstated → "IMPLICIT: [assumption]. Consider adding to Constraints."

**GATE: Cycle complete after spec verification is reported.**

The spec verification is informational (does not block completion) — but gaps are clearly reported so the user can decide whether to run another cycle.

### Final Report

Report the full cycle result to the user:

```
TDD Cycle Complete
==================
Spec: [feature name] — [N] criteria defined
Tests: [count] written ([file path])
Implementation: [list of files]
Refactoring: [applied/skipped] — [reasoning]
Spec Coverage: [X/N] criteria verified ([percentage]%)
[If gaps: "Missing: [list]"]
All tests: PASSING
```

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
5. GREEN: implementer creates `utils/formatFileSize.ts` — all tests PASS
6. REFACTOR: refactorer extracts shared number formatting — tests still PASS
7. Spec verification: 5/5 criteria verified (100%)
8. Report: "TDD cycle complete. Spec: 5 criteria, 5 tests, 2 files, 100% spec coverage."

### User says: "implement product search filtering" (auto-trigger)

1. Stack detected: Vitest
2. Spec phase: found `docs/search.md` — extracts 7 acceptance criteria from existing doc
   User confirms extracted criteria → spec locked
3. RED: tests generated from spec criteria (AC-1 through AC-7)
4. Spec coverage check: 7/7 — proceed
5. GREEN → REFACTOR → Spec verification: 7/7 (100%)

### User says: "/tdd add card flip animation" (no spec, user chooses prompt-only)

1. Stack detected: Vitest
2. Spec phase: no relevant doc found → offer to write spec
3. User chooses "proceed from prompt only" → spec phase skipped, `spec_traceability: "prompt-only"`
4. RED → GREEN → REFACTOR → complete (no spec verification — noted in report)
5. Report includes: "Spec coverage: N/A (prompt-only mode — no spec to verify against)"

### User says: "/tdd add user avatar upload" (spec written, partial coverage)

1. Stack detected: Vitest
2. Spec phase: write spec with 6 criteria → user confirms
3. RED: test-writer creates 4 tests (covers AC-1, AC-2, EC-1, ERR-1)
4. Spec coverage check: 4/6 — warn user: "Missing: AC-3 (resize to 200x200), AC-4 (reject files >5MB)"
5. User says "proceed anyway" → continue with 4 tests
6. GREEN → REFACTOR → Spec verification: 4/6 (67%)
7. Report: "Spec coverage: 4/6 (67%). Missing: AC-3, AC-4. Consider follow-up TDD cycle."

## See Also

- `references/anti_patterns.md` — TDD anti-patterns with code examples (phase violations, over-mocking, structural, dependency)
- `references/framework_configs.md` — detection rules, run commands, and test skeletons per framework
- `agents/tdd-test-writer.md` — RED phase agent
- `agents/tdd-implementer.md` — GREEN phase agent
- `agents/tdd-refactorer.md` — REFACTOR phase agent
