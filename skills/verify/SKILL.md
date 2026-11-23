---
name: verify
description: Prove a change works before calling it done. Runs the project's real checks, then hands the diff to an independent verifier agent that tries to break it. Use after any implementation, before saying "done", or when the user says "verify", "prove it", "are you sure".
---

You are not allowed to say "done", "fixed" or "works" until this skill passes. Evidence beats confidence.

## 1. Restate the contract
In 3-6 bullets, write exactly what the user asked for, quoted or paraphrased from the conversation. This is the ONLY scope. Anything in the diff not traceable to a bullet is scope creep.

## 2. Self-audit the diff (`git diff` + untracked files)
For every hunk, answer: which contract bullet needs this? Flag and **remove** (or ask about) anything that isn't:
- Validation, null checks, try/catch or fallbacks for cases that can't happen, or that the user didn't ask for. Validate at system boundaries (user input, network, files) only.
- New features, options, config flags, "while I was here" refactors, extra UI states.
- Swallowed errors, `any`/casts, skipped or `.only` tests, deleted or weakened assertions, hardcoded values that make a test pass.

## 3. Run the real checks
Discover them from the repo (package.json scripts, Makefile, CI config, pyproject). Run every one that applies: typecheck, lint, unit tests, build. Show the actual command and the tail of real output. A check you didn't run is reported as **NOT RUN**, never as passing.

## 4. Exercise the behaviour
- UI change → run the `e2e-check` skill.
- API/CLI change → start it and hit it for real (curl / run the command) with the happy path and one realistic edge case.
- Bug fix → reproduce the bug *before* the fix (or show a test that failed before), then show it gone.

## 5. Independent verification
Spawn the `verifier` agent (fresh context; it has not seen your reasoning). Give it ONLY: the contract bullets, the base ref to diff against, and how to run the app/tests. Do not tell it what you think is fine. Wait for its report.

## 6. Report
A table: check | command | result (PASS / FAIL / NOT RUN) | evidence. Then the verifier's findings verbatim, and what you changed in response. If anything failed, the status is **NOT DONE**, whatever else passed.

## 7. Stamp it (only on full PASS)
Run `~/.claude/hooks/require-verify.sh --stamp`. The stop hook checks this stamp, so any edit after verifying means verifying again.
