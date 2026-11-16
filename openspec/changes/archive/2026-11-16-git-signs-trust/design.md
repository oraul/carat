# Design

## Context

`git_signs` asks git through `PluginApi::Host#run_program`, which `PluginLink` hands to `FileRequests#run_program`, which checks the words and calls `Ports::ProcessPort#capture`; `Drivers::ProcessRunner` spawns the program with the editor's environment and working directory. The only trust answer is `JsonRpcLanguageGateway#trust_of`, over `Domain::Config::TRUSTED_ROOTS`, private to the gateway. A plugin names no `Domain` constant.

## Goals / Non-Goals

Goals: no plugin program runs outside a trusted root; in a trusted root git cannot be made to run a command by the repository's configuration through a lazy fetch, the `ext::` transport, or an fsmonitor hook. Non-goals: a trust prompt, an API request for trust, re-deciding trust after `:cd`.

## Decisions

- Refuse inside `run_program` rather than add a trust request. A request would grow the API (a `Host` method, a `PluginLink` override, a family method, version 2.8) and still rely on each plugin asking; the refusal covers every plugin, present and future, with no API change. Alternative rejected: the request, for those reasons.
- `Domain::TrustedRoots.cover?(config, cwd, home)` holds the rule the gateway had (a root word absolute or under `~`, no `.` or `..` segment, a trailing slash ignored, `/` covering all, the working directory equal to a root or below it; no line, or a relative working directory, trusts nothing). The gateway and the plugin host both call it, so the rules cannot drift.
- The plugin host decides trust once in `activate_all(config)`, which already receives the loaded configuration, and sets `FileRequests#trusted=`; before activation `trusted` is false, so nothing runs. This keeps the constructor of `PluginHost` unchanged. The gateway already caches its answer for the same reason: neither the directory nor the configuration changes while the editor runs.
- `ProcessPort#capture(argv, environment)` takes the variables to add to the child's environment; `ProcessRunner` passes the Hash as `Process.spawn`'s leading environment argument, which Spinel supports, and `FakeProcesses` records each call's variables so a test can see them. `FileRequests` passes `GIT_NO_LAZY_FETCH=1` for every program: only git reads it, and a plugin's program is a probe, never a fetch.
- `git_signs` prefixes both commands with `-c protocol.ext.allow=never -c core.fsmonitor=false`: command-line configuration outranks the repository's, so a `.git/config` cannot re-allow `ext::` or name an fsmonitor command.

## Risks / Trade-offs

- git older than 2.44 ignores `GIT_NO_LAZY_FETCH`; there a trusted root's partial clone could still lazily fetch over a non-`ext::` transport. Accepted: the trusted root is the user's own statement of trust, the primary gate; the `ext::` transport stays refused.
- A user who never set `language.trusted_roots` loses the branch segment until they do. Accepted and documented: it is the same rule the language servers follow.

## Testing

`test/domain_trusted_roots.rb` table-tests the rule; `test/use_cases_plugins.rb` checks the refusal before activation and outside a root, and the environment the port receives; `test/drivers_process_runner.rb` checks the variable reaches the child; `test/editor_git_signs.rb` checks a root outside the trusted roots runs no git and shows nothing, a trusted root shows the branch and counts, and a canned promisor repository, whose counts command the double answers only when lazy fetching is off and `ext::` is refused, runs no command.
