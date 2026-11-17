# Design

## Context

See proposal.md for the motivation. `Config#language?` reads `language.<name>.<setting>` with the setting being everything after the language name's first dot, so `language.ruby.lsp.root` arrives as setting `lsp.root`, today refused as unknown; a project file's `language.*` line is already refused before the setting is read. `JsonRpcLanguageGateway#words_of` picks the command with `@config.last("language.<type>.lsp")`; the gateway runs one server per language, rooted in the working directory (`initialize_params`), and `TrustedRoots` matches roots against that directory.

## Goals / Non-Goals

**Goals:**
- Pick the server command by the working directory, with no new allocation on the idle tick when no root line exists.

**Non-Goals:**
- Matching each buffer's own path and running one server per root of a language at once: every request, capability list, and document sync in the gateway is keyed by language, so that is a rework of the gateway, not this part.
- Process ending on quit and `:LspRestart` (part b).

## Decisions

- Match the root against the working directory, not the buffer's path: the server is rooted in the working directory, and with one server per language a buffer-path match would hand later buffers outside the root to the root's server. Alternative considered: the current buffer's path at launch, rejected for that reason.
- Add `TrustedRoots.under?(word, cwd, home)`, one root word against a directory, and have `cover?` use it, so a command root and a trusted root follow one rule (absolute or `~/`, no `.` or `..` segment, `/` covering every absolute directory). Alternative: a second copy of the rule in the gateway, rejected as drift-prone.
- The gateway scans the configuration's lines from the last for a key of `language.<type>.lsp` plus `.root`, compared with `bytesize`, `start_with?`, and `end_with?` on the key already built, so a configuration with no root line allocates nothing more than today; the first covering line wins, which is the later line of the files. The command is the line's words after the root, handed to `ProcessPort#spawn` as the argv, as today.
- `Config#language?` accepts `lsp.root` as a language setting and refuses one with fewer than two words; the root's form is not checked there (`trusted_roots.rb` requires `config.rb`), matching `language.trusted_roots`, where a word that is no root covers nothing.
- The trust gate is unchanged: the root's command starts on its own only under a `language.trusted_roots` root.

## Risks / Trade-offs

- [A session started outside the root that opens files under it runs the default command] → documented in the README and the spec; buffer-path matching is a later, larger change.
- [`words_of` allocates the dropped words on each call when a root line matches] → it runs on the idle tick only while no server runs for the language, and only for users with a root line; the bench configuration has none.
