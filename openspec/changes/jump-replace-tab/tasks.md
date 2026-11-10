# Tasks

## 1. Reproduction

- [ ] 1.1 Add the table of jump tab cases to `test/adapters_definitions.rb` (gd alone, the position with an `:e` tab, a target with its own tab, a second window, `option.jumptab keep`, an outside target, a pick-list choice, Ctrl-O and Ctrl-I, back and forth, `:ls` and `:ls!`, `:bn`, `:b N`), reading the tabs in order and the selected one, and run it before the fix: the replace cases keep the tab left.

## 2. The option

- [ ] 2.1 Add `jumptab` (`replace` or `keep`) to `Domain::Options` (`carat/domain/options.rb`), `keep` in `Options.new`, `option.jumptab replace` in `config/default.caratrc` and its mirror (`make gen-config`); proven by the `option.jumptab` rows of `test/domain_options_config.rb` ("An unknown jumptab mode is refused and keeps the earlier value") and `test/config_sync.rb`.

## 3. Unlisted buffers

- [ ] 3.1 Add the `listed` member and `tabless?` to `Domain::Buffer` (`carat/domain/buffer.rb`); make `BufferList#add` list a buffer again, and `step_from`, `file_count`, and `replacement_for` skip tabless buffers (`carat/domain/buffer_list.rb`); paint only tabbed buffers in `Adapters::TabBar`; proven by ":bn skips an unlisted buffer" and ":b N lists an unlisted buffer again" in `test/adapters_definitions.rb`.
- [ ] 3.2 Hide unlisted buffers from `:ls`, flag them `u` under `:ls!`, and keep them with the `u` filter in `UseCases::ListBuffers`; proven by "The listing hides an unlisted buffer and the bang shows it" in `test/adapters_definitions.rb`.

## 4. The tab rule

- [ ] 4.1 Add `BufferList#hand_tab(left, target)` and call it from `UseCases::VisitTarget#jump` under `option.jumptab replace` when the target had no tab; proven by the definitions scenarios of `test/adapters_definitions.rb` (the takeover, the position, its own tab, a second window, keep, outside, pick list) and the existing ghost-tab table under `option.jumptab keep`.
- [ ] 4.2 Call `hand_tab` from `UseCases::WalkJumps#call` by the same rule; proven by "Ctrl-O gives the buffer gd left its tab back" and "Back and forth keeps the tab's position" in `test/adapters_definitions.rb`.

## 5. Docs

- [ ] 5.1 Update the `gd`, `<C-o>`, `<C-i>`, and `:ls` rows of `docs/compatibility.md` and add the `option.jumptab` row, the `VisitTarget` and `BufferList` lines of `docs/codebase-map.md`, and the `gd` sentence and option list of `README.md`.
- [ ] 5.2 Run `make gates`, `make spec-validate`, `make docs-lint`, and `make lint`, and fix what fails.
