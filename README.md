# Skills

Custom AI Agent Skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by Kirill Oleinichenko.

## Available Skills

| Skill | Description |
|-------|-------------|
| [attack-surface](attack-surface/) | Strategic research framework that compresses months of market research into hours through 3 power questions |
| [deep-research](deep-research/) | Multi-source research with inline citations, source quality tiers, contradictions analysis, and adversarial review |
| [first-principles](first-principles/) | Multi-pass first principles analysis that decomposes problems to fundamental truths through 4 universal lenses |
| [tdd](tdd/) | Spec-driven Test-Driven Development with strict Red-Green-Refactor cycle and three context-isolated subagents |

## What Are Skills?

Skills are specialized knowledge modules for Claude Code — structured prompts that teach the AI agent how to perform complex multi-step workflows. Each skill is a self-contained folder with a `SKILL.md` definition and optional reference files.

## Installation

Copy any skill folder to your Claude Code skills directory:

```bash
cp -r <skill-name>/ ~/.claude/skills/<skill-name>/
```

## License

MIT
