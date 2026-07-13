# Agent instructions

## General Guidelines
- Never use the em-dash "—". Use plain dash "-" instead.
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- When doing bug-fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end-user would experience it as possible. This is to ensure that the fix is not just a workaround but a genuine bug fix.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection. If something looks off, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, program design, performance, and test flakiness. If you see one, even if it is not caused by what you are working on right now, still get it fixed. (Boyscout rule!)

## Engineering standards
- Default to the simplest design that is correct, robust, and maintainable. Don't cut corners to save time. Equally, don't add abstraction, configuration, or scaling machinery for needs that don't exist yet.
- Fix bugs at the root, not the symptom. Before fixing, reproduce the bug end-to-end, as close to the real user's path as possible. The reproduction is what proves the fix is real and not a workaround.
- Hold the UI to a high bar. If something looks wrong: fix it when it's small and adjacent, flag it when it's larger or out of scope. Don't silently expand the change.
- Boyscout rule with scope discipline: leave things better than you found them, but keep every change reviewable. Small adjacent issues (a lint warning, a flaky test, a typo) get fixed. Anything larger or unrelated gets surfaced, not folded into the current work.

## Tooling
- The repo's existing choice wins. Lockfiles, configs, and scripts decide the tool, not preference. Don't migrate a working setup to a different tool as a side effect.
- When starting fresh or when the choice is genuinely open, default to pnpm (Node) and uv (Python). For anything not listed, prefer the fast, actively-maintained tool over the legacy default.