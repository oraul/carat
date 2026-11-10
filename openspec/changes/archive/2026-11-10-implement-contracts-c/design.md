# Design

## Context

`test/lint.rb` already walks every source file (`source_files`) line by line, collecting violations, and walks `carat/**/*.rb` again for the naming and constructor rules; each rule is a class method of `LintTest` with a self-check `t.assert_equal` in `main`, and the snapshot is one `ok` line per check. `code_of` empties string literals and drops comments; `defs_of` reads the defs of one class body by indentation. None of the three patterns is checked.

## Goals / Non-Goals

**Goals:** a failing case and a repository-wide rule for each of the three patterns, with no violation left on `main`.

**Non-Goals:** removing the existing message repeats; catching a binding written in a form other than a configuration line.

## Decisions

### Messages: the fixed prefix of an E-numbered literal, grouped by file

`message_literals(line)` returns, for each `"E<digits>:` or `'E<digits>:` in a code line, the text up to the closing quote, an interpolation, or an escape, trimmed. The main walk collects `message<TAB>path` pairs; `repeat_problems(found, known)` answers one problem per message held by two or more files and not in `known`, and one per `known` entry no longer held by two files. Grouping by the fixed prefix means `E488: Trailing characters: #{x}` and `E488: Trailing characters: #{y}` count as one message, which is what a reader would move to `Domain::Messages`. Alternative: every repeated string literal. Rejected: short literals (`""`, `"\n"`, action names) repeat legitimately, and both recorded findings were Vim messages.

The pairs are kept as strings in one array rather than a hash of arrays, the simplest shape for Spinel's inference.

### Readers: per class body, by indentation

`shadow_problems(text)` takes each `class` or `module` line, collects the `attr_reader` and `attr_accessor` names two spaces deeper and the `Struct.new(` or `Data.define(` members of the class line itself, and reports a `def NAME` (bare, `private`, or `protected`, not `def self.`) at the same depth whose name is one of them. Per class body, because a file may hold a record and a class whose method shares a member's name (`PluginApi::Host#message` beside `Response`'s `message`). The existing `defines?` answers for a whole file and could not tell them apart.

### Bindings: the configuration-line form outside the configuration's homes

`binding_literal?(line, modes)` is true when a code line holds a literal beginning `keymap.<mode> ` for a mode in `modes`. The modes come from `config/default.caratrc` (`binding_modes`: every `keymap.<scope>` but `leader` and `group`, which bind no key to an action), so a new mode is covered without a lint edit and `keymap.leader takes one key`, a message, is not a binding. The rule skips `carat/plugins/`, whose manifests hold their defaults as configuration lines (CLAUDE.md), and the generated mirror, which the walk skips already.

## Risks / Trade-offs

- [A repeated message hidden by splitting its text or building it] → the rule reads literals only; review still catches the rest.
- [`KNOWN_REPEATED_MESSAGES` becomes a place to park new repeats] → each entry names its owner and a stale entry fails; adding one is a visible, reviewed line.
- [A one-line class body (`class X < Struct.new(:a); end`)] → skipped, since it has no body to shadow in.
