---
name: bugfix-pipeline
description: >
  ALWAYS invoke this skill when the user reports a bug to fix — it traces the active code path,
  writes a failing test, iterates the fix, and reviews the diff, with test gates that prevent
  fixing the wrong code path. Do not edit suspected code directly before tracing the active path
  and writing a failing test. Triggers: "/bugfix", "fix bug", "investigate bug", "trace and fix",
  or a referenced issue ID. Do NOT use for new features (use /tdd), refactoring without
  bugs, or documentation changes.
---

# /bugfix — Bug-Fix Pipeline With Test Gates

Trace active code path → write failing test → iterate fix → review diff → report.

Prevents the most expensive failure mode in agent-assisted debugging: **confidently
fixing code that never runs.**

## Why the tracing step exists

Ask an agent to fix a bug and it will grep for a plausible-looking function, find one,
and fix it. The fix is often correct — applied to the wrong copy. Codebases accumulate
`searchUsers()` in a service and `searchUsers()` in a legacy helper nobody deleted; a
barrel file re-exports one of them; only one is actually imported by the running route.
The agent reports success, the tests it never ran still pass, and the bug survives.

Every gate below exists to make that failure impossible rather than unlikely:

- The **path is traced and confirmed before any edit** — so the target is known, not guessed.
- The **test must fail first** — proving the bug reproduces *in the path you traced*. A
  test that passes on the first run means you traced the wrong path (or the bug is gone).
- The **fix is constrained to the traced files** — an implementer that wanders outside them
  is a signal you're back to guessing.

## Instructions

### Step 0: Context Gathering

**If the user references an issue ID** and an issue tracker is available (Linear, Jira,
GitHub Issues — via CLI, MCP server, or whatever this project uses): fetch it and extract
expected behavior, actual behavior, and reproduction steps from the description and comments.

**If not:** extract the bug description from the user's prompt. A tracker is optional —
everything below works from a plain description.

