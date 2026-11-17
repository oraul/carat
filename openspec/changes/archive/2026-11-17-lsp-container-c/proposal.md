# Proposal

## Why

Part c of the `lsp-container` user request (docs/queue-feature.md, Sprint 14 item 1, after #171 and #174), outside the numbered roadmap of `docs/architecture.md` section 12, as an extension of the delivered item 10 (`language-services`). A `language.<name>.lsp.root` line whose root is relative (`src`) or holds a `.` or `..` segment (`/a/./b`, `/a/../b`) is kept without a report and then covers no directory, so the user's container command silently never runs, against the README's promise that every configuration problem is reported as `file:line: message`.

Re-verified on main at 80331bcf9cd8: `Config#language?` checks only that a root line holds two words (`carat/domain/config.rb:218`); the language gateway's `root_line` skips a non-root word through `TrustedRoots.under?`, whose `root_of` holds the root rule (`carat/domain/trusted_roots.rb:44`). Both hold as the brief says.

## What Changes

- One domain check of a root word, `RootWord.root?` (new `carat/domain/root_word.rb`): `~`, `~/...`, or an absolute path, with no `.` or `..` segment. `TrustedRoots.root_of`, which the gateway's root covering and the trusted roots use, applies it to the word with the home expanded; the configuration reader applies it to a root line's first word.
- A `language.<name>.lsp.root` line in the defaults or the user file whose root fails the check is reported as `language.<name>.lsp.root ROOT is not a root` with its file and line, and not kept. A line with fewer than two words keeps its current report.

Out of scope: reporting a `language.trusted_roots` word that is no root (the brief names only root lines; such a word still trusts nothing silently); a root that names a missing directory, which is not checked against the disk; the project file, which keeps refusing every language line before any root check.

Assumptions: the message wording `language.ruby.lsp.root src is not a root`, matching the existing `language.ruby.lsp.root needs a root and a command`; a `~` root is a root for the reader whatever the home, since the home is the gateway's concern and an empty home still covers nothing there.

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `config-files`: a root line whose root is not a root is reported and ignored.

## Impact

New `carat/domain/root_word.rb` (required by `carat/domain/config.rb` and `carat/domain/trusted_roots.rb`, listed in `carat.rb`), `carat/domain/config.rb` (`language?`), `carat/domain/trusted_roots.rb` (`root_of`); tests in `test/domain_rc_parser.rb` and `test/domain_trusted_roots.rb`. The gateway's behavior is unchanged: a root that is no root still covers nothing. No dependency, no port.

- README.md: changed, the language paragraph says a root that is not a root is reported.
- docs/architecture.md: unchanged, section 7's `.caratrc` scopes name `lsp.root ROOT COMMAND...` without its checks, which live in the spec and the codebase map, area 3.
