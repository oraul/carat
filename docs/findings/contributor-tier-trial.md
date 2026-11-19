### The token weighting prices a mid-tier start at the cheap tier's price

- Location: `tools/run_state.sh` line 2009 (`add_tokens`; the alias list read from the agent files' `model:` lines at about line 1976, `TIER_PRICES` at line 448; the `weighted_phases` history column it feeds).
- Why: once `.claude/agents/contributor.md` has a `model:` line, the `tokens` command labels the contributor's starts cheap and prices them at 100/125/10/500 instead of a mid price, so `weighted_tokens` and `weighted_phases` are understated; the same starts are also recorded as `metric.start.N` `implement/cheap/...` and in `weighted_phases` under a `cheap` label the calibration profile no longer uses. The trial's revert rule uses total tokens, so its verdict is unaffected. Queued as Pool 30 `tier-price-mid`.
- Fix: in `tier-price-mid`, price each alias by its own tier, label such a start by the agent tier (or by the alias's own price key) together with its price, extend the design's no-cheap-label goal to the token labels then, and add a tools-test case that prices and labels a mid-tier start apart from a cheap one.

### The tier trial's keep rule does not say how its figures compare

- Location: `docs/goals.md:38`
- Why: the rule compares 6 deliveries with 10 rows without saying whether each figure is a per-row rate or a mean, which history (both lane files in merge order, or one lane), or how `total_tokens` of changes of mixed sizes compare, so the planner's verdict can be read either way.
- Fix: state per-row rates and means over both lane histories in merge order, `total_tokens` taken against each row's estimate budget.

### The calibration comment names the tier twice

- Location: `.claude/workflows/deliver-change.js:129`
- Why: the comment says the tier twice ("the tier the model: line of the agent's file names ... whichever tier that is"), wordier than the rule it states.
- Fix: "The tier is agent, the agent file's model: line (the only place a tier is named; tools/tools_test.sh compares them), or session, the session's model".
