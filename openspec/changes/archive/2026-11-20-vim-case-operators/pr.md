feat(operators): add the g~ gu gU case operators

## Summary

Adds the Neovim case operators g~, gu, and gU in normal mode, over a motion, a text object, or a count, with the linewise g~~ guu gUU forms, and makes them act on the selection in the visual modes. Only the single-character ~ and the visual ~ u U changed case before, so a word or a counted range could not be recased with an operator.

---

## Changes

- Add the pending operators operator.swap_case, operator.lowercase, and operator.uppercase, bound in normal, operator_pending, visual, visual_line, and visual_block by keymap lines in config/default.caratrc, mirrored by make gen-config.
- Add Operators.recase_range and the recase row helpers, so a case operator writes no register, leaves the cursor at the start of the range, repeats with the dot command, and undoes in one step.
- Change Operators.recase to map each letter by itself as Neovim does, so a multibyte letter such as the German sharp s or the Turkish dotted capital I matches Neovim for the new operators and for ~ and the visual ~ u U.
- Change the visual case keys so a selection that changes nothing records no edit, while a visual r with a character still undoes in one step.
- Register the three operators in OperatorHandler and the selection handler, and build the shared recase use case once in EditorAssembly.
- Add test/editor_case_operators.rb with table-driven rows per key, multibyte letters, dot repeat, undo, and the visual modes, and update the assembly and substitute snapshots.
- Document the operators in docs/compatibility.md, docs/actions.md, the code map, the README operator list, and the CLAUDE.md wording for the visual modes, and add the Case operators requirement to the operators spec.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the quality review, pass with no blocking finding, and the benchmark review, pass.
- Run the checker stages docs-lint, dev-build, test-build, test-run (116 of 116 tests pass), diagnose, bench-budget, tools-test, gates, and metrics at the reviewed commit, all exit 0.
- Run make spec-validate after archiving, 54 of 54 items pass.
- Run make gates and make docs-lint on the final branch, both pass.

---

## Notes

A visual ~, u, or U that changes nothing is not recorded as the last change, so a later dot repeats the change before it, where Neovim repeats the case key; this and a header comment wrap are recorded in the findings file as follow-ups. The lane queue decisions were shortened to keep the queues within their shared byte budget. Brief assumption: the five modes are the five binding modes of CLAUDE.md, since ~ u U already worked in the three visual modes.
