# Tasks

## 1. Configuration

- [ ] 1.1 Accept the `lsp.root` language setting in `carat/domain/config.rb` with at least a root and a command word, noting a shorter line; verify with the rows "a root command" and "a root command without a command" and the check "an untrusted file cannot set a root command" in `test/domain_rc_parser.rb`, and the project-file check in `test/adapters_config_gateway.rb`
- [ ] 1.2 Document the key in the comment of `config/default.caratrc`, regenerate `carat/domain/default_config.rb` with `make gen-config`, and verify `make test-one T=test/config_sync.rb` passes

## 2. Server command

- [ ] 2.1 Add `TrustedRoots.under?` in `carat/domain/trusted_roots.rb`, used by `cover?`; verify with its table in `test/domain_trusted_roots.rb`
- [ ] 2.2 Pick the last covering root line's command in `JsonRpcLanguageGateway#words_of`; verify with the root table in `test/adapters_language_gateway.rb` (root's command under the root, the default elsewhere, the later line winning, a word that is no root)
- [ ] 2.3 Update README.md, `docs/architecture.md` section 7, and `docs/codebase-map.md` (areas 3 and 17) for the key; verify `make docs-lint` and `make gates` pass

## Workflow follow-up

- Archive the change after the checks and reviews pass.
