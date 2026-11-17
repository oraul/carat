# Tasks

## 1. One root check

- [x] 1.1 Add `RootWord.root?` in `carat/domain/root_word.rb`, listed in `carat.rb`, and make `TrustedRoots.root_of` (`carat/domain/trusted_roots.rb`) use it; verify with the root word table in `test/domain_trusted_roots.rb`, the existing cover and under tables, and "a root that is no root covers nothing" in `test/adapters_language_gateway.rb`

## 2. Report a root that is not a root

- [x] 2.1 Note and refuse a `lsp.root` line whose first word fails `RootWord.root?` in `Config#language?` (`carat/domain/config.rb`); verify with "A root that is not a root is reported" in `test/domain_rc_parser.rb`

## 3. Documents

- [ ] 3.1 Update `docs/codebase-map.md` area 3 (the new file, the config check) and the README language paragraph; verify `make docs-lint` and `make gates` pass
