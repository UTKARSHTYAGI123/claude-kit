#!/usr/bin/env bash
# Stop hook: block finishing once if code changed since the last successful /verify.
#   require-verify.sh          -> hook mode (reads hook JSON on stdin)
#   require-verify.sh --stamp  -> record the current working tree as verified
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
cd "$(git rev-parse --show-toplevel)"
if command -v sha256sum >/dev/null; then SHA="sha256sum"; else SHA="shasum -a 256"; fi
state_hash() {
  { git diff HEAD -- . ':!.scratch'
    git ls-files --others --exclude-standard -- . ':!.scratch' | tr '\n' '\0' | xargs -0 $SHA 2>/dev/null
  } | $SHA | cut -d' ' -f1
}
if [ "$1" = "--stamp" ]; then mkdir -p .scratch; state_hash > .scratch/.verified; echo "verified stamp written"; exit 0; fi

input=$(cat)
echo "$input" | grep -q '"stop_hook_active": *true' && exit 0   # never loop
changes=$( { git diff HEAD --name-only; git ls-files --others --exclude-standard; } | grep -vE '^\.scratch/|\.(md|snippet)$' )
[ -z "$changes" ] && exit 0
[ -f .scratch/.verified ] && [ "$(cat .scratch/.verified)" = "$(state_hash)" ] && exit 0
echo "Code changed but has not been verified. Run the verify skill (real checks plus the verifier agent) before finishing, or tell the user exactly which checks were NOT RUN and why." >&2
exit 2
