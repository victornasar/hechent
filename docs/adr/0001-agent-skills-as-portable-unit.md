# 0001: The Agent Skills folder format is the portable unit

**Status:** Accepted, 2026-11-25

## Context

Hechent must work in Cursor and Claude Code today and should not lock out Codex or other agents. The options were a custom source format compiled into each harness's format, one large instruction file per harness, or the open Agent Skills format (`skills/<name>/SKILL.md` with `name` and `description` frontmatter) that several harnesses already load.

## Decision

Skills are written once in the Agent Skills format. Repository-level instructions use `AGENTS.md`. Harness differences are handled by thin adapters in `adapters/<harness>/`, written only after a difference has been observed by installing into that harness.

## Consequences

- No build step and no compiler to maintain.
- Progressive disclosure comes for free: only descriptions are always loaded; bodies load on use.
- Harness-specific features (subagent types, slash commands, invocation policy files) cannot live in skill bodies. Skills describe capabilities; adapters map them.
- If a harness stops supporting the format, the cost is an adapter, not a rewrite.

## Alternatives rejected

- **Custom format plus generators.** Abstraction before the differences are known; a maintenance burden for a solo maintainer.
- **One monolithic instruction file.** Everything loads every turn, which is the context cost skills exist to avoid.
