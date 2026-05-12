# tdd

A Claude Code skill that runs strict spec-driven Test-Driven Development with three context-isolated subagents (RED, GREEN, REFACTOR).

## What it does

Most "TDD with AI" looks like this: ask for a feature, get tests and implementation in the same response, both shaped to agree with each other. The tests don't catch bugs because they were written knowing the implementation. The implementation is over-built because nothing forces it to stay minimal.

This skill enforces the discipline:

1. **Spec** — write or extract numbered acceptance criteria (`AC-1`, `AC-2`, …, edge cases `EC-*`, error cases `ERR-*`). Lock the spec before any code is written.
2. **RED** — a `tdd-test-writer` subagent (no access to implementation) writes failing tests, one per criterion. The orchestrator verifies they actually fail before continuing.
3. **GREEN** — a `tdd-implementer` subagent writes the minimum code to pass. It cannot modify test files. The orchestrator validates that no test was weakened and only files in scope were touched.
4. **REFACTOR** — a `tdd-refactorer` subagent improves the code while keeping tests green. Reverts everything if any test breaks.
5. **Verify** — the orchestrator builds a traceability matrix mapping every `AC-*` / `EC-*` / `ERR-*` criterion to a passing test. Gaps are reported, not hidden.

Each phase is gated. The orchestrator will not move on until the previous gate is green.

## Why use it

The structural value is **subagent isolation**. The agent writing tests has never seen the implementation. The agent writing implementation cannot weaken tests. This breaks the feedback loop where AI quietly writes both sides to agree, which is the failure mode that makes most LLM-driven TDD worthless.

Other things this skill does that ad-hoc TDD doesn't:

- **Spec quality lint** before locking — catches subjective language ("fast", "robust"), compound criteria, missing examples
- **Post-RED lint** — flags over-mocking, weak assertions, tests of private internals, missing imports
- **Implementation scope check** — implementer is told exactly which files it may touch; out-of-scope edits are reported
- **Spec coverage matrix** at the end — every criterion → test mapping, with explicit "MISSING" markers for gaps
- **Final quality gate** — full test suite + type check + build, not just the targeted file

## Supported test frameworks

Auto-detected from project files:

| Framework | Detection |
|-----------|-----------|
| Vitest | `vitest.config.*` or `vitest` in `package.json` |
| Bun test | `bun test` script in `package.json`, `bun.lock`/`bun.lockb` |
| Swift Testing | `Package.swift` with test targets, `import Testing` |
| XCTest | `*Tests/` Xcode dirs with `import XCTest` |
| Jest | `jest` in `package.json` (Vitest-compatible API) |
| pytest | `pytest` in `pyproject.toml` / `setup.cfg`, `pytest.ini` |

If no framework is detected, the skill stops and asks you to set up testing first — it will not auto-install dependencies.

## Structure

```
tdd/
├── SKILL.md                       # Orchestrator — phase gates, examples, anti-patterns
├── README.md                      # This file
├── agents/
│   ├── tdd-test-writer.md         # RED phase subagent
│   ├── tdd-implementer.md         # GREEN phase subagent
│   └── tdd-refactorer.md          # REFACTOR phase subagent
└── references/
    ├── anti_patterns.md           # TDD anti-patterns with examples
    └── framework_configs.md       # Per-framework run commands and skeletons
```

## Installation

Two steps — the skill and its three subagents go to different directories.

```bash
# 1. Install the skill
cp -r tdd ~/.claude/skills/

# 2. Install the three subagents
cp tdd/agents/*.md ~/.claude/agents/
```

For project-scoped installation, replace `~/.claude/` with `your-project/.claude/`.

After installing, `/tdd` becomes available as a slash command.

## Usage

```
/tdd add file size formatting utility
```

```
/tdd implement product search filtering
```

```
/tdd add card flip animation
```

You can also reference an existing spec doc with `@file`:

```
/tdd @docs/avatar-upload.md
```

When invoked, the skill will:

1. Detect your test framework
2. Either extract acceptance criteria from the referenced doc, or write a spec for you to review
3. Wait for you to confirm or modify the spec before any code is written
4. Run the RED → GREEN → REFACTOR cycle, gating each phase
5. Report a spec-coverage matrix at the end

## License

MIT
