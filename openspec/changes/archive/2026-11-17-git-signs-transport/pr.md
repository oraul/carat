fix(plugins): refuse every git transport and foreign float focus

## Summary

Every program a plugin runs now gets an empty GIT_ALLOW_PROTOCOL beside GIT_NO_LAZY_FETCH=1, a disabled plugin's floats close in every tab page, and focus_window refuses a float the plugin did not open. A git older than 2.44 ignores GIT_NO_LAZY_FETCH, so a partial clone under a trusted root with a repository-local remote.NAME.uploadpack or core.sshCommand could run that command on a lazy fetch, and the float rules left a raising plugin's floats open and let a plugin focus the completion popup or another plugin's floats.

---

## Changes

- Change the plugin host's program environment to set GIT_ALLOW_PROTOCOL to the empty string, so git allows no transport whatever the repository's configuration and the git version.
- Change PluginRegistry so a disabled plugin has its floats closed in every tab page before its buffers are dropped.
- Change focus_window to answer No window N on a float the plugin does not own, as move_float and close_float do, id 0 still naming the current window.
- Add tests for the promisor scenario of the git_signs plugin with no transport allowed, the run_program environment, a raising plugin's floats gone from two tab pages, focus_window on another plugin's float, and a child process seeing a variable set to the empty string.
- Change the git-status, plugin-host, and plugin-windows specs with the archived change git-signs-transport.
- Document the program environment, the focus rule, and the disabled plugin's cleanup in docs/plugins.md and the FileRequests entry of docs/codebase-map.md.
- Record the backlog lane's plan, its metrics history row, and one missing-test finding in docs/findings/git-signs-transport.md.

---

## Testing

- Run the security review of the committed diff, pass with high 0, medium 0, low 0, and nothing blocking
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics on the implementation commit, all pass
- Run the quality review, pass with no blocking finding and five advisories
- Run the benchmark comparison against main's recorded figures, pass with no regression
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

Of the five quality advisories, the missing test of focus_window on the completion popup is recorded in docs/findings/git-signs-transport.md; the git-status scenario wording, the second plugin-host requirement beside the existing GIT_NO_LAZY_FETCH one, and the duplicated float ownership test are wording or style and dropped, and the comment at test/use_cases_plugins.rb:385 is kept because it names the live scenario "run_program turns lazy fetching off" of the plugin-host spec. The history row appended is the backlog lane's last merged change, secret-patterns.