**Always:** detect the project from cwd and read whatever architecture docs it has
(`README`, `ARCHITECTURE.md`, `CONTRIBUTING`, or the project's own conventions file).

### Step 1: Code Path Tracing (CRITICAL)

Before touching any code:

1. **Identify the entry point** for the buggy behavior:
   - API endpoint → find the route handler
   - UI bug → find the component/view
   - CLI/background job → find the command handler

2. **Trace the call chain forward** from the entry point using Grep and Read:
   - Follow function calls and imports
   - At each step, verify which implementation is ACTUALLY imported (not a similarly-named duplicate)
   - Pay special attention to: re-exported functions, barrel imports, service/repository layers with legacy copies

3. **Document the active code path:**
   ```
   Active Code Path:
   1. routes/api/orders.ts:45 → handleOrderSearch()
   2. services/orderService.ts:120 → searchOrders()
   3. repositories/orderRepo.ts:88 → findByFilters()  ← BUG IS HERE

   Also found (NOT active — dead code):
   - services/orderServiceLegacy.ts:50 → searchOrders() (unused, imported nowhere)
   - utils/searchHelpers.ts:30 → buildFilterConditions() (different code path)
   ```

4. **GATE: Present the traced code path to the user for confirmation.**
   Ask: "Is this the correct active code path? Should I proceed with writing a failing test targeting [file:line]?"

   Do NOT proceed until the user confirms.

### Step 2: Write Failing Test (RED Phase)

Invoke the `tdd-test-writer` agent via the Agent tool with `subagent_type: "tdd-test-writer"`.

**Pass to agent:**
- Bug description (expected vs actual behavior)
- Active code path from Step 1 (so the test imports the correct module)
- Project path
- Test framework and run command (detected the same way [`tdd`](../tdd/) does it in its Step 0)

**Receive from agent:**
- Test file path
- Test failure output (proving the bug exists)
- What each test verifies

**GATE:** The test must FAIL, proving the bug is reproduced in the active code path.

If the test passes → either the bug is already fixed, or the test doesn't reproduce the
issue, or Step 1 traced the wrong path. Report and ask how to proceed — do not "fix" anything.

### Step 3: Iterate Fix (GREEN Phase)

Invoke the `tdd-implementer` agent via the Agent tool with `subagent_type: "tdd-implementer"`.

**Pass to agent:**
- Test file path (from Step 2)
- Bug description (brief — 1-2 sentences)
- **Active code path constraint:** "Only modify files in the active code path: [list]. Do NOT modify files outside this list."
- Test run command

**Receive from agent:**
- Files modified (must be a subset of the active code path files)
- Test success output (all tests pass)

**GATE:** All tests pass AND every modified file is within the traced active code path.

If the implementer modified files outside the path → flag as a potential wrong-path fix and
report to the user rather than accepting it.

### Step 4: Review & Report

Do this directly (no subagent needed):

1. **Diff review:** run `git diff` on modified files
   - Were any test files modified? (violation — the test is the spec)
   - Were files outside the active code path changed? (flag)
   - Any new `// TODO` or `// HACK` comments? (warn)

2. **Regression check:** run the FULL test suite, not just the new test
   - All existing tests must still pass
   - If any fail → the fix has side effects; report details

3. **Generate report:**

```markdown
## Bug Fix Report

**Issue:** [ID](url) — Title
**Status:** Fixed, pending approval

### Active Code Path
1. `file:line` → function()
2. `file:line` → function()
3. `file:line` → function() ← ROOT CAUSE

### Root Cause
[Brief explanation of why the bug occurs]

### Fix Applied
[What was changed and why]

### Files Modified
| File | Change |
|------|--------|
| path/to/file.ts | Description of change |

### Test Coverage
| Test | Status |
|------|--------|
| new-test.test.ts | N tests PASS |
| Full suite | N tests PASS, 0 failures |

### Side Effects
None detected / [details if any]
```

4. **Ask the user:** "Ready to commit and push? Or do you want to review the diff first?"

## Hard Rules (Never Break)

- **NEVER** modify code before tracing the active code path (Step 1)
- **NEVER** skip user confirmation of the traced path
- **NEVER** modify test files during the fix phase (Step 3)
- **NEVER** push without user approval
- **NEVER** let the implementer weaken test assertions
- **ALWAYS** run the full test suite after the fix, not just the new test
- **ALWAYS** verify modified files are within the traced code path

## Examples

### Example 1: Duplicate functions
User says: `/bugfix ENG-233` — "Record sync fails on collections with >3000 items"
1. Fetches the issue (or takes the description straight from the prompt)
2. Traces: `routes/api/sync.ts → syncService.ts → batchInsert()`. Finds `batchInsertLegacy()` in the same file (dead code). Confirms `batchInsert()` is the active path.
3. User confirms the path
4. Test: "sync 5000 records should succeed" — FAILS (parameter limit exceeded)
5. Fix: chunks `batchInsert` into 500-item batches — test PASSES
6. Full suite: 42/42 pass. Report generated.

### Example 2: No issue ID, ambiguous code
User says: "fix the search returning stale results"
1. No issue ID. Extracts: "search returns stale/cached results"
2. Traces: `routes/search.ts → searchService.ts → runQuery() → cache.get()`. Identifies a cache TTL issue.
3. User confirms: "Yes, the cache is the problem"
4. Test: "search after a record update should return fresh data" — FAILS
5. Fix: adds cache invalidation on update — PASSES
6. Full suite: all pass. Report generated.

### Example 3: Test already passes (the useful failure)
User says: `/bugfix ENG-45`
1. Fetches the issue, traces the code path
2. Writes a test reproducing the described bug — the test PASSES
3. Reports: "The test passes, meaning the described behavior doesn't reproduce. Either the bug was fixed in a recent commit, the reproduction steps need adjustment, or the traced path isn't the one the bug lives in. How should I proceed?"

This is the gate earning its keep: without it, Step 3 would have "fixed" a bug that
wasn't there and reported success.

## Requirements

- **`tdd-test-writer` and `tdd-implementer` agents.** Both ship with the
  [`tdd`](../tdd/) skill in this repo — copy its `agents/` files to `~/.claude/agents/`.
- A project with a runnable test suite.

## See Also

- [`tdd`](../tdd/) — the full Red-Green-Refactor cycle for *new* behavior. `/bugfix` is
  its counterpart: same discipline, but the failing test's job is to reproduce a defect
  rather than specify a feature. Route by intent — new behavior → `/tdd`, something broken
  → `/bugfix`, pure refactor → neither.
