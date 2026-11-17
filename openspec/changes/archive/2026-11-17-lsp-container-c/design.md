# Design

## Context

See proposal.md. `Config#language?` (`carat/domain/config.rb`) checks a trusted file's language lines; a `lsp.root` line only for two words. `TrustedRoots.root_of` (`carat/domain/trusted_roots.rb`) turns a root word into an absolute path or `""`, and `under?`, which the language gateway's `root_line` and `TrustedRoots.cover?` call, covers nothing for `""`. `trusted_roots.rb` requires `config.rb` (for `Config` and `Config::TRUSTED_ROOTS`), so the reader cannot require `TrustedRoots` without a cycle.

## Goals / Non-Goals

**Goals:**
- One rule for what a root word is, read by the configuration reader and by the root covering the gateway asks.
- A root line whose root breaks the rule reported with its file and line, and not kept.

**Non-Goals:**
- Reporting `language.trusted_roots` words; checking a root against the disk.

## Decisions

- A new domain module `RootWord` with one function `root?(word)`: true for `~`, a word starting with `~/`, or one starting with `/`, when the word with a trailing `/` added holds neither `/./` nor `/../`. It requires nothing, so `config.rb` and `trusted_roots.rb` both require it. Alternative: a `Config.root?` class function that `TrustedRoots` reaches through its existing require, rejected since a path rule is not the configuration record's concern; moving the rule into `TrustedRoots` and requiring it from `config.rb`, rejected as a require cycle.
- `TrustedRoots.root_of` expands `~` first (still `""` for an empty home), then answers `""` unless `RootWord.root?(path)` holds, so an odd home with a `..` segment still covers nothing, as before; the trailing slash trimming stays there. The gateway changes nothing: it already goes through `under?`.
- `Config#language?` checks the root after the word count, so a one-word line keeps its "needs a root and a command" report, and notes `#{line.key} #{root} is not a root`. The project file never reaches it: language lines from it are refused first.

## Risks / Trade-offs

- [A user file with a relative root line, ignored silently until now, starts showing a report at startup] → that is the requested behavior; the line covered nothing before either.
