feat(git): sign the lines that differ from HEAD

## Summary

Adds line signs to the git plugin: each line that differs from the file at HEAD shows an added, changed, or deleted sign, following the buffer's text on activation, open, save, and focus. Until now no sign showed what changed, and the plugin's synchronous git captures on the editor thread could stall every open, save, and focus in a slow repository. A focus with HEAD unchanged now runs no git, and after a capture times out the plugin runs no git until HEAD changes.

---

## Changes

- Add `git_added`, `git_changed`, and `git_deleted` signs to the `git_signs` plugin, computed by a new plugin-local line diff against the HEAD text from `git cat-file blob HEAD:./PATH`, which carries the same `protocol.ext.allow=never` and `core.fsmonitor=false` arguments as the branch capture so git never reads the work tree or runs a configured filter.
- Change a window focus to run no git when the HEAD state read from `.git/HEAD`, the branch ref, `packed-refs`, and `logs/HEAD` matches the last git run, reusing the held HEAD text.
- Add a back-off that runs no git after a capture passes its deadline until HEAD changes, so one timed-out capture stalls no later event.
- Change the host's `run_program` to answer "PROGRAM ran past 2 seconds" for a killed program, through a new `timed_out?` on `Ports::ProcessPort`, answered by `Drivers::ProcessRunner` and by `Doubles::FakeProcesses`, which gains `time_out`.
- Add a `buffer_close` subscription that only forgets the closed buffer's held HEAD text and signs, so held texts stay bounded by the open buffers.
- Add the three git sign glyphs to every icon set.
- Add tests in `test/editor_git_signs.rb`, the new `test/plugins_git_signs_diff.rb`, `test/use_cases_plugins.rb`, `test/drivers_process_runner.rb`, and `test/domain_icons.rb` covering each sign kind, the no-git focus, the timeout back-off, the diff argv, and the timeout message.
- Document the signs, the focus rule, the timeout, the icons, and the message in the README, `docs/plugins.md`, `docs/compatibility.md`, `docs/architecture.md`, and the code map, and sync the `git-status`, `plugin-host`, and `icons` specs through the archived OpenSpec change.
- Record the review findings left for later in `docs/findings/git-signs-status-b.md` and apply the feature lane's queue to `docs/queue-feature.md`.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the quality review, pass with no blocking finding and three advisories, and the benchmark review, pass with allocations and rounds held.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run make spec-validate after the archive, 53 passed and 0 failed.

---

## Notes

Out of scope, as the proposal records: signs that follow each keystroke, signs against the index, hunk actions, running git off the editor thread (no host request for it yet), and observing HEAD from a repository subdirectory or a linked worktree, where a focus asks git as before. The quality advisory on reporting a timeout through the stalled flag rather than a return value was dropped as a style point; the timeout suffix spelled twice, the untested buffer close, stale signs on an empty relative path, and the empty HEAD key in worktrees are recorded as findings for a follow-up.
