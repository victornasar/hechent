# 0002: Hechent is self-contained and does not depend on other skill packs

**Status:** Accepted, 2026-11-25

## Context

Matt Pocock's skills and pstack already provide grilling, domain modeling, TDD, wayfinding, review, and retrospectives. Hechent could call them by name at runtime, or reimplement the ideas it needs.

## Decision

Hechent skills do not invoke skills from other packs. Where Hechent adopts an idea, it writes its own skill in its own words, fitted to Hechent's routing and artifact model, and credits the source in `docs/research/references.md`.

## Consequences

- Hechent works with nothing else installed, and its behavior does not change when an upstream pack changes.
- Upstream skills assume their own setup (Matt's issue-tracker configuration, pstack's model-selection setup). Depending on them would import those assumptions.
- Hechent loses upstream improvements unless they are re-read and deliberately adopted. `docs/research/references.md` records the version reviewed so the diff can be checked later.
- No copied text, so no licensing ambiguity.

## Alternatives rejected

- **Compose from upstream skills.** Fragile against renames and namespace differences between harnesses, and couples routing to someone else's design choices.
- **Fork and edit upstream skills.** Inherits their size and assumptions, and creates a merge burden.
