### A dangling .claude link refuses every write with the dangling-path message
- Location: `tools/agent_guard.sh`, `write_target`, the loop over `LOCAL_FILES` after `real_path`.
- Why: each write resolves the real path of every local settings file; while `.claude` is a dangling link, `real_path` refuses every write as "a path through a dangling link: .claude/settings.local.json", which names neither the write nor the reason. The refusal is on the safe side, so only the message misleads (merge-path-lows quality review).
- Fix: resolve the local settings paths once at the guard's start, skipping a dangling one, and compare each write's real path with that list.
none
