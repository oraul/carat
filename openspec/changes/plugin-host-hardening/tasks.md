# Tasks

## 1. Domain

- [x] 1.1 Add window ids: `id` on `Window`, `next_window_id` and `adopt` on `EditorState` (first window and `add_tab`), `Layout#leaf_of` and `Layout#leaf_showing`, `TabPage` lookups, `EditorState#window_tab` and `buffer_with_id`; verify with `test/domain_layout.rb`
- [x] 1.2 Add `BufferFeed`, `BufferNotice`, `Buffer#feed`, `Buffer#rename`, `Buffer#path_text`, open and close notices from `EditorState`, and the transaction `cause` and merged range in `Transaction`; verify with `test/domain_buffer.rb`
- [x] 1.3 Replace the sign hashes with `SignLayer` layers moved by `LineSplice.shift_marks` in `Buffer#splice`, with `sign_at`, `place_sign`, `clear_signs`, and `Buffer#revert_to`; update `FramePresenter` and remove the backlog entry; verify with `test/domain_buffer.rb` and `test/adapters_frame_presenter.rb`
- [x] 1.4 Record binding owners in `Keymap` (`add_owned`, `remove_owner`, conflicts) and move `action_name?` to `Keymap`; verify with `test/domain_keymap.rb`
- [x] 1.5 Tighten `ManifestCheck` (major and newer minor refused, member types checked, string or symbol events and option types) and add `PathPolicy` and `PathInfo`; verify with `test/domain_plugin_manifest.rb`

## 2. Plugin API 1.2

- [x] 2.1 Change `carat/plugin_api.rb`: version 1.2, string enums, `Event` with `removed` and `inserted`, ids in `Event`, `Context`, and `BufferView` (`buffer`, `message`), `WindowResponse`, `TextResponse`, `open_in_split`, `open_in_tab`; verify the build and `test/use_cases_plugins.rb`

## 3. Host split and hardening

- [x] 3.1 Add the `Guarded` concern, `PluginEntries`, `PluginEntry` normalized events and option types, and `PluginRegistry` with guarded register and activate, uniqueness, depth and cause, and disable with cleanup; verify with `test/use_cases_plugin_hardening.rb`
- [x] 3.2 Add `PluginEvents` (queue, rounds, cause exclusion, feed notices, snapshot by ids) and `PluginRouter`; verify with `test/use_cases_plugin_hardening.rb` and `test/use_cases_plugins.rb`
- [x] 3.3 Add `FileOps` and `SplitWindow#side`, number split windows, use `Buffer#rename` in `SaveFile`, and add the request families `BufferRequests`, `WindowRequests` (open before focus, `open_in_split`, `open_in_tab`), `FileRequests`, and `UiRequests` (E169); verify with `test/use_cases_plugin_files.rb` and `test/editor_plugins.rb`
- [x] 3.4 Rewrite `PluginLink` to check the refusal once and forward, and `PluginHost` as the facade with the flush; activate after `attach` in `EditorAssembly`; verify with `make test`

## 4. Plugins

- [x] 4.1 Move the explorer and hello plugins to 1.2 (string enums, typed responses, ids, `open_in_split`, `open_in_tab`); verify with `test/editor_explorer.rb`, `test/plugins_explorer.rb`, and a path with a space and a bar

## 5. Lint and documentation

- [x] 5.1 Add the plugin reference rule, the `PluginLink` coverage rule, and the concern rules with self-checks to `test/lint.rb`; verify with `make lint`
- [x] 5.2 Update `docs/plugins.md`, `docs/architecture.md` (sections 4, 5.3, 9, and 11), `CLAUDE.md` (Status, Layout, Coding conventions), and `docs/backlog.md`; verify by reading them against the code

## 6. Integration

- [ ] 6.1 Run `make check`, review the regenerated snapshots, and compare `make types` with `main` for new `untyped`

## Workflow follow-up

- Run the security review, archive the change, open the pull request, wait for CI, and squash-merge.
