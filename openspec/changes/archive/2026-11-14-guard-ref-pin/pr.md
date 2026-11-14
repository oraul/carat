fix(agents): read the guard from a fresh fetch of origin's main

## Summary

Every agent's tool-call hook now reads tools/agent_guard.sh from a fresh shallow fetch of origin's main into a temporary repository, instead of from the local origin/main ref. Branch code run by make could move origin/main, plant an object, or redirect a fetch through writable git configuration so that a permissive guard ran for every agent, the merger's merge-tool hook included; this was the blocking security Medium of the sprint-4 sweep.

---

## Changes

- Change every hook line under .claude/agents to fetch refs/heads/main with depth 1 from the pinned origin address into a new temporary bare repository, with no global or system configuration and transfer.fsckObjects on, read the guard at FETCH_HEAD there, remove the repository, and refuse with status 2 on any failure.
- Refuse any origin address but the repository's own hosted one over https, ssh, or the scp-like form, so a local path, a file address, a remote helper, an option, or another hosted repository is refused.
- Keep the merger's merge-tool hook check that main's guard names the merge tool, on the guard read the same way.
- Add tools/tools_test.sh cases for a locally moved origin/main, a planted object with a mismatched hash, a replace ref, a repository insteadOf, a local, foreign, or remote-helper origin, an unreachable origin, a main the repository lacks, no leftover temporary repository, no object or ref written in the project, and identical resolution across every hook line.
- Trim the contributor and planner agent prose to their docs-lint byte budgets by pointing to CLAUDE.md instead of restating it.
- Document where the guard is read from in the tools/agent_guard.sh header, the codebase map bullet, and the README guard sentence.

---

## Testing

- Run the security review of the committed diff at 54726eda8ca1, passed with no high, medium, or low finding.
- Run the quality review at 54726eda8ca1, passed with no blocking finding and three advisories recorded in the backlog.
- Run the checker's fast stages at 54726eda8ca1 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run the benchmark comparison against main's recorded figures, passed.
- Run make spec-validate after archiving the change, all 51 items pass.

---

## Notes

Every agent tool call now costs one shallow fetch of main, about one second, and needs origin reachable; offline, every agent call is refused, which fails closed as a missing guard already did. A fork must edit the pinned owner and name in its hook lines. The merge gates' worktree of origin/main still reads the project's object store and is out of scope here. The review advisories, among them the hook lines' pinned address against the single URL exception of the hard rules and cleanup of the temporary repository on interruption, are appended to the backlog.
