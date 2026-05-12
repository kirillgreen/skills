# Test Framework Configurations

Detection rules, run commands, and minimal test skeletons per framework.

---

## Vitest (TypeScript/JavaScript)

**Detection**: `vitest` in package.json devDependencies, or `vitest.config.ts/js`

**Run commands**:
```bash
npx vitest run                                    # All tests (run once)
npx vitest run path/to/file.test.ts               # Single file
npx vitest run path/to/file.test.ts -t "name"     # Single test by name
npx vitest run --coverage                         # With coverage
```

**File conventions**: `*.test.ts`, `*.spec.ts`, or files in `__tests__/`

**Skeleton**:
```typescript
import { describe, it, expect } from 'vitest'

describe('ModuleName', () => {
  it('should [behavior]', () => {
    // Arrange
    const input = /* ... */

    // Act
    const result = functionUnderTest(input)

    // Assert
    expect(result).toBe(expected)
  })
})
```

---

## Swift Testing (iOS 16+, Xcode 16+)

**Detection**: `Package.swift` with test targets, or `import Testing` in test files

**Run commands**:
```bash
swift test --filter {TestSuite}                    # Single suite
swift test                                         # All tests
xcodebuild test -scheme {scheme} -only-testing:{target}/{class}  # Xcode
```

**File conventions**: `*Tests.swift` in test target

**Skeleton**:
```swift
import Testing
@testable import App

@Suite("Feature Tests")
struct FeatureTests {
    @Test("should [behavior]")
    func shouldBehavior() {
        // Arrange
        let input = /* ... */

        // Act
        let result = featureUnderTest(input)

        // Assert
        #expect(result == expected)
    }
}
```

**Key differences from XCTest**:
- `@Test` instead of `func testXxx()`
- `#expect()` instead of `XCTAssertEqual()`
- `@Suite` for grouping
- Can use `throws` and `async` naturally
- No `setUp`/`tearDown` — use init/deinit or `@Test(.enabled(if:))`

---

## XCTest (Legacy iOS)

**Detection**: `*Tests/` Xcode directories with `import XCTest`

**Run commands**:
```bash
xcodebuild test -scheme {scheme} -only-testing:{target}/{class}
xcodebuild test -scheme {scheme} -destination 'platform=iOS Simulator,name=iPhone 16'
```

**File conventions**: `*Tests.swift` in XCTest target, classes extending `XCTestCase`

**Skeleton**:
```swift
import XCTest
@testable import App

final class FeatureTests: XCTestCase {
    func testShouldBehavior() {
        // Arrange
        let input = /* ... */

        // Act
        let result = featureUnderTest(input)

        // Assert
        XCTAssertEqual(result, expected)
    }
}
```

---

## Bun

**Detection**: `bun test` in package.json scripts, or bun as runtime

**Run commands**:
```bash
bun test                           # All tests
bun test path/to/file.test.ts      # Single file
```

**File conventions**: `*.test.ts` alongside source

**Skeleton**:
```typescript
import { describe, it, expect } from 'bun:test'

describe('ModuleName', () => {
  it('should [behavior]', () => {
    // Arrange
    const input = /* ... */

    // Act
    const result = functionUnderTest(input)

    // Assert
    expect(result).toBe(expected)
  })
})
```

---

## Jest (Reference — Vitest-compatible API)

**Detection**: `jest` in package.json devDependencies, or `jest.config.js/ts/mjs`

**Run commands**:
```bash
npx jest                                     # All tests
npx jest path/to/file.test.ts                # Single file
npx jest --testPathPattern=file -t "name"    # Single test by name
npx jest --coverage                          # With coverage
```

**File conventions**: Same as Vitest. API is compatible.

**Skeleton**: Same as Vitest (uses same `describe`/`it`/`expect` API), but imports are auto-global.

---

## pytest (Python)

**Detection**: `pytest` in pyproject.toml/setup.cfg, `pytest.ini`, `conftest.py`

**Run commands**:
```bash
pytest -v                                         # All tests
pytest tests/test_module.py -v                    # Single file
pytest tests/test_module.py::test_function -v     # Single test
pytest -k "keyword" -v                            # By keyword
pytest --cov=src -v                               # With coverage
```

**File conventions**: `test_*.py` or `*_test.py`, functions prefixed with `test_`

**Skeleton**:
```python
def test_should_behavior():
    # Arrange
    input_data = ...

    # Act
    result = function_under_test(input_data)

    # Assert
    assert result == expected
```

---

## Cross-Framework Rules

| Rule | All Frameworks |
|------|----------------|
| Test name | Describes behavior, not implementation (`should format bytes` not `test_format`) |
| Structure | Arrange-Act-Assert (AAA), clearly delineated |
| Isolation | Each test independent, no shared mutable state |
| Scope | 3-7 tests initially: happy path + 2-3 edge cases + 1 error case |
| Assertions | One logical assertion per test (multiple `expect` ok if testing one behavior) |
