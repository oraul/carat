# Design

## Context

See proposal.md, Why. The sign is drawn by `Ruby::Plugin#check`, which reads the whole buffer through the host and runs `Ruby::Structure` over it; `Structure` drives the tokenizer, which counts openers and ends per line (`opens`, `ends`, and the `@loop` flag, with `modifier_before?`, `JUMPS`, and `endless?` deciding what counts). The plugin listens to `buffer_open`, `buffer_change`, and `mode_change` only for the check, and keeps `EXTENSIONS`, `NAMES`, and `ruby_path?` only to filter those events.

## Goals / Non-Goals

**Goals:** no sign and no whole-buffer pass from the ruby plugin; tokens and line states byte-identical.

**Non-Goals:** the host's sign requests, which other plugins use; any tokenizer behavior that produces tokens or states.

## Decisions

- Remove the opener counting from the tokenizer rather than leave it unread: it runs on every keyword of every tokenized line, and nothing but `Structure` read `opens` or `ends`. `starts`, `modifier_before?`, `JUMPS`, and `endless?` have no other caller (checked by search), so they go too; `definition` and `class_name` still return the position after the name, as before.
- Remove `on_event`, `deactivate`, the host reference, the typing-mode queue, and the file name tables from the plugin and declare no events: the base `PluginApi::Plugin` already provides empty `on_event` and `deactivate`, and the filetype detection of the editor decides which buffers are Ruby. Alternative: keep the events with an empty handler; rejected, since every event is a guarded call for nothing.
- Keep the `Structure:class` tokens of `test/plugins_ruby.rb`: they are the Neovim highlight group, not the removed class.

## Risks / Trade-offs

- [A token row depends on the removed counting] → the counting never wrote tokens (it only changed `@opens`, `@ends`, `@loop`), and the unchanged token and state rows of `test/plugins_ruby.rb.expected`, `test/editor_syntax.rb.expected`, `test/use_cases_plugin_syntax.rb.expected`, and `test/domain_syntax_cache.rb.expected` prove it.
- [Users relied on the sign] → requested removal; language server diagnostics cover it.
