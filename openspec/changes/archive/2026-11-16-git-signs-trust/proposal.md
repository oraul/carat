# Proposal

## Why

The sprint-10 sweep verified a security High (confidence 9): the `git_signs` plugin runs git (`symbolic-ref` for the branch, `rev-list --left-right --count HEAD...@{upstream}` for the counts) through the host's `run_program` in whatever directory Carat opens, and a cloned repository's `.git/config` is untrusted: a partial clone whose promisor remote is an `ext::` command, or a local remote with its own upload-pack, runs that command when `rev-list` lazily fetches a missing upstream object. Opening a directory must never decide what Carat runs; the language servers already start on their own only under `language.trusted_roots`. This also closes the backlog entry "git_signs rev-list can lazy-fetch from a promisor remote in an untrusted .git (security Medium, confidence 6)".

## What Changes

- The host's `run_program` refuses, without starting anything, every program while the editor's working directory is outside the roots of `language.trusted_roots`, the same trust the language servers use, decided once when the plugins activate. So `git_signs` runs no git and shows no segment outside a trusted root, and no other plugin can run a program there either.
- The host runs every program a plugin starts with `GIT_NO_LAZY_FETCH=1` added to its environment, so git never fetches a missing object from a promisor remote for a plugin; the process port's `capture` takes the variables to add.
- Every `git_signs` command passes `-c protocol.ext.allow=never -c core.fsmonitor=false`, so a repository's configuration can neither allow the command-running `ext::` transport nor name an fsmonitor command, even in a trusted root.
- The trust test moves from the language server gateway into one shared `Domain::TrustedRoots`, used by both, so the two answers cannot drift.
- Document that the branch segment needs a trusted root (README, `docs/plugins.md`, `docs/architecture.md`) and place the new file in the map.

Out of scope: a trust prompt or a `:trust` command; a trust request a plugin can ask (the refusal inside `run_program` is smaller and covers every plugin, so the API does not grow and its version stays 2.7); `:cd` re-deciding trust (the working directory and the configuration do not change while the editor runs, as the gateway already assumes); the line signs of `git-signs-status-b`.

Roadmap: a security fix of the status half of item 14 of `docs/architecture.md` section 12, `plugin-git-and-formatting`, already delivered by `git-signs-status-a`.

Assumptions: refusing inside `run_program` is the smaller and safer of the brief's two options, since it needs no API growth and no plugin can forget to ask; `GIT_NO_LAZY_FETCH` is honored by git 2.44 and later and ignored by older git, where the trusted-root gate and `protocol.ext.allow=never` still hold; the environment is set for every program the host runs because only git reads it; the recorded allocation figures to hold are lh 26.0, j 27.0, insert 32.0 (the brief's insert 26.0 differs from the recorded `git-signs-status-a` row, which says 32.0).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-host`: `run_program` refuses outside a trusted root and runs programs with git's lazy fetch off.
- `git-status`: the branch segment shows only under a trusted root, and git runs with lazy fetch and command-running configuration off.

## Impact

`carat/domain/trusted_roots.rb` (new), `carat/adapters/json_rpc_language_gateway.rb` (uses it), `carat/use_cases/plugins/file_requests.rb` and `carat/use_cases/plugins/plugin_host.rb` (the refusal and the environment), `carat/ports/process_port.rb`, `carat/drivers/process_runner.rb`, `carat/doubles/fake_processes.rb` (`capture` takes the environment), `carat/plugins/git_signs/plugin.rb` (the `-c` options); tests in `test/editor_git_signs.rb`, `test/use_cases_plugins.rb`, `test/drivers_process_runner.rb`, and a new `test/domain_trusted_roots.rb`. No dependency is added and the plugin API version stays 2.7.

- README.md: changed, the branch segment needs a trusted root.
- docs/architecture.md: changed, the trust rule names plugin programs.
