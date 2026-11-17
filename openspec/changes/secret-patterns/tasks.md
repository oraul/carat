# Tasks

## 1. The rule

- [x] 1.1 `tools/rules.sh`: add `CONFIG_PATH_RE` and `BARE_ASSIGN_RE` beside `ASSIGN_RE`, with the secrets header comment naming them. Tested by the scanner cases of 1.2.
- [x] 1.2 `tools/scan_text.sh`: export `CONFIG_PATH_RE`, write the configuration rows' text to a `config` work file, and grep `BARE_ASSIGN_RE` without case over it in the secret pass. Tested by "scan_text: refuses an unquoted secret assignment: yaml", "toml", "shell", "caratrc", "caratrc setting", "scan_text: refuses an unquoted secret assignment in a configuration file read by name", "scan_text: allows an unquoted assignment in code", and "scan_text: allows a variable or a call in a configuration file" in `tools/tools_test.sh`.
- [x] 1.3 `tools/tools_test.sh` gate cases: "gates: content refuses an unquoted secret in a configuration file" and "gates: content allows an unquoted assignment in code", run by `make tools-test`.

## 2. Docs and checks

- [x] 2.1 `docs/codebase-map.md`: the `tools/rules.sh` and `tools/scan_text.sh` lines name `CONFIG_PATH_RE`, `BARE_ASSIGN_RE`, and the configuration-row check; `make docs-lint` passes.
- [x] 2.2 Run `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate`, all pass.
