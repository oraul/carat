# Tasks

## 1. The history

- [x] 1.1 Keep texts only in `MessageHistory` (`add(text)`, one `clear`, no `level_at`), keep an error whole in `EditorState#show`, and keep `Notices#add` dropping a line feed; prove it in `test/domain_messages.rb` (Scenario: The refusal of a quit over an unsaved buffer is kept whole)
- [x] 1.2 Build the history once in `EditorAssembly`, a required `message_history:` of `EditorState` and `Notices`, and prove the one instance in `test/adapters_assembly.rb`

## 2. The search echo

- [x] 2.1 Show the pattern echo with `show_output` in `JumpToMatch`; prove it in `test/editor_messages.rb` (Scenarios: The echo of a search is not kept, The wrap message of a search is kept, The refusal of a quit over an unsaved buffer is kept whole)

## 3. Docs

- [x] 3.1 Update `docs/compatibility.md`, `docs/codebase-map.md`, and the `messages` delta spec
