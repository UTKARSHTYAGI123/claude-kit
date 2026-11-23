# QA playbook: testing a PR with Claude

How to get Claude to test someone's PR deeply and safely. Based on QA of PR 69 (news digest), where Claude found 13 real problems and posted them with regression tests.

## What went wrong in that run (and why it matters)

The first full run had 14 failing tests. Four of those failures were mistakes in Claude's own tests, not bugs in the PR:

| Wrong test | What Claude did | Why it looked like a bug |
|---|---|---|
| Bad images kept, slow image logged | Put 5 or more stories in a section that holds at most 4 | The extra stories were never picked, so they looked "missing" and the image warning never appeared |
| Timer sends twice after Send now | Moved the fake clock from 19:00 forward 7 hours | That crossed midnight, so the timer correctly sent the *next* day's email |
| Retry fills a held email (first version) | Same midnight crossing | The retry ran on a different day from the held email |
| AI returns odd types | The fake AI broke every reply, including a later retry call with fewer stories | The fake AI itself crashed, and the app reported that crash as its own |

A fifth, milder slip: the fake feed gave old stories a fresh date whenever the clock moved. The reviewer agent caught that this made one finding look worse than it is. Separately, the PR's own test suite has a test with `2026-11-23` written into it, so it fails depending on the clock and timezone.

None of these reached you. Before reporting, each failure was traced to its cause, debugged with prints, and fixed in the test. The independent `verifier` agent then re-checked every finding. The lesson: **a failing test is a claim, not a finding.** Fake setups have their own rules (caps, clocks, call order) and break them easily.

Rules that came out of it (also in `CLAUDE.md.snippet`):
1. Before calling a failure a bug, rule out the test: limits and caps in the fake data, clock and date crossings, the fake's own call order.
2. Pin time: a fixed start such as 06:00 UTC, a fixed timezone, and never let a test move across midnight unless that is the point.
3. Have the `verifier` agent try to disprove findings before you share them.

## How to run this yourself

**1. Ask for the plan first, not the work.** Make a requirements list and say "don't start, discuss how you'd approach it". Copy this:

```
Test PR <link>. Requirements: <list, e.g. "min 6 stories", "images not distorted",
"errors logged", "works when a source fails">. Don't start: discuss how you'd test
it, what you'd fake, what you can't test, token cost, and what you need from me.
```

**2. Answer the decisions.** The plan ends with questions. The ones that matter:
- **Fixtures or real data?** Fixed fake data (feeds, pages, images) makes failures repeatable and costs no API usage. Real data finds real-world surprises but varies from run to run. Start with fixtures.
- **Real AI?** Only for judging output quality and consistency, and only with a written rubric you approve.
- **Where results go:** chat only, a file, or a PR comment.

**3. Let it run, then read the report.** A good report:
- lists every requirement as PASS, FAIL or NOT RUN
- shows evidence for each failure (the exact output, not "seems broken")
- says what it could not test

**4. Ask for priorities:** "which are P0 and P1?" P0 = mail, data or users actually broken; P1 = a stated requirement broken; P2 = rare or cosmetic.

**5. Share it:** "write these up as a PR comment", then "post it". Claude drafts first and posts only when you say so.

**6. Get regression tests:** ask for "tests in the repo's own style that fail now and pass when fixed". Hand them to whoever fixes the PR.

**7. Re-check after fixes:** in the same session, while it still has its test setup, ask it to re-run everything against the new code.

## Using it safely

- **Never real email, payments or messages.** Ask for file or outbox mode and a fake mail server. Say it out loud in the request.
- **Don't let it touch the team's branch.** Claude reads the PR without creating a branch and works in a temporary copy. It doesn't push to someone else's PR.
- **Outward actions need your yes:** posting comments, pushing, and anything sent to an outside service. Claude drafts and asks; check the draft before you say "post".
- **No secrets in test files or comments.** Use fake keys; real ones go through the environment's secret settings, never chat.
- **Temporary folders vanish** when the cloud session ends. Anything worth keeping goes into a repo, a PR comment, or a file sent to you.
- **NOT RUN is honest, not a failure.** If the report says something wasn't tested (Outlook rendering, live feeds), don't treat that area as checked.

## Getting the most out of it

- **Give testable requirements.** "Good quality" can't be checked; "every story has a description, a takeaway and a picture under X" can.
- **Ask for failure injection, not only happy paths:** "break each step on purpose and tell me if mail still goes out".
- **Ask for measurements:** for UI and email, "render it in a browser at 600px and 390px and measure", not "looks fine".
- **Keep the reviewer agent in the loop:** "have the verifier try to disprove the findings" catches false alarms like the four above.
- **Turn findings into tests every time,** so a bug fixed once stays fixed.
- **Budget:** a deep PR QA like this one took roughly 400 to 700k tokens. A focused re-check after fixes takes much less.

## Related pieces of the kit

| Piece | Use it for |
|---|---|
| `/verify` and the `verifier` agent | proving your own change works; a fresh agent tries to break it |
| `/e2e-check` | UI flows in a real browser, with screenshots |
| `/grill-me` | when you're unsure what the feature should even do |
| `/tdd` | fixing the findings test-first, using the regression tests |
