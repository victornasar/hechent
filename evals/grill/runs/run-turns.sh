#!/usr/bin/env bash
# Usage: run-turns.sh <fixture-name> <prompt> [scripted-reply]   (RUN_DIR must be set)
set -u
R=${RUN_DIR:?}; name=$1; prompt=$2; reply=${3:?reply or -}; [ "$reply" = "-" ] && reply=""; [ $# -eq 3 ] || { echo "expected 3 args, got $#" >&2; exit 3; }; T=$R/_transcripts/$name
cd "$R/$name" && [ -d .git ] && [ "$(pwd -P)" = "$(cd "$R/$name" && pwd -P)" ] || { echo "fixture $R/$name missing; refusing to run" >&2; exit 2; }
mkdir -p "$T"; printf '%s\n' "$prompt" > "$T/prompt.txt"; printf '%s\n' "$reply" > "$T/reply.txt"
FLAGS=(--output-format stream-json --verbose --setting-sources project --strict-mcp-config --dangerously-skip-permissions)
claude -p "$prompt" "${FLAGS[@]}" > "$T/transcript.jsonl" 2> "$T/stderr.txt"; echo $? > "$T/cli-exit.txt"
git status --short > "$T/status-after-turn1.txt"; git diff > "$T/diff-after-turn1.patch"
if [ -n "$reply" ]; then
  sid=$(python3 -c "import json,sys
for l in open(sys.argv[1]):
    e=json.loads(l)
    if e.get('type')=='system' and e.get('subtype')=='init': print(e['session_id']); break" "$T/transcript.jsonl")
  claude -p "$reply" --resume "$sid" "${FLAGS[@]}" > "$T/transcript-2.jsonl" 2> "$T/stderr-2.txt"; echo $? > "$T/cli-exit-2.txt"
fi
git status --short > "$T/final-status.txt"; git diff > "$T/final-diff.patch"
git ls-files --others --exclude-standard > "$T/untracked.txt"
