#!/usr/bin/env bash
# One-command, re-runnable install into ~/.claude (user-level = every project).
#   ./install.sh          copy files (default)
#   ./install.sh --link   symlink instead, so `git pull` in this repo updates everything
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
MODE="${1:-copy}"
mkdir -p "$DEST/skills" "$DEST/agents" "$DEST/hooks"

put() { # put <src> <dst>
  if [ -L "$2" ]; then rm "$2"
  elif [ -e "$2" ] && ! grep -q "ai-workflow-kit" "$DEST/.kit-managed" 2>/dev/null; then mv "$2" "$2.bak.$(date +%s)"
  else rm -rf "$2"; fi
  if [ "$MODE" = "--link" ]; then ln -s "$1" "$2"; else cp -r "$1" "$2"; fi
}
for s in "$DIR"/skills/*/; do put "${s%/}" "$DEST/skills/$(basename "$s")"; done
put "$DIR/agents/verifier.md" "$DEST/agents/verifier.md"
put "$DIR/hooks/require-verify.sh" "$DEST/hooks/require-verify.sh"
chmod +x "$DIR/hooks/require-verify.sh"
echo "ai-workflow-kit" > "$DEST/.kit-managed"

# Merge the Stop hook into settings.json (keeps everything else you have there).
python3 - "$DEST/settings.json" "$DEST/hooks/require-verify.sh" <<'PY'
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
s = json.load(open(path)) if os.path.exists(path) and os.path.getsize(path) else {}
stop = s.setdefault("hooks", {}).setdefault("Stop", [])
if not any(h.get("command") == cmd for g in stop for h in g.get("hooks", [])):
    stop.append({"hooks": [{"type": "command", "command": cmd}]})
json.dump(s, open(path, "w"), indent=2)
PY

# Add the working rules to ~/.claude/CLAUDE.md between markers (replaced on re-run).
MD="$DEST/CLAUDE.md"; touch "$MD"
python3 - "$MD" "$DIR/CLAUDE.md.snippet" <<'PY'
import re, sys
md, snip = sys.argv[1], open(sys.argv[2]).read().strip()
block = f"<!-- ai-workflow-kit:start -->\n{snip}\n<!-- ai-workflow-kit:end -->"
t = open(md).read()
t = re.sub(r"<!-- ai-workflow-kit:start -->.*?<!-- ai-workflow-kit:end -->", lambda _: block, t, flags=re.S) if "ai-workflow-kit:start" in t else (t.rstrip() + "\n\n" + block + "\n").lstrip()
open(md, "w").write(t)
PY
echo "ai-workflow-kit: $(ls "$DIR/skills" | wc -l | tr -d ' ') skills, verifier agent, stop hook and CLAUDE.md rules installed in $DEST ($MODE)"
