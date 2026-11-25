# 0004: Docket stays a separate product and is an optional trust layer

**Status:** Accepted, 2026-11-25

## Context

The same developer maintains Docket (`victornasar/docket`), a kit that makes one unit of agent work trustworthy: a human-approved Ticket before code, Evidence bound to the worktree by mechanical gates (`docket verify`, `check-scope`, `check-evidence`, `pre-review`), an independent read-only Review, and Done as an evidence-backed state.

Hechent makes agents better at the engineering itself: assessing, planning, implementing, verifying, reviewing, improving. The two touch at three points (tickets, verification, review), so they could be merged, one could absorb the other, or they could stay apart with a defined handoff.

## Decision

Hechent and Docket remain separate repositories and separate products.

- Hechent owns engineering capability: how to approach and execute the work.
- Docket owns engineering trust: whether the work stayed inside an approved contract and is backed by enough current evidence to be Done.
- Each is useful without the other. Neither imports the other's code or depends on its internal structure.
- When Docket is attached to a repository, Hechent works inside Docket's process through a file-and-CLI handoff defined in [DOCKET-INTEGRATION.md](../../DOCKET-INTEGRATION.md). Docket's rules win wherever they apply.
- Hechent never approves a Ticket, never decides one is Done (it may only record a Docket Review Pass through Docket's own completion procedure), never substitutes its own review for Docket's Review, and never claims Docket validated anything it did not.

## Why

- **Independence of the check.** Docket's value is that its gates do not trust the agent. If the methodology that does the work also owns the gates that judge it, the check is no longer independent. Keeping the products apart keeps the incentive structure honest.
- **Different change rates.** Engineering procedures will change often as Stage 4 scenarios expose failures. Trust gates should change rarely and deliberately.
- **Each stands alone.** A developer may want disciplined agents without a ticket gate on every change (Hechent alone), or a trust gate around any agent's work (Docket alone).

## Consequences

- The integration is the Docket Ticket file itself plus Docket's documented CLI. No new file format, package, API, or service.
- Hechent calls Docket's CLI. This is use of a public interface, not a skill dependency, so it is consistent with [ADR 0002](0002-ideas-not-dependencies.md).
- In attached mode, Docket's ticket-before-code applies to every code change, including work Hechent would one-shot. Hechent's path choice then sets planning depth before the Ticket, not whether a Ticket exists.
- In attached mode, the Docket Ticket is the only ticket artifact. Hechent does not also write its own tickets for the same work.
- Docket currently ships capability recipes (code review, diagnosis, domain modeling, TDD, program design) that overlap Hechent's planned skills. That overlap is recorded as an open question in DOCKET-INTEGRATION.md and is for Docket to resolve.

## Alternatives rejected

- **Merge into one product.** Couples fast-moving procedures to slow-moving gates, and puts the judge and the judged in the same codebase.
- **Hechent requires Docket.** Forces ticket ceremony onto trivial work and onto users who do not want the gate.
- **A shared library or schema package.** No concrete need yet. The Ticket Markdown and CLI exit codes already form a contract.
