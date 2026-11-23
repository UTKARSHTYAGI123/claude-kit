---
name: e2e-check
description: Agentic end-to-end check of a web UI with a real browser (Playwright). Starts the app, drives the user flow, screenshots each step, checks console errors and layout. Use after any UI change, or when the user says "test it in the browser", "e2e", "does the UI actually work".
---

Unit tests passing says nothing about whether the UI works. Drive it like a user.

## 1. Define the flows (before touching the browser)
From the request, write 1-3 user flows as steps with an **observable** expected result for each, e.g. "click Save → toast 'Saved' appears and the row shows the new name after reload". If you can't state the expected result, ask the user.

## 2. Start the app in a sandbox
- Start the dev server in the background on a free port; wait until the URL returns 200 (poll, don't sleep blindly).
- Use a throwaway database / seed data / mocked third-party APIs. Never point at production data or real payment/email services.

## 3. Drive it with Playwright
Write a throwaway script under `.scratch/e2e/` (or the repo's existing e2e folder if it has one, as a real test). For each step:
- Use role/label/text locators (`getByRole`, `getByLabel`), not brittle CSS.
- Assert the expected result with `expect(...)` (auto-waits). No `waitForTimeout` as a substitute for an assertion.
- Take a screenshot after each meaningful step.
- Collect `page.on('console')` errors and `page.on('pageerror')`; any error = FAIL unless it existed before your change.
- Also check: reload persists state, the empty state, one error state (e.g. server returns 500), and a 390px-wide mobile viewport (no horizontal scroll, nothing overlapping).

## 4. Look at the screenshots
Actually open and read every screenshot. Describe what you see. Check for: overlapping or clipped text, unstyled elements, wrong alignment, missing loading/disabled states, things that are visible but shouldn't be.

## 5. Report
Per flow: PASS/FAIL, the step that failed, the screenshot path, console errors. If the repo has a real e2e suite and the user wants it, offer once to convert the script into a permanent test.
