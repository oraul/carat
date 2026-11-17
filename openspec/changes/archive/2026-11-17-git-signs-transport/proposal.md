# Proposal

## Why

Backlog item 1 of sprint 16 (T3, security Low at confidence 5 and Medium at confidence 4). The `git_signs` plugin refuses only the `ext::` transport on its command line (`carat/plugins/git_signs/plugin.rb:42`-`44`) and the host relies on `GIT_NO_LAZY_FETCH=1` (`carat/use_cases/plugins/file_requests.rb:30`), which git before 2.44 ignores, so in a partial clone under a trusted root a repository-local `remote.NAME.uploadpack` or `core.sshCommand` runs on a lazy fetch. A plugin disabled after it raised keeps its floats open (`PluginRegistry#disable`, `plugin_registry.rb:259`), and `focus_window` (`window_requests.rb:131`) enters any float, the completion popup's or another plugin's, which `move_float` and `close_float` refuse.

## What Changes

- Every program the plugin host runs gets `GIT_ALLOW_PROTOCOL` set to the empty string beside `GIT_NO_LAZY_FETCH=1`: git then allows no transport at all, whatever the repository's configuration says and whatever the git version (the variable dates from git 2.6.1), so a lazy fetch, or any fetch, can start no command and reach no remote.
- A plugin that is disabled has its floats closed in every tab page, before its buffers are dropped.
- `focus_window` refuses a float the plugin did not open with "No window N", as `move_float` and `close_float` refuse it; id 0 still answers the current window and changes nothing.
- Tests: the promisor scenario of `test/editor_git_signs.rb` shows every command run with no transport allowed; `test/use_cases_plugins.rb` shows `run_program`'s environment, a raising plugin's floats gone from two tab pages, and `focus_window` on another plugin's float answering "No window N"; `test/drivers_process_runner.rb` shows the child sees a variable set to the empty string.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `git-status`: git runs with no transport allowed, not only `ext::` refused.
- `plugin-host`: the program environment refuses every git transport; a disabled plugin's floats are closed.
- `plugin-windows`: focusing a float another plugin opened fails.

## Impact

- `carat/use_cases/plugins/file_requests.rb`, `carat/use_cases/plugins/plugin_registry.rb`, `carat/use_cases/plugins/window_requests.rb`, and the comment of `carat/plugins/git_signs/plugin.rb`.
- Tests: `test/editor_git_signs.rb`, `test/use_cases_plugins.rb`, `test/drivers_process_runner.rb`, with their snapshots.
- docs/plugins.md: changed, `run_program`, `focus_window`, and the disabled plugin's cleanup.
- docs/codebase-map.md: changed, the `FileRequests` entry names the variable; no file is added, moved, or removed.
- README.md: unchanged, it names neither the program environment nor the plugin requests.
- docs/architecture.md: unchanged, its plugin section names no program environment, focus rule, or cleanup list this changes.
- CLAUDE.md: unchanged, no process change.
- docs/compatibility.md and docs/actions.md: unchanged, no command or action is added.

Outside the roadmap of `docs/architecture.md` section 12: a backlog security fix of sprint 16.

Backlog headings this change covers: "### git_signs relies on GIT_NO_LAZY_FETCH, which a git older than 2.44 ignores (security Low, confidence 5)", "### git_signs disables only the ext transport, so a lazy fetch can run a command", "## A disabled plugin's floats stay open", "## focus_window enters floats the plugin does not own".

## Out of scope

- A plugin that needs a git transport (a fetch or push from a future git panel) gets none from `run_program`; allowing one is a decision for that change.
- Dropping the now redundant `-c protocol.ext.allow=never` from the plugin's command lines, kept as a second refusal.

Minor assumptions: the refusal sits in the host's program environment, beside `GIT_NO_LAZY_FETCH`, since a plugin cannot set a variable and `-c protocol.allow=never` loses to a repository's `protocol.NAME.allow`; `focus_window(0)` keeps answering the current window when that is a foreign float, since it enters nothing and the explorer reads the current window that way.
