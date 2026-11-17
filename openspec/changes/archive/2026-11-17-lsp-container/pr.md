feat(lsp): run a root's server command under its root

## Summary

A user configuration line `language.NAME.lsp.root ROOT COMMAND...` now names the language server command carat runs, as written and without a shell, when the working directory is ROOT or under it, while the language's `language.NAME.lsp` command still runs everywhere else. Only one server command per language could be named, so a user whose projects under one directory need another command, such as one that runs the server inside the project's container, could not say so, and a project's `.caratrc` must never name a program to run.

---

## Changes

- Add the `language.NAME.lsp.root` setting to `Domain::Config`, read from the defaults and the user file with a root and a command, a line with fewer than two words reported as file:line: message and ignored
- Refuse a `language.NAME.lsp.root` line in a project `.caratrc` with a file:line report, like every other language line there
- Change the JSON-RPC language gateway to pick the last root line whose root covers the working directory and run its words as the program and arguments, falling back to the default command elsewhere
- Add `TrustedRoots.under?`, one root word against a directory under the trusted-roots rule, which `cover?` now uses
- Add a comment line for the new key to `config/default.caratrc` and its generated mirror
- Add tests for the root's command under ROOT, the default elsewhere, the later root line winning, the short line report, and the project file's refused line, and refresh their snapshots
- Document the key in the README, section 7 of the architecture, and the codebase map, and sync the `config-files` and `language-server` specs

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the quality review, pass with no blocking finding and four advisories
- Run the benchmark review against main's recorded figures, pass with lh 26.0, j 27.0, and insert 26.0 allocations held
- Run make spec-validate after the archive, 53 items pass

---

## Notes

This is part a of the lsp-container request, delivered split; carat ending only its server process on quit and on :LspRestart is queued in the feature pool as lsp-container-b. A root's command still starts on its own only under a `language.trusted_roots` root, and the gateway keeps one server per language for the session. The advisories on the idle-tick rescan of the configuration and on a root line whose root is not a root are recorded in the change's findings file; the two style advisories on a record member read and a duplicated key constant are dropped as minor.
