# AI workflow kit

Matt Pocock's skills (snapshot of github.com/mattpocock/skills @ abeeaf9, MIT), with a "docs are optional" override added, plus verification tooling.

## Install
macOS / Linux:

    git clone https://github.com/UTKARSHTYAGI123/claude-kit ~/claude-kit && ~/claude-kit/install.sh --link

Windows (PowerShell):

    git clone https://github.com/UTKARSHTYAGI123/claude-kit $HOME\claude-kit
    powershell -ExecutionPolicy Bypass -File $HOME\claude-kit\install.ps1 -Link

Update: `git pull` in the clone, then re-run the install command.
This puts everything in `~/.claude/skills/` (the same folder `grill-me` lives in) and `~/.claude/agents/verifier.md`. Any existing skill with the same name is backed up as `<name>.bak.<timestamp>`.

## The loop
1. `/grill-me`: use it when you're not sure about a feature. It interviews you before anything gets built.
2. Implement (`/tdd` or `/implement`).
3. `/verify` runs real checks, a scope-creep audit and the independent `verifier` agent.
4. `/e2e-check` drives UI changes in a real browser (Playwright, screenshots, console errors, mobile width).
5. The stop hook blocks "done" once if code changed since the last passing `/verify`.

## What's what
| Piece | Stops |
|---|---|
| `CLAUDE.md.snippet` | unrequested validations and features |
| `verify` skill | "it works" with no evidence; scope creep |
| `verifier` agent | the author grading its own homework; deleted, skipped or hollow tests |
| `e2e-check` skill | buggy UI that unit tests miss |
| `hooks/require-verify.sh` | skipping verification entirely |

Skipped: the `in-progress/` skills from the repo (drafts). Note that Matt's `code-review` shadows the built-in `/code-review`. Delete `~/.claude/skills/code-review` if you prefer the built-in one.
