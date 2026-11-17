# Proposal

## Why

No sign shows a line added, changed, or deleted: the `git_signs` plugin of part a (`git-signs-status-a`) shows only the branch segment. Part a also runs its two git captures on the editor thread on every buffer open, save, and window focus, each up to the host's 2-second deadline, so a slow repository stalls every one of those events (the backlog entry "git_signs runs git synchronously on the editor thread"). This is part b of the T2 user request `git-signs-status-b`, item 1 of sprint 12 in `docs/queue-feature.md`.

## What Changes

- The `git_signs` plugin places a sign on each line of a buffer that differs from the file at HEAD: `git_added` on an added line, `git_changed` on each line of a run that replaced lines, and `git_deleted` on the line above lines that were removed (the first line when they were removed at the top). The text at HEAD comes from a third capture, `git cat-file blob HEAD:./PATH`, with the same `protocol.ext.allow=never` and `core.fsmonitor=false` arguments as the branch capture, and the lines are compared in the plugin, so git never reads the work tree and no filter a repository configures runs. The signs follow the buffer's text, unsaved edits included, on activation, open, save, and focus.
- A window focus with HEAD unchanged runs no git: the plugin reads the working directory's `.git/HEAD`, its branch's ref file, `.git/packed-refs`, and `.git/logs/HEAD` through the host's `read_file` and `stat`, and on a focus with the same answer as at its last git run keeps the segment and diffs the buffer against the HEAD text it already holds. Where that state cannot be read (no `.git` directory in the working directory) a focus asks git as before.
- After a capture runs past its deadline the plugin runs no git until HEAD changes, so one timed-out capture stalls no later event.
- The host's `run_program` answers "PROGRAM ran past 2 seconds" for a program it killed at the deadline, distinct from "cannot run PROGRAM" for one that cannot start: `Ports::ProcessPort` gains `timed_out?`, answered by `Drivers::ProcessRunner` and by `Doubles::FakeProcesses`, which gains `time_out(command)`.
- The icon table gains `git_added`, `git_changed`, and `git_deleted` in every set.
- Document the signs, the focus rule, the timeout, the icons, and the message in `docs/plugins.md`, `docs/compatibility.md`, `docs/architecture.md`, the README, and the map.

Out of scope: signs that follow each keystroke (`buffer_change` is not subscribed; the signs follow the next save or focus); signs against the index rather than HEAD, staged hunks, and hunk actions (stage, reset, preview); running git off the editor thread, which needs a host request the API does not have; a sign for a file git does not track or that is empty at HEAD, a file over the 64 KiB a capture keeps, and a binary file, which show none; observing HEAD from a working directory below the repository's root or in a linked worktree, where a focus asks git as part a did.

Roadmap: delivers the signs half of item 14 of `docs/architecture.md` section 12, `plugin-git-and-formatting` (git signs and status as a plugin), after part a's status half.

Assumptions: the base is HEAD, as the brief's "HEAD and the file unchanged" reads; "a diff capture" is the capture of the file's text at HEAD with the diff computed in the plugin, since `git diff` reads the work tree and would run a repository's clean filter, which the plugin's commands never do; open and save still ask git for the branch and counts, as part a's scenarios require, and only a focus is gated, as the brief's acceptance names; after a timed-out capture with HEAD not observable no git runs until the plugin is activated again; a deleted run's sign goes on the line above it so it never covers a changed or added line.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `git-status`: the line signs, the focus rule, and the timeout back-off.
- `plugin-host`: the message for a program that ran past its deadline.
- `icons`: the `git_added`, `git_changed`, and `git_deleted` names.

## Impact

`carat/plugins/git_signs/plugin.rb` and the new `carat/plugins/git_signs/line_diff.rb`; `carat/ports/process_port.rb`, `carat/drivers/process_runner.rb`, `carat/doubles/fake_processes.rb`, `carat/use_cases/plugins/file_requests.rb`, `carat/plugin_api.rb` (the comment of `run_program`, no version change: the request and its response are the same, only the failure's message is distinct); `carat/domain/icons.rb`. Tests in `test/editor_git_signs.rb`, the new `test/plugins_git_signs_diff.rb`, `test/use_cases_plugins.rb`, `test/drivers_process_runner.rb`, and `test/domain_icons.rb`. No dependency is added; the security review reads the new capture's argv and the reads of `.git`.

- README.md: changed, the git plugin's line signs.
- docs/architecture.md: changed, the `run_program` message in section 9.1 and the git plugin's files in section 11.
