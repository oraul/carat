### The token weighting prices a mid-tier start at the cheap tier's price

- Location: `tools/run_state.sh` line 2009 (`add_tokens`; the alias list read from the agent files' `model:` lines at about line 1976, `TIER_PRICES` at line 448).
- Why: once `.claude/agents/contributor.md` has a `model:` line, the `tokens` command labels the contributor's starts cheap and prices them at 100/125/10/500 instead of a mid price, so `weighted_tokens` and `weighted_phases` are understated. The trial's revert rule uses total tokens, so its verdict is unaffected. Queued as Pool 30 `tier-price-mid`.
- Fix: price each alias by its own tier and add a tools-test case that prices a mid-tier start apart from a cheap one.
