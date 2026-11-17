## 1. The target address

- [ ] 1.1 Add `ExRange.target` to `carat/domain/ex_range.rb`: the target line or `E16`, `E20`, and `Not implemented: address x`; proved by rows in `test/domain_ex_range.rb`

## 2. The commands

- [ ] 2.1 Add `MoveCommandHandler` (`m[ove]`) under `carat/use_cases/ex/` with `make new-ex-command`: the move, `E134`, the no-op target, the cursor, `N lines moved`, `E477`; proved by `test/editor_line_commands.rb`
- [ ] 2.2 Add `CopyCommandHandler` (`co[py]`, `t`) the same way: the copy, the cursor, `N more lines`, `E477`; proved by `test/editor_line_commands.rb`
- [ ] 2.3 Register both in `EditorAssembly` after `:messages`, before the plugin commands; proved by the `test/use_cases_ex.rb` spelling rows

## 3. Tests and docs

- [ ] 3.1 Add `test/editor_line_commands.rb` with `make new-test`: every delta scenario by name, `:g/x/m0`, undo, `E134`, `E16`
- [ ] 3.2 Update `docs/compatibility.md` (rows, the Global section's sentence), `docs/codebase-map.md` area 12, and `docs/architecture.md` section 5.2; `make docs-lint`
