# Tasks

## 1. Reproduction

- [x] 1.1 Add the table of `gd` targets (inside, outside, linked out, outside and already listed) reading the tab row, the selected tab, the current buffer, and the buffers listed to `test/adapters_definitions.rb`, and run it before the fix: the outside and linked-out cases have no tab row and no selected tab, the listed case shows a second copy with the file's tab unselected.

## 2. Read-only file buffers

- [x] 2.1 Add the `readonly` member to `Domain::Buffer` (`carat/domain/buffer.rb`), false by default; proven by the table of `test/adapters_definitions.rb`.
- [x] 2.2 Refuse a read-only buffer in `UseCases::SaveFile` with `E45: 'readonly' option is set`, before any path; proven by "A target outside the project opens read-only" and "Writing a read-only buffer is refused" in `test/adapters_definitions.rb`.
- [x] 2.3 Open an outside or linked-out target in `UseCases::VisitTarget#view` as a listed read-only file buffer, showing a listed buffer of the file first, and drop the `:definitions` scratch-view clauses of `jump` and `listed_for`; proven by the table's four cases and "The read-only target's tab selects and closes like the others" in `test/adapters_definitions.rb`.
- [x] 2.4 Show `=` in the fourth flag column of `UseCases::ListBuffers` for a read-only buffer and let the `=` filter keep them; proven by "A read-only buffer in the listing" and "Filtered by the read-only flag" in `test/adapters_definitions.rb`, and the existing scenarios named in `test/editor_buffers.rb`.

## 3. Docs

- [x] 3.1 Update the `gd` and `:ls` rows and the differences paragraph of `docs/compatibility.md`, the `VisitTarget` line of `docs/codebase-map.md`, and the `gd` sentence of `README.md`.
- [x] 3.2 Run `make gates`, `make spec-validate`, `make docs-lint`, and `make lint`, and fix what fails.
