# Tasks

## 1. Measure

- [x] 1.1 Build Spinel's newest commit, b582d53e, under `tmp/.spinel-new` and `tmp/.toolchain-new` with the local rebuild trace (`SP_ELAB_TRACE`, naming the method generated, the asking call, and the source position last emitted), and compile the runner at main as `make test-build` does, with its own `SPINEL_CACHE_DIR`: the `an_elab_points` builds, the `cg_methods` seconds, and the rebuilds per generated method and line.
  - Result at b582d53e: 731 builds, `an_elab_points` 63.9 s, `cg_methods` 103.6 s, analysis 134.7 s (fixpoint 4 rounds, re-narrowing 2), 4 min 32 s. `JsonRpcLanguageGateway` 188, `DomainGrammarTest#run` 60, `EditorCmdlineTest#main` 36, FileUtils 26, `EditorVisualTest` and `EditorRegistersTest` 24 each, `SymbolOutline` 18, `LintTest` 46, the rest 2 to 16 each.

## 2. Production reads

- [x] 2.1 `carat/adapters/json_rpc_language_gateway.rb`: read every parsed message, result, and notification through `Json.field` and `Json.element`, each receiver already guarded as a `Hash` or an `Array`. Proven by the unchanged snapshots of `test/adapters_language_gateway.rb`, `test/adapters_hover.rb`, `test/adapters_signature.rb`, `test/adapters_definitions.rb`, `test/adapters_server_completions.rb`, and `test/editor_lsp.rb` (`make test`).
- [x] 2.2 `carat/adapters/symbol_outline.rb`: the documentSymbol answer the same way, requiring `carat/domain/json.rb`. Proven by `test/editor_breadcrumbs.rb`'s unchanged snapshot.
- [x] 2.3 `carat/doubles/fake_processes.rb`: `methods_sent` reads the method through `Json.field`. Proven by the language-server tests that call it, snapshots unchanged.

## 3. Test reads

- [x] 3.1 The test helpers and loops the trace names read their untyped arrays through `Carat::Json.element` (`DomainGrammarTest` through its `at`), every check, label, and snapshot unchanged: `test/domain_grammar.rb`, `test/editor_cmdline.rb`, `test/editor_windows.rb`, `test/editor_leader.rb`, the cursor moves of `test/editor_grammar.rb`, `editor_insert.rb`, `editor_motions.rb`, `editor_normal.rb`, `editor_operators.rb`, `editor_registers.rb`, `editor_repeat.rb`, `editor_text_objects.rb`, `editor_undo.rb`, `editor_visual.rb`, and `test/editor_global.rb`, `editor_search.rb`, `editor_substitute.rb`, `editor_completion.rb`, `editor_finder.rb`, `editor_floats.rb`, `editor_palette.rb`, `editor_plugins.rb`, `use_cases_arrange_view.rb`, `adapters_status_bar.rb`, `domain_display_width.rb`, `domain_buffer.rb`, `domain_edits.rb`, `domain_global.rb`, `domain_messages.rb`, `domain_selection.rb`. Proven by `make test` at 6af548c9 with every snapshot unchanged.

## 4. Measure again and document

- [ ] 4.1 Measure the runner again at b582d53e and `make test` at 6af548c9, every snapshot unchanged and re-narrowing at 2 rounds.
- [ ] 4.2 `docs/spinel-notes.md`: the figures after this change and what remains. Verify with `make docs-lint`, `make gates`, and `make spec-validate`.
