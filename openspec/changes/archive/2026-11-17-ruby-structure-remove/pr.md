feat(ruby)!: remove the unclosed block opener sign

## Summary

Removes the error sign the `ruby` plugin drew on an unclosed block opener, along with the whole-buffer structure check behind it, so the plugin only tokenizes for highlighting again. The check rescanned the whole Ruby buffer on open and after every normal-mode change, taking a 100,000-line Ruby file's open from 22 to 116 ms, and the user asked for its removal.

---

## Changes

- Remove the unclosed-opener sign from the `ruby` plugin together with its `buffer_open`, `buffer_change`, and `mode_change` events, its whole-buffer check, and its Ruby file name tables.
- Remove `Ruby::Structure` and the tokenizer's opener counting (the opens, ends, and loop state and the modifier and endless-definition checks), leaving tokens and line states byte-identical.
- Remove the two ruby-syntax requirements on the sign and the opener counting from `openspec/specs/ruby-syntax/spec.md`.
- Remove the structure editor test and the structure rows of the plugin unit test, and add an editor syntax row proving a Ruby buffer with an unclosed opener shows no sign after insert mode ends and after a normal-mode change.
- Document the removal in the README, the codebase map, and `docs/plugins.md`.
- Record this change's findings file, the plan's queue update, and the `tab-close-c` metrics history row.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run every checker stage at the reviewed commit (docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, tools-test, gates, metrics), all pass, with the highlighting snapshots unchanged.
- Run the quality review, pass with no blocking finding and one advisory, recorded in the findings file.
- Run the benchmark comparison with main's recorded figures, pass with open-ruby at 24.0 allocations as on main and 138.0 microseconds against main's last three of 145.2 to 216.3.
- Run `make spec-validate` after archiving, 53 passed and 0 failed.

---

## Notes

Breaking for users only in that the sign no longer shows on an unclosed `def`, `class`, `do`, or other block opener; a language server's diagnostics still report unbalanced blocks, and nothing calls the removed code. The plugin host's sign API and the `Structure` highlight group stay, since other plugins and Neovim's `class` and `module` highlighting use them. The seven backlog entries the queue item lists all concern the removed check and close with it. The quality advisory on the queue entry's stale line references is carried to the findings file; the plan's queue update removes that entry.
