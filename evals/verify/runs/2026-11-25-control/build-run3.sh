#!/usr/bin/env bash
set -euo pipefail
S=$1; H=/Users/nasarissa/Documents/hechent; R=$HOME/verify-blind-runs/run3
rm -rf "$R"; mkdir -p "$R/_transcripts"; rsync -a ~/Documents/docket/ "$R/_docket/"
: > "$S/run3-map.tsv"
for scen in docs-only:docs-lib browser-broken:todo-app preexisting-failure:slug-lib docket-stale:pricing permissions:auth-svc; do
  s=${scen%%:*}; base=${scen##*:}
  arms=$(printf 'skill\ncontrol\nskill\ncontrol\n' | python3 -c "import sys,random;l=sys.stdin.read().split();random.seed('$s');random.shuffle(l);print(' '.join(l))")
  n=1
  for arm in $arms; do
    name=$base-$n; "$H/evals/verify/setup.sh" "$s" "$R/$name" "$R/_docket" >/dev/null
    if [ "$arm" = skill ]; then
      mkdir -p "$R/$name/.claude/skills"; cp -R "$H/skills/verify" "$R/$name/.claude/skills/verify"; echo ".claude/" >> "$R/$name/.git/info/exclude"
      if (cd "$R/$name" && git ls-files --error-unmatch AGENTS.md >/dev/null 2>&1); then
        { echo; cat "$H/templates/agents-snippet.md"; } >> "$R/$name/AGENTS.md"; (cd "$R/$name" && git update-index --skip-worktree AGENTS.md)
      else
        cp "$H/templates/agents-snippet.md" "$R/$name/AGENTS.md"; echo "AGENTS.md" >> "$R/$name/.git/info/exclude"
      fi
    fi
    printf '%s\t%s\t%s\n' "$name" "$s" "$arm" >> "$S/run3-map.tsv"; n=$((n+1))
  done
done
