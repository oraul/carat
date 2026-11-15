chore(agents): pin origin by digest instead of by address

## Summary

Pins the repository's origin by git blob digest in every agent hook line and in the merge gates' green line, so no tracked file outside the Makefile `toolchain` target spells the repository's hosted address, its host, or its owner and name. #126 pinned origin by writing the address in pieces and the green line named the hosting service's host, which broke the rule that only the toolchain target may hold a URL; a digest of the exact address cannot be read back into it while still refusing every origin #126 refused.

---

## Changes

- Change every hook line under `.claude/agents/` to accept `remote.origin.url`, `.git` stripped, only when its `git hash-object --stdin` id is one of the three digests of the repository's https, ssh, and scp forms, keeping the fetch into a temporary repository, `transfer.fsckObjects`, and the guard read at `FETCH_HEAD` unchanged, and refusing any other origin with the same message.
- Change `originCheck` in `.claude/workflows/deliver-change.js` to take no argument and accept origin's resolved url only when its blob id is one of six ids in `ORIGIN_IDS`, the hook lines' three forms with and without `.git`, so the line names no host and an origin with a user before the host or a trailing slash is refused.
- Change `tools/agent_guard.sh` to admit `git hash-object --stdin` for the merger profile alone, refusing every other option such as `-w`, `--path`, and `--literally`, and document in its header how the pins are written and recomputed.
- Change `tools/tools_test.sh` to run the hook and green-line cases against a fixture origin on a reserved `.invalid` host whose digests replace the pinned ones, adding cases for each accepted form and for a trailing slash, a user before the host, another owner, and the guard's hash-object options.
- Refactor the contributor's and the planner's prose by a few bytes, and drop the hook line's one-use variable, so both stay within their docs-lint budgets without raising them.
- Document the digest pin in the `agent_guard.sh` bullet of `docs/codebase-map.md` and in the guard sentence of `README.md`.
- Add the archived OpenSpec change `guard-pin-no-url` with its brief, proposal, design, and tasks, and no spec delta since no editor behavior changes.
- Record the planner's queue, the metrics row of the previous merged change, a security entry for a planted object reaching the merge gates' worktree, and two quality advisories in `docs/backlog.md`.

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low finding.
- Run the quality review, passed with no blocking finding and two advisories recorded in `docs/backlog.md`.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, bench-budget, metrics, tools-test, and gates, all pass, with diagnose passed on the same code and reused.
- Run the benchmark comparison against main's recorded figures, passed.
- Run `make spec-validate` after the archive, 51 passed and 0 failed.

---

## Notes

The merger's hook runs the guard from origin's main, which admits `git hash-object --stdin` only once this change merges, so the merger's hook may refuse this change's own green line; if it does, this one merge needs the user, and later changes are unaffected. A fork or a clone whose origin is another repository is refused by every hook, as with #126; the guard's header says how to recompute the three digests. The planted-object route into the merge gates' worktree of origin/main stays open and is recorded in the backlog for the planner.
