---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

> **Docs are optional (local override).** `GLOSSARY.md`, ADRs, `docs/agents/*`, issue-tracker config and similar files are *nice to have*, never prerequisites. If they're missing: don't stop, don't tell the user to run `/setup-matt-pocock-skills`, and don't create them on your own. Use whatever exists, infer the rest from the code and conversation, and keep going. If a doc would genuinely help, offer it **once** at the end in one line; write it only if the user says yes. Default issue tracker when none is configured: just report in chat.

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, call the Skill tool with "code-review" to review the work.

Commit your work to the current branch.
