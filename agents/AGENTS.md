# Agent instructions

## General Guidelines
- Never use the em-dash "—". Use plain dash "-" instead.
- When making technical decisions, don't let development effort decide. Prefer the option that is higher quality, simpler, more robust, and easier to maintain, even if it takes longer to build.
- When doing bug-fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end-user would experience it as possible. This is to ensure that the fix is not just a workaround but a genuine bug fix.
- When end-to-end testing a product, scrutinize the UI down to the pixel.

## Engineering standards
We're a startup, and our number one rule is to keep things simple. Handle the most important cases, not every possible edge case, and don't add fallbacks for failures that aren't expected to happen.

We try to only add new functionality that is small (that is, simple and few lines of code) or absolutely necessary. If a change is not small or absolutely necessary, don't make it.

- Default to the simplest design that is correct, robust, and maintainable. Don't cut corners to save time. Equally, don't add abstraction, configuration, or scaling machinery for needs that don't exist yet.
- Fix bugs at the root, not the symptom. Before fixing, reproduce the bug end-to-end, as close to the real user's path as possible. The reproduction is what proves the fix is real and not a workaround.
- Hold the UI to a high bar. If something looks wrong: fix it when it's small and adjacent, flag it when it's larger or out of scope. Don't silently expand the change.
- Boyscout rule with scope discipline: leave things better than you found them, but keep every change reviewable. Small adjacent issues (a lint warning, a flaky test, a typo) get fixed. Anything larger or unrelated gets surfaced, not folded into the current work.
- Tautological tests are considered harmful.

**Backwards-compatibility**: When changing existing functionality, you might wonder whether we need to ensure backwards-compatibility. As a rule of thumb:
  - If the change is local to the workspace (part of the current workspace diff, i.e., uncommitted or not yet merged into main) then we should NOT provide backwards-compatibility. Operate as if no changes have been made yet (e.g., rewrite migrations as needed).
  - If the change is in main, but hasn't yet been released (the user will tell you), ask the user whether to provide backwards-compatibility.
  - If the change has been released, provide backwards-compatibility.

### Specifics
- **UI descriptions:** Do not add subtitles, helper text, or descriptive copy beneath headings, labels, cards, or settings by default. Prefer one concise, self-explanatory heading or label. Only add supporting copy when the user explicitly asks for it or when it is necessary to prevent misunderstanding or error, and never use it to restate the heading.
- **Code comments:** Don't write comments about minor past events (e.g., we had a bug and we fixed it). Do mention events like "We migrated all users from X system to Y system" that are important or answer questions readers might have about the codebase.

## Working autonomously
When a step doesn't need my input, keep going, and put status notes in the same message as your next action. Stop and ask only when you can't continue without me, when a change would grow beyond the current task, or before anything destructive (deleting data, force-pushing, changing anything outside the repo).

## Tooling
- The repo's existing choice wins. Lockfiles, configs, and scripts decide the tool, not preference. Don't migrate a working setup to a different tool as a side effect.
- When starting fresh or when the choice is genuinely open, default to pnpm (Node) and uv (Python). For anything not listed, prefer the fast, actively-maintained tool over the legacy default.

## Telemetry
Please make note of mistakes you make in MISTAKES.md. If you find you wish you had more context or tools, write that down in DESIRES.md. If you learn anything about your env write that down in LEARNINGS.md.

