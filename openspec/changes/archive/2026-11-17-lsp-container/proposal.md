# Proposal

## Why

Only `language.<name>.lsp` names a language server, one command for every project, so a user whose projects under one directory need another server command (for example one that runs the server inside the project's container) cannot say so. This is part a of the `lsp-container` user request (docs/queue-feature.md, Sprint 12), outside the numbered roadmap of `docs/architecture.md` section 12, as an extension of the delivered item 10 (`language-services`).

## What Changes

- A user-file (or defaults) line `language.<name>.lsp.root ROOT COMMAND...` names the server command for a working directory that is, or is under, ROOT; the command's words are passed as the program and its arguments, as written, with no shell.
- Outside every such root the language's `language.<name>.lsp` command runs as before; when several root lines cover the directory, the later line wins, as for every setting.
- A `language.<name>.lsp.root` line with fewer than two words is reported as `file:line: language.<name>.lsp.root needs a root and a command` and ignored.
- A project `.caratrc` line `language.<name>.lsp.root ...` is reported as `file:line: language commands are not read from a project file` and ignored, like every `language.*` line there.
- ROOT follows the `language.trusted_roots` rule: an absolute path or a `~/` path under the home directory, without a `.` or `..` segment; any other word covers nothing.

Out of scope: carat ending only its server process on quit and on `:LspRestart` (part b, queued as `lsp-container-b`); several servers of one language at once, one per root, in one session (one server per language stays); the trust rule, unchanged: a root's command starts on its own only under a `language.trusted_roots` root, and `:LspStart` starts it elsewhere.

Assumptions: "files under ROOT" is read as the working directory being under ROOT, the directory every server is rooted in (its `initialize` root) and the one `language.trusted_roots` matches, since the gateway runs one server per language for the whole session.

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `language-server`: a root's command serves a working directory under its root, the default command elsewhere.
- `config-files`: the `language.<name>.lsp.root` key is read from the defaults and the user file with a root and a command, and refused from a project file.

## Impact

`carat/domain/config.rb` (the `lsp.root` language setting and its word count), `carat/domain/trusted_roots.rb` (`TrustedRoots.under?`, one root word against a directory, which `cover?` now uses), `carat/adapters/json_rpc_language_gateway.rb` (`words_of` picks the root's command), `config/default.caratrc` and its mirror `carat/domain/default_config.rb` (a comment line); tests in `test/domain_rc_parser.rb`, `test/domain_trusted_roots.rb`, `test/adapters_language_gateway.rb`, `test/adapters_config_gateway.rb`. No new file, no dependency, no port change.

- README.md: changed, the configuration bullet names `language.<name>.lsp.root`.
- docs/architecture.md: changed, section 7's scopes name `language.<name>.lsp.root` and the project-file rule covers it.
