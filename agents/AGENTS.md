# Agent instructions

## General Guidelines
- Never use the em-dash "—". Use plain dash "-" instead.
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- When doing bug-fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end-user would experience it as possible. This is to ensure that the fix is not just a workaround but a genuine bug fix.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection. If something looks off, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, program design, performance, and test flakiness. If you see one, even if it is not caused by what you are working on right now, still get it fixed. (Boyscout rule!)

## Engineering standards
We're a startup. You're probably used to writing enterprise code -- code that tries to handle every possible edge case and has fallbacks for everything. That's not how we do things around here: our number one rule is to keep things simple. We handle ONLY the most important cases.

We try to only add new functionality that is small (that is, simple and few lines of code) or absolutely necessary. If a change is not small or absolutely necessary, don't make it.

- Default to the simplest design that is correct, robust, and maintainable. Don't cut corners to save time. Equally, don't add abstraction, configuration, or scaling machinery for needs that don't exist yet.
- Fix bugs at the root, not the symptom. Before fixing, reproduce the bug end-to-end, as close to the real user's path as possible. The reproduction is what proves the fix is real and not a workaround.
- Hold the UI to a high bar. If something looks wrong: fix it when it's small and adjacent, flag it when it's larger or out of scope. Don't silently expand the change.
- Boyscout rule with scope discipline: leave things better than you found them, but keep every change reviewable. Small adjacent issues (a lint warning, a flaky test, a typo) get fixed. Anything larger or unrelated gets surfaced, not folded into the current work.
- Tautological tests are considered harmful.
**Backwards-compatibility**: When changing existing functionality, you might wonder whether we need to ensure backwards-compatibility. As a rule of thumb:
  - If the change is local to the workspace (part of the current workspace diff, i.e., uncommitted or not yet merged into main) then we should NOT provide backwards-compatibility. Operate as if no changes have been made yet (e.g., rewrite migrations as needed).
  - If the change is in main, but hasn't yet been released (the user will tell you), then probably don't need to provide backwards-compatibility. In this case, you should always ask the user what to do.
  - If the change has been released, we probably do need to provide backwards-compatibility.

### Specifics
- **UI descriptions:** Do not add subtitles, helper text, or descriptive copy beneath headings, labels, cards, or settings by default. Prefer one concise, self-explanatory heading or label. Only add supporting copy when the user explicitly asks for it or when it is necessary to prevent misunderstanding or error, and never use it to restate the heading.
- **Code comments:** Better not to add comments that refer to particular minor events (e.g., we had a bug and we fixed it). You can mention events like "We migrated all users from X system to Y system" that are important or answer questions readers might have about the codebase.

## Tooling
- The repo's existing choice wins. Lockfiles, configs, and scripts decide the tool, not preference. Don't migrate a working setup to a different tool as a side effect.
- When starting fresh or when the choice is genuinely open, default to pnpm (Node) and uv (Python). For anything not listed, prefer the fast, actively-maintained tool over the legacy default.

## Telemetry
Please make note of mistakes you make in MISTAKES.md. If you find you wish you had more context or tools, write that down in DESIRES.md. If you learn anything about your env write that down in LEARNINGS.md.

