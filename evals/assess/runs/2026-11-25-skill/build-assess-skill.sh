#!/usr/bin/env bash
set -euo pipefail
S=$1; H=/Users/nasarissa/Documents/hechent; R=$HOME/verify-blind-runs/assess-skill
rm -rf "$R"; mkdir -p "$R/_transcripts"; rsync -a ~/Documents/docket/ "$R/_docket/"
: > "$S/assess-skill-jobs.txt"
cp "$H/evals/assess/runs/2026-11-25-control/scenarios.tsv" "$S/assess-skill-map.tsv"
while IFS=$'\t' read -r base scen prompt; do
  for n in 1 2; do
    name=$base-$n; "$H/evals/assess/setup.sh" "$scen" "$R/$name" "$R/_docket" >/dev/null
    mkdir -p "$R/$name/.claude/skills"
    cp -R "$H/skills/assess" "$H/skills/verify" "$R/$name/.claude/skills/"
    echo ".claude/" >> "$R/$name/.git/info/exclude"
    if (cd "$R/$name" && git ls-files --error-unmatch AGENTS.md >/dev/null 2>&1); then
      { echo; cat "$H/templates/agents-snippet.md"; } >> "$R/$name/AGENTS.md"; (cd "$R/$name" && git update-index --skip-worktree AGENTS.md)
    else
      cp "$H/templates/agents-snippet.md" "$R/$name/AGENTS.md"; echo "AGENTS.md" >> "$R/$name/.git/info/exclude"
    fi
    [ -z "$(cd "$R/$name" && git status --short)" ] || { echo "dirty fixture $name" >&2; exit 1; }
    printf '%s\0%s\0' "$name" "$prompt" >> "$S/assess-skill-jobs.txt"
  done
done < "$S/assess-skill-map.tsv"
