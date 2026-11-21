# Backlog: carat/use_cases/files/list_tree.rb

## Copies and placement found by the periodic review at 186ddfb

- Where: `ListTree#probe` (`carat/use_cases/files/list_tree.rb` line 65) repeats `ProbePath#call` and asks the port itself, against `docs/architecture.md` section 5, queued in `periodic-blockers-b`; `CompleteWord` (`carat/use_cases/completion/complete_word.rb` line 47) copies the word-before-cursor slice of `show_completion.rb` lines 74 to 77, queued in `completion-tidy`; `Layout#fixed_width?` (`carat/domain/layout.rb` line 299) is used only by its test, queued in `slots-tidy`; `JumpList#step` (`carat/domain/jump_list.rb` line 55) pushes before the range check, so Ctrl-O on an empty list adds an entry, queued in `definitions-tidy`; `Icons::NAMES` (`carat/domain/icons.rb` line 13) is read nowhere and `DecodedLine` and `Cell` (`decoded_line.rb` line 15, `cell.rb` line 274) are never-changed values declared as `Struct`, queued in `carat-palette`. Periodic quality at 186ddfb. Raised again at ce6abdb (periodic quality): `ListTree#probe` (`list_tree.rb:67`) as a blocker; the `CompleteWord` copy (`complete_word.rb:47`) and `Layout#fixed_width?` (`layout.rb:299`).
- Why it matters: two probes and two slices drift; dead surface; a jump that answers nothing moved after adding an entry; records against the Data rule.
- Fix outline: inject the one `probe_path:` into `ListTree` and use `Domain::PathPolicy.inside?`; one domain prefix helper; delete `fixed_width?`; return -1 before the push with a `test/domain_jump_list.rb` row; test `NAMES` against each set or drop it; `Data` subclasses or the Spinel reason in the comment.
- Also: docs/architecture.md, carat/use_cases/completion/complete_word.rb, carat/domain/layout.rb, carat/domain/jump_list.rb, carat/domain/icons.rb, test/domain_jump_list.rb
- Category: editor
- Added: 2026-11-10

### ListTree copies ProbePath and spells inside? another way

- Location: carat/use_cases/files/list_tree.rb:67 and :98 (sprint-4 sweep, quality).
- Why: probe repeats ProbePath#call, the map's one place asking the port about a path; ListTree calls PluginApi::Paths.inside? where the others use Domain::PathPolicy.inside?.
- Fix: inject probe_path; use one spelling.
- Category: editor
- Added: 2026-11-14
