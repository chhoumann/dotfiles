# Agent instructions

## General Guidelines
- Never use the em-dash "—". Use plain dash "-" instead.
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- When doing bug-fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end-user would experience it as possible. This is to ensure that the fix is not just a workaround but a genuine bug fix.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection. If something looks off, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, program design, performance, and test flakiness. If you see one, even if it is not caused by what you are working on right now, still get it fixed. (Boyscout rule!)

## Output
- Never use em-dashes. Use a plain hyphen (-).

## Engineering standards
- Default to the simplest design that is correct, robust, and maintainable. Don't cut corners to save time. Equally, don't add abstraction, configuration, or scaling machinery for needs that don't exist yet.
- Fix bugs at the root, not the symptom. Before fixing, reproduce the bug end-to-end, as close to the real user's path as possible. The reproduction is what proves the fix is real and not a workaround.
- Hold the UI to a high bar. If something looks wrong: fix it when it's small and adjacent, flag it when it's larger or out of scope. Don't silently expand the change.
- Boyscout rule with scope discipline: leave things better than you found them, but keep every change reviewable. Small adjacent issues (a lint warning, a flaky test, a typo) get fixed. Anything larger or unrelated gets surfaced, not folded into the current work.

## Tooling
- The repo's existing choice wins. Lockfiles, configs, and scripts decide the tool, not preference. Don't migrate a working setup to a different tool as a side effect.
- When starting fresh or when the choice is genuinely open, default to pnpm (Node) and uv (Python). For anything not listed, prefer the fast, actively-maintained tool over the legacy default.

## Picking the right models for workflows and subagents

Rankings, higher = better. Cost reflects what I actually pay (OpenAI has really generous limits), not list price. Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model | cost | intelligence | taste |
| :--- | :--- | :--- | :--- |
| gpt-5.5 | 9 | 8.5 | 5 |
| sonnet-5 | 5 | 5 | 7 |
| opus-4.8 | 4 | 7 | 8 |
| fable-5 | 2 | 9.25 | 9 |

How to apply:
- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag. Escalating costs less than shipping mediocre work.
- Cost is a tie–breaker only; when axes conflict for anything that ships, intelligence > taste > cost.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt-5.5 – it's effectively free.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7.
- Reviews of plans/implementations: fable-5 or opus-4.8, optionally gpt-5.5 as an extra independent perspective.
- Never use Haiku.
- Mechanics: gpt-5.5 is only reachable through Codex (my ~/.codex/config.toml defaults to gpt-5.5). In Claude Code, use the official Codex plugin (https://github.com/openai/codex-plugin-cc): the `codex:codex-rescue` subagent for delegated coding/diagnosis work, and the `codex:rescue` / `codex:review` / `codex:adversarial-review` skills. For work the plugin doesn't cover (investigation, data analysis), run `codex exec -s read-only` directly with a self-contained prompt.
- Claude models (sonnet-5, opus-4.8, fable-5) run via the Agent/Workflow model parameter.

Using gpt-5.5 inside workflows and subagents (the model parameter only takes Claude models):
- Prefer spawning the plugin's Codex subagent: `agentType: 'codex:codex-rescue'` (Agent tool or Workflow `agent()` opts) with a self-contained prompt.
- Fallback where that agent type is unavailable: spawn a thin Claude wrapper agent with `model: 'sonnet', effort: 'low'` whose prompt instructs it to write a self-contained codex prompt, run `codex exec` via Bash, and return