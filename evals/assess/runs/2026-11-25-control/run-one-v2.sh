#!/usr/bin/env bash
# Usage: run-one.sh <fixture-name> <prompt>
set -u
R=${RUN_DIR:?}; name=$1; prompt=$2; T=$R/_transcripts/$name
mkdir -p $T; printf '%s\n' "$prompt" > $T/prompt.txt
cd "$R/$name" && [ -d .git ] && [ "$(pwd -P)" = "$(cd "$R/$name" && pwd -P)" ] || { echo "fixture $R/$name missing; refusing to run" >&2; exit 2; }
date -u +%FT%TZ > $T/started.txt
claude -p "$prompt" --output-format stream-json --verbose \
  --setting-sources project --strict-mcp-config --dangerously-skip-permissions \
  > $T/transcript.jsonl 2> $T/stderr.txt
echo $? > $T/cli-exit.txt
date -u +%FT%TZ > $T/finished.txt
git status --short > $T/final-status.txt
git diff > $T/final-diff.patch
git ls-files --others --exclude-standard > $T/untracked.txt
for f in $(cat $T/untracked.txt); do echo "=== $f"; cat "$f"; done > $T/untracked-contents.txt 2>/dev/null
