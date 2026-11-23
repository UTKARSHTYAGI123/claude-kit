---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

> **Docs are optional (local override).** `GLOSSARY.md`, ADRs, `docs/agents/*`, issue-tracker config and similar files are *nice to have*, never prerequisites. If they're missing: don't stop, don't tell the user to run `/setup-matt-pocock-skills`, and don't create them on your own. Use whatever exists, infer the rest from the code and conversation, and keep going. If a doc would genuinely help, offer it **once** at the end in one line; write it only if the user says yes. Default issue tracker when none is configured: just report in chat.

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) - not the current workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
