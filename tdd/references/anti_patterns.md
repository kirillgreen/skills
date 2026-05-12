# TDD Anti-Patterns Reference

Compact reference for the orchestrator and agents. Read when writing tests, reviewing agent output, or evaluating refactoring.

---

## Phase Violations

### Writing implementation before tests
**Symptom**: Code appears in source files before a corresponding test exists.
**Fix**: Delete the implementation. Write the test first.
**Why**: Implementation-first means the test verifies what was built, not specifying what should be built. The test becomes a rubber stamp.

### Writing all tests at once
**Symptom**: Multiple test functions written in a batch before any implementation.
**Fix**: Write one test. Make it fail. Make it pass. Refactor. Then write the next.
**Why**: Batch testing leads to batch implementation. The feedback loop widens, errors compound.

### Skipping the RED phase
**Symptom**: A test is written and passes immediately without implementation.
**Fix**: If the test passes without new code: (a) the behavior already exists, (b) the test is trivially passing (wrong assertion), or (c) the test setup is wrong. Investigate.
**Why**: A test that was never seen failing provides no confidence.

### Modifying tests to match implementation
**Symptom**: After writing implementation, the test is changed to match what the code does rather than what the spec requires.
**Fix**: The test encodes the REQUIREMENT. Fix the implementation, not the test. Only change the test if the user confirms the requirement was wrong.
**Why**: Inverts the authority chain. Tests are specifications; implementation serves them.

---

## Test Quality Anti-Patterns

### Testing implementation details
**Symptom**: Tests assert on private methods, internal state, call counts of mocked internals, or specific algorithm steps.
**Examples**:
- `expect(service._cache).toHaveLength(3)` -- testing private cache
- `expect(mockDb.query).toHaveBeenCalledTimes(2)` -- testing query pattern
- `expect(result.__internal_flag).toBe(true)` -- testing private state

**Fix**: Test through public interfaces only. Assert on return values, side effects visible to callers, or observable state changes.
**Why**: Implementation-detail tests break on every refactor, even when behavior is preserved.

### Testing the framework, not the code
**Symptom**: Tests that verify the test framework, mocking library, or ORM works correctly.
**Examples**:
- Mocking a database then asserting the mock returns the mocked value
- Testing that `JSON.parse(JSON.stringify(x))` round-trips correctly

**Fix**: Tests should verify YOUR code's behavior, not third-party behavior.

### Tautological tests
**Symptom**: Tests where the assertion is trivially true regardless of implementation.
**Examples**:
- `expect(true).toBe(true)`
- `expect(result).toBeDefined()` (where result is always defined)
- Asserting a function returns without throwing when it has no throw paths

**Fix**: Every assertion must be capable of failing given a plausible incorrect implementation.

### Over-mocking
**Symptom**: More mock setup code than actual test code. Every dependency is mocked.
**Fix**: Use real implementations where practical. Mock only at system boundaries (network, filesystem, clock). Prefer integration tests with in-memory fakes over unit tests with extensive mocks.
**Why**: Over-mocked tests pass even when integration is broken.

**Detection** (used in Post-RED Lint):
- TypeScript: `vi.mock`, `vi.spyOn`, `jest.mock`, `jest.spyOn`
- Swift: `Mock`, `Stub`, `@Mock`

If feature targets a pure module (`utils/`, `lib/`, `helpers/`, `domain/`, `models/`) and test uses mocking -> likely over-mocking.

---

## Structural Anti-Patterns

### God test
**Symptom**: A single test function that tests multiple behaviors with multiple assertions and complex setup.
**Fix**: Split into one test per behavior. Each test should have one reason to fail.
**Pattern**: Arrange-Act-Assert, each section clearly delineated.

### Test interdependence
**Symptom**: Tests that depend on execution order, shared mutable state, or other tests' side effects.
**Fix**: Each test sets up its own state and tears it down. Tests must pass when run in isolation or in any order.

### Fragile test fixtures
**Symptom**: A change in test setup code breaks many unrelated tests.
**Fix**: Use builder patterns or factory functions that provide sensible defaults. Each test overrides only what it cares about.

### Testing trivial code
**Symptom**: Tests for getters, setters, constructors, or obvious one-liners.
**Fix**: Skip tests for code with zero logic. Focus on code with conditionals, loops, transformations, or business rules.

---

## Process Anti-Patterns

### Gold plating during GREEN
**Symptom**: Implementation includes extra features, optimization, or error handling not required by the current test.
**Fix**: Write the absolute minimum to make the test pass. Want to add more? Write a test for it first.

### Skipping REFACTOR
**Symptom**: After GREEN, immediately writing the next test without cleaning up.
**Fix**: Always assess the code after GREEN. Even if no refactoring is needed, consciously evaluate. Refactoring is where design emerges.

### Premature refactoring
**Symptom**: Extracting abstractions after only one or two instances of a pattern.
**Fix**: Wait for the "Rule of Three" -- extract only after seeing a pattern three times.

### Ignoring test failures in the full suite
**Symptom**: A new test passes but existing tests break, and the broken tests are dismissed as "unrelated."
**Fix**: Every test failure after GREEN is a regression until proven otherwise. Investigate and fix before REFACTOR.

---

## Dependency Anti-Patterns

### Lower layer importing higher layer
**Symptom**: Utility or model code imports from services, routes, or components.
**Examples**:
- `utils/format.ts` importing from `services/userService.ts`
- `models/Order.ts` importing from `routes/orderHandler.ts`

**Fix**: Dependencies flow inward only: `utils/lib` -> `services` -> `routes/handlers`. Never reverse.
**Detection** (used in Post-REFACTOR validation, TypeScript/Node only):
- `utils/`, `lib/` should not import from `services/`, `routes/`, `components/`
- `services/` should not import from `routes/`, `handlers/`, `pages/`
- `models/`, `types/` should not import from anything except other types/models

### Business logic in handlers/controllers
**Symptom**: Validation, calculations, or state transitions in HTTP handlers or CLI commands.
**Fix**: Extract into a service or utility. The handler should only translate input -> domain call -> output.
**Why**: Logic in handlers is untestable without the framework and gets duplicated across entry points.

### Mocking pure objects
**Symptom**: Using `jest.mock()` or similar to create fake domain entities or value objects instead of constructing real instances.
**Fix**: Pure objects are cheap to construct. Use real instances. Only mock at system boundaries.
**Why**: You're testing your mocks, not your logic.

### Using sleep() / real timers in tests
**Symptom**: Tests use `setTimeout`, `sleep()`, `Task.sleep()`, or real timers to wait for async behavior.
**Fix**: Use virtual time (`vi.useFakeTimers()`, `TestScheduler`, `Clock.mock`). Assert on completion signals, not wall-clock time.
**Why**: Real timers make tests slow, flaky, and non-deterministic. A passing test today fails on a slower CI machine tomorrow.

### Testing non-deterministic features (AI/ML)
**Symptom**: Tests assert exact LLM output text, making them break on every model update.
**Fix**: Assert properties and format, not exact content. Use recording/playback pattern for LLM responses in tests (record real response once, replay deterministically).
**Why**: AI output varies by nature. Test structure, type constraints, and invariants — not verbatim strings.

---

## Notes

### Property-based testing for pure functions
For deterministic, side-effect-free functions (formatters, validators, parsers, math utilities), consider adding property-based tests alongside example-based tests. Use `fast-check` (TypeScript) or `Hypothesis` (Python) to verify invariants across random input distributions. This catches edge cases that hand-picked examples miss.
