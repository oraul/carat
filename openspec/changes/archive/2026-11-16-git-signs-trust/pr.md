fix(plugins): run plugin programs only under a trusted root

## Summary

The host's run_program now refuses every plugin program while the editor runs outside a root of language.trusted_roots, and runs the programs it does start with git's lazy fetch off, so the git_signs plugin shows its branch segment only in a trusted root. Opening a cloned repository could run a command named by its untrusted .git/config, since a promisor remote such as an ext:: transport ran when rev-list lazily fetched a missing upstream object (a security High at confidence 9). Refusing inside run_program covers every plugin without growing the plugin API, which stays at version 2.7.

---

## Changes

- Change run_program to refuse without starting anything while the working directory is outside every root of language.trusted_roots, decided once when the plugins activate.
- Add GIT_NO_LAZY_FETCH=1 to the environment of every program the host runs, the process port's capture now taking the variables to add.
- Change the git_signs commands to pass -c protocol.ext.allow=never and -c core.fsmonitor=false, so a trusted repository's configuration can name no command either.
- Move the trusted roots rule from the language server gateway into one shared Domain::TrustedRoots, used by both, so the two answers cannot drift.
- Add tests for the trusted roots rule, the refusal outside a trusted root, the hardened command line and environment under an ext:: promisor remote, the branch segment and counts in a trusted root, and the environment reaching the child process.
- Document that the branch segment needs a trusted root in README.md, docs/plugins.md, and docs/architecture.md, and place the new files in the code map.
- Archive the git-signs-trust OpenSpec change, adding its requirements to the plugin-host and git-status specs.

---

## Testing

- Run the security review of the committed diff, passed with no High or Medium finding and one Low, recorded in docs/findings/git-signs-trust.md.
- Run the quality review, passed with no blocking finding; its six docs and style advisories are dropped.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run the benchmark review, passed with the allocations held at lh 26.0, j 27.0, and insert 26.0.
- Run make spec-validate after the archive, all 53 items pass.
- Run make gates and make docs-lint before the push, both pass.

---

## Notes

Reviewer guidance: GIT_NO_LAZY_FETCH is honored by git 2.44 and later; an older git ignores it, where the trusted-root refusal and protocol.ext.allow=never still hold, and refusing every transport on the command line is recorded as a defense in depth follow-up. A trust prompt, a trust request plugins can ask, and :cd re-deciding trust are left out. Closes the backlog entry on git_signs rev-list lazy-fetching from a promisor remote in an untrusted .git.
