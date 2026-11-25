# Run 4: Docket passing path + Cursor permissions

Blind evaluations closing the two coverage gaps left after Run 3.

| Directory | Scenario | Harness |
|---|---|---|
| `duration-lib/` | `docket-ready` (final airtight fixture) | Claude Code `claude -p`, skill arm |
| `duration-lib-attempt1-fixture-gap/` | earlier fixture; Spec-gap on rounding | same |
| `duration-lib-attempt2-approach-gap/` | earlier fixture; Approach/invalid-input escalations | same |
| `auth-svc-cursor/` | `permissions` | Cursor Agent (Task tool; `cursor-agent` CLI lacked auth) |

Live working copies also under `~/verify-blind-runs/run4/`.
