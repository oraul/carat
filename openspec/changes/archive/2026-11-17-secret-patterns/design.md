# Design

## Context

`tools/scan_text.sh` is the one scanner of forbidden text. It turns its input into rows `FLAG<TAB>WHERE:LINE<TAB>WHERE<TAB>TEXT` and writes one work file per check, line-aligned with the labels; the secret pass greps `KEY_RE|TOKEN_RE` and `ASSIGN_RE` (without case) over the text file and prints each matching row's label with `secret: [not shown]`. In `--diff` mode WHERE is the diff's path, in file mode the file as passed, and for standard input or `--where NAME` the name.

## Goals / Non-Goals

Goals: refuse an unquoted secret literal in YAML, TOML, shell, and `.caratrc` files; leave code alone (`token = next_token` in Ruby). Non-goals: new token shapes, any other gate rule, widening `ASSIGN_RE`.

## Decisions

- Filter by path in the scanner's row split, not by a new column: the awk that writes `text` also writes `config`, the row's text when WHERE matches `CONFIG_PATH_RE` (exported to it like `MODEL_PATH_RE`), else an empty line, so the labels stay aligned and the existing label mapping is reused. Alternative: widen `ASSIGN_RE`, refused by the brief, since it would refuse code.
- `BARE_ASSIGN_RE` has two forms. The separator form (`=`, `:`, `=>`) covers YAML, TOML, and shell. The `.caratrc` form `scope.name value` has no separator, so a whole line whose name has a dot and ends in a secret word, then a value, then only spaces, is refused; requiring the dot and the whole line keeps a YAML prose line such as `secret ingredients` out.
- The value starts with a letter or digit, holds no quote, dollar sign, backquote, parenthesis, or space, has eight characters or more, and ends at a space or the line's end. So a variable (`$TOKEN`, `${TOKEN}`), a command substitution, a YAML tag or anchor, and a call (`ENV.fetch(...)`, `read_password(prompt)`) pass, and a quoted value is left to `ASSIGN_RE`.
- `TOKEN_RE` stays: the platforms the project uses are GitHub (every `gh?_` prefix and `github_pat_`), npm (`npm_`), and the `sk-` keys, all present.
- The new test fixtures in `tools/tools_test.sh`, itself a shell file the content gate now checks for bare assignments, split each secret word in pieces like the existing secret fixtures.

## Risks / Trade-offs

- A literal non-secret of eight characters or more assigned to a secret-named key in a configuration file (`token: required`) is refused; the author quotes nothing away, so the line must be renamed or the value read from a variable. Such lines are rare and the cost of a missed secret is higher. A scan of the repository's 211 configuration files at 8b54500 finds one such line, a placeholder in a `tools/new.sh` comment, which the content gate reads only if a branch edits it.
