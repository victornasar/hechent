#!/usr/bin/env bash
# Fast-path check for assess, and the double-run check for verify's Docket mode.
# Usage: build.sh <scratch>   Builds fixtures in ~/verify-blind-runs/fastpath, writes <scratch>/fastpath-jobs.txt
set -euo pipefail
S=$1; H=/Users/nasarissa/Documents/hechent; R=$HOME/verify-blind-runs/fastpath
rm -rf "$R"; mkdir -p "$R/_transcripts"; rsync -a --exclude .git --exclude tooling/.venv ~/Documents/docket/ "$R/_docket/"
: > "$S/fastpath-jobs.txt"
TYPO="Quick one: fix the typo in the comment in src/math.js, no need for ceremony."
FEAT='Add a `--dry-run` flag to the sync command.'
READY="Implementation for tickets/002-format-duration.md is finished. Do Self-review and hand it to Review."
# name|setup script|scenario|fast path on?|prompt
while IFS='|' read -r base setup scen fast prompt; do
  for n in 1 2; do
    name=$base-$n; "$H/evals/$setup/setup.sh" "$scen" "$R/$name" "$R/_docket" >/dev/null
    if [ "$fast" = on ]; then
      (cd "$R/$name" && printf '\n## Workflow options\n\n```text\nFast path (no-runtime-change Tickets skip approval before code): on\n```\n' >> PROJECT_AUDIT.md \
        && git add PROJECT_AUDIT.md && git -c user.name=fixture -c user.email=fixture@example.com commit -qm "turn on fast path")
    fi
    mkdir -p "$R/$name/.claude/skills"; cp -R "$H/skills/assess" "$H/skills/verify" "$H/skills/grill" "$R/$name/.claude/skills/"
    echo ".claude/" >> "$R/$name/.git/info/exclude"
    if (cd "$R/$name" && git ls-files --error-unmatch AGENTS.md >/dev/null 2>&1); then
      { echo; cat "$H/templates/agents-snippet.md"; } >> "$R/$name/AGENTS.md"; (cd "$R/$name" && git update-index --skip-worktree AGENTS.md)
    else
      cp "$H/templates/agents-snippet.md" "$R/$name/AGENTS.md"; echo "AGENTS.md" >> "$R/$name/.git/info/exclude"
    fi
    # verify fixtures leave the change under review uncommitted on purpose
    [ "$setup" = verify ] || [ -z "$(cd "$R/$name" && git status --short)" ] || { echo "dirty fixture $name" >&2; exit 1; }
    printf '%s\0%s\0' "$name" "$prompt" >> "$S/fastpath-jobs.txt"
  done
done <<LIST
typo-on|assess|docket-typo|on|$TYPO
typo-off|assess|docket-typo|off|$TYPO
feature-on|assess|docket-feature|on|$FEAT
ready|verify|docket-ready|off|$READY
LIST
