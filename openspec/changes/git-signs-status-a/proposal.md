# Proposal

## Why

No git branch shows anywhere in the editor: `carat/plugins/` has no git plugin, and the plugin API has no request that runs a program, so a plugin cannot ask git anything. This is part a of sprint 9's `git-signs-status-a`, a T2 user request: the branch with its ahead and behind counts in the status line. Part b, the line signs, stays in the pool.

## What Changes

- Add the plugin API request `run_program(argv)` (API 2.7): the host runs a program found on `PATH`, without a shell, with no input and its error output discarded, in the editor's working directory, and answers its standard output as text (at most 64 KiB), failed when the command is empty, the program is a path rather than a name, it cannot start, or it runs past 2 seconds, when it is stopped.
- Give `Ports::ProcessPort` a one-shot `capture(argv)`, implemented by `Drivers::ProcessRunner` with `Process.spawn` and `IO.pipe` and by `Doubles::FakeProcesses` from scripted output.
- Add the compiled `git_signs` plugin: on activation, when a buffer opens or is saved, and when a window gains the focus, it asks git for the current branch (`git symbolic-ref --short -q HEAD`) and its counts against the upstream (`git rev-list --left-right --count HEAD...@{upstream}`), and sets its status segment at priority 40, the branch's: the `git` icon, the branch, then the `ahead` icon and count and the `behind` icon and count, each count only when above zero. Outside a repository, on a detached head, or without git the segment is empty and no error is shown. git's output is untrusted text: control characters are dropped, the name is cut to 60 characters, and a count that is not digits reads as zero.
- Add the icon names `ahead` and `behind` to every icon set (`↑` and `↓` in unicode, `+` and `-` in ascii), so the segment holds under `option.icons ascii`.
- Document the request, the plugin, and the icons in `docs/plugins.md`, `docs/compatibility.md`, `docs/architecture.md`, the README, and the map.

Out of scope: the line signs (part b); a dirty-tree marker or staged counts; refreshing on a timer or when git changes the branch outside the editor (the next open, save, or focus change shows it); the editor's reserved `branch` slot of the status bar, which no plugin request fills and which stays empty; a project trust prompt.

Roadmap: delivers the status half of item 14 of `docs/architecture.md` section 12, `plugin-git-and-formatting` (git signs and status as a plugin); the signs and the formatting follow.

Assumptions: the plugin is named `git_signs`, as the layout of `docs/architecture.md` section 11 plans, so part b adds its signs to it; the segment goes through `set_segment` at priority 40 rather than the reserved `branch` slot, since the brief asks for one request, the program run; the commands read only refs and objects, never the work tree, so no clean filter or fsmonitor hook of a cloned repository runs; a run blocks the editor thread for at most 2 seconds, and a refresh runs two short commands only on the three events and activation, never per key; a branch with no upstream shows without counts.

## Capabilities

### New Capabilities

- `git-status`: the git plugin's branch segment with its ahead and behind counts.

### Modified Capabilities

- `plugin-host`: the `run_program` request (API 2.7).
- `icons`: the `ahead` and `behind` names.

## Impact

`carat/plugin_api.rb` (`Host#run_program`, version 2.7), `carat/use_cases/plugins/plugin_link.rb`, `carat/use_cases/plugins/file_requests.rb` (the request), `carat/use_cases/plugins/plugin_host.rb` and `carat/adapters/editor_assembly.rb` (the process port passed on), `carat/ports/process_port.rb`, `carat/drivers/process_runner.rb`, `carat/doubles/fake_processes.rb`, `carat/domain/icons.rb`, the new `carat/plugins/git_signs/plugin.rb` with its configuration lines and the regenerated registry; tests in `test/use_cases_plugins.rb`, `test/drivers_process_runner.rb`, `test/domain_icons.rb`, `test/adapters_assembly.rb`, and a new `test/editor_git_signs.rb`. No dependency is added; the program run is the first a plugin can make, so the security review reads the request.

- README.md: changed, the git plugin's branch segment.
- docs/architecture.md: changed, the `run_program` request in section 9.1 and the plugin's directory in section 11.
