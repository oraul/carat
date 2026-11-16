feat(git): show the branch with ahead and behind counts in the status bar

## Summary

Shows the git branch of the editor's working directory with its ahead and behind counts in the status bar, through a new compiled git_signs plugin and a new plugin API request that runs a program. No branch showed anywhere before, because no git plugin existed and no plugin could ask git anything; this is part a of the git signs and status request, the line signs following as part b.

---

## Changes

- Add the git_signs plugin, which on activation, buffer open, buffer save, and window focus asks git for the branch and its counts against the upstream and sets a status segment at priority 40, empty outside a repository, on a detached head, or without git, with no error shown.
- Treat git's output as untrusted text: control characters are dropped, the branch name is cut to 60 characters, and a count that is not digits reads as zero.
- Add the plugin API request run_program (API 2.7), which runs a program named on the PATH without a shell, with no input and its error output discarded, answering at most 64 KiB of standard output cut before a split character, and failing on an empty command, a path, a start failure, non-UTF-8 output, or a run past 2 seconds.
- Add a one-shot capture to the process port, implemented by the process runner driver with Process.spawn and IO.pipe and by the fake processes double from scripted output.
- Add the ahead and behind icon names to every icon set, plus and minus in ascii, so the segment holds under option.icons ascii.
- Add tests for the request, the driver's limit, deadline, and character cut, the icons, the assembly wiring, and the plugin's branch, counts, silence outside a repository, ascii icons, and refresh on focus and activation.
- Document the request, the plugin, and the icons in the plugins guide, the compatibility table, the architecture, the README, and the code map, and sync the git-status, plugin-host, and icons specs from the archived change.

---

## Testing

- Run the security review of the committed diff, pass with no blocking finding; one Medium at confidence 6, below the blocking threshold, is recorded in the backlog.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run the quality review, pass after one fix round with no blocking finding; its advisories are recorded in the backlog.
- Run the benchmark review against main's recorded figures, pass.
- Run make spec-validate after the archive, all 53 items pass.

---

## Notes

The security review flags that git rev-list in a crafted, untrusted .git with a promisor remote could lazy-fetch a missing object and run a command the repository config names; it is recorded in the backlog with the fix of adding a flag that stops the fetch. Part b, the line signs, stays in the pool, and the reserved branch slot of the status bar stays empty since the plugin fills its own segment. The package step also applies the planner's queue and appends the previous merged change's metrics row.
