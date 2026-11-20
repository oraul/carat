fix(tools): pin openspec and run the base's ci scope script

## Summary

Pins OpenSpec to one exact version wherever the delivery tooling runs it, and makes CI's scope step run the base branch's scope script instead of the pull request's own. Every spec validation fetched and ran whatever version the registry named latest in a session holding the push credentials, and a pull request could change the scope script or its documentation rules to decide by its own logic whether the checks that test it run at all.

---

## Changes

- Change the Makefile's OpenSpec command and the default command of tools/spec_validate.sh to run @fission-ai/openspec@2.1.1, the version latest named at d7f5de8, through a new OPENSPEC_PACKAGE variable
- Change the contributor's guard in tools/agent_guard.sh to admit npx only for the pinned package, refusing the latest tag, the unversioned name, and any other version, with a refusal that names OPENSPEC_PACKAGE rather than a version literal
- Change the Scope step of ci.yml to read tools/ci_scope.sh and tools/rules.sh from the merge commit's first parent into the runner's temporary directory and run that copy over the checkout
- Add tools-test cases for the pinned default command, the four pins (Makefile, script, guard, CLAUDE.md) being equal, the guard naming the pin once, the three guard refusals, and the scope step answering with the base's script over a head that replaces it
- Document the pin in CLAUDE.md's OpenSpec line and README.md's OpenSpec row, and the base's scope script in docs/architecture.md section 10 and the codebase map's area 1
- Add the archived OpenSpec change and record two remaining security Lows, the unpinned transitive dependencies and the bare openspec command, in docs/findings/pr-trust-lows.md

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding and two Lows, both recorded in docs/findings/pr-trust-lows.md
- Run the quality review, pass with no blocking finding and one advisory, recorded in docs/findings/pr-trust-lows.md
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the benchmark comparison against main's recorded figures, pass
- Run make spec-validate after archiving, 54 passed and 0 failed

---

## Notes

The pin fixes only the top-level package: npx still resolves OpenSpec's dependency ranges on a cold cache, which a vendored lockfile would close, left recorded as a follow-up. The ci.yml file itself still comes from the pull request, so an edit of the step remains a visible workflow change in the reviewed diff. The other headings of the queue line (fork branch names in open_pr.sh and open-pr.yml, gates.sh, and the review continuations) are left to separate queued items, and tools/rules.sh is not edited. The generated OpenSpec skills under .claude/ are not refreshed here.
