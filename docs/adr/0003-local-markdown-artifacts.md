# 0003: Work artifacts are local Markdown by default

**Status:** Accepted, 2026-11-25

## Context

Specs, tickets, wayfinder maps, and evidence need a home in the target repository. Matt Pocock's skills default to an issue tracker (GitHub or Linear) with native blocking links, falling back to local files. The primary user is a solo developer working across many repositories, some without a remote or tracker.

## Decision

All Hechent artifacts are Markdown files in the target repository. Working artifacts live under `.hechent/work/<slug>/` and are gitignored by default. Durable knowledge goes to conventional committed locations: `GLOSSARY.md`, `docs/adr/`, and `.hechent/lessons.md`. An issue-tracker backend may be added later as an adapter.

## Consequences

- Works offline, with any harness, in any repo, with no setup step.
- Artifacts are readable and diffable by the agent with ordinary file tools, which is cheaper than API calls.
- No native blocking visualization or multi-person claiming, which matter less to a solo developer.
- Gitignored work artifacts do not survive a fresh clone. The PR description and ADRs are the permanent record, so anything worth keeping must be promoted there before merge.

## Alternatives rejected

- **Issue tracker by default.** Requires configuration per repo and a network, and adds tool calls to every read.
- **Commit work artifacts.** Adds planning files to every PR diff and leaves stale specs in the tree after merge.
