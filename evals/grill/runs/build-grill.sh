#!/usr/bin/env bash
# Usage: build-grill.sh <scratch> <run-dir-name> <arm: control|base>
set -euo pipefail
S=$1; R=$HOME/verify-blind-runs/$2; ARM=$3; H=/Users/nasarissa/Documents/hechent
rm -rf "$R"; mkdir -p "$R/_transcripts"; : > "$S/jobs-$2.txt"
while IFS=$'\t' read -r base scen prompt reply; do
  for n in 1 2; do
    name=$base-$n; "$H/evals/grill/setup.sh" "$scen" "$R/$name" >/dev/null
    if [ "$ARM" = base ] || [ "$ARM" = grill ]; then
      mkdir -p "$R/$name/.claude/skills"; cp -R "$H/skills/assess" "$H/skills/verify" "$R/$name/.claude/skills/"
      [ "$ARM" = grill ] && cp -R "$H/skills/grill" "$R/$name/.claude/skills/"
      echo ".claude/" >> "$R/$name/.git/info/exclude"
      cp "$H/templates/agents-snippet.md" "$R/$name/AGENTS.md"; echo "AGENTS.md" >> "$R/$name/.git/info/exclude"
    fi
    [ -z "$(cd "$R/$name" && git status --short)" ] || { echo "dirty fixture $name" >&2; exit 1; }
    printf '%s\0%s\0%s\0' "$name" "$prompt" "${reply:--}" >> "$S/jobs-$2.txt"
  done
done < "$S/grill-map.tsv"
