## MODIFIED Requirements

### Requirement: A root's language command names a root and a command
A `language.<name>.lsp.root` line in the defaults or the user file SHALL be accepted when it holds a root and at least one word of a command; a line with fewer words SHALL be reported as "language.<name>.lsp.root needs a root and a command" and ignored. The root SHALL be `~`, a path starting with `~/`, or an absolute path, with no `.` or `..` segment; a line whose root is not SHALL be reported as "language.<name>.lsp.root ROOT is not a root", with ROOT as written, and ignored.

#### Scenario: Root command in the user file
- **WHEN** the user file holds "language.ruby.lsp.root /work docker compose exec app ruby-lsp"
- **THEN** nothing is reported and the line is kept with its words

#### Scenario: Root command without a command
- **WHEN** the user file's first line is "language.ruby.lsp.root /work"
- **THEN** line 1 is reported as "language.ruby.lsp.root needs a root and a command" and ignored

#### Scenario: A root that is not a root is reported
- **WHEN** the user file's lines 1 to 4 are root lines for the roots `src`, `/a/./b`, `/a/../b`, and `/a/b`, each with the command `docker`
- **THEN** lines 1, 2, and 3 are reported as "language.ruby.lsp.root src is not a root", "language.ruby.lsp.root /a/./b is not a root", and "language.ruby.lsp.root /a/../b is not a root" and ignored, and line 4 is kept
