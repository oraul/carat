# Tasks

## 1. Predicate-like members and keywords (a)

- [ ] 1.1 `test/lint.rb` `member_problem`, run in the naming loop. Tested by the self-check "the member and keyword name rule" (an `attr_reader :has_text`, a `Struct.new(:is_open, ...)`, a `Data.define(:get_x)`, and a `def initialize(has_x:)` refused; `:pattern`, `history:`, and a positional `is_x` passed) and "no lint violations".

## 2. The port table (b)

- [ ] 2.1 `test/lint.rb` `port_rows` and `port_problems` over `carat/ports/*.rb` and `docs/architecture.md`. Tested by the self-check "the port table rule" (a missing method, a method the port lacks, a port without a row, and a full row passing) and "no lint violations".
- [ ] 2.2 `docs/architecture.md` section 6: `LanguageServicePort#start`.

## 3. Shared holders (c)

- [ ] 3.1 `carat/use_cases/dispatcher.rb`, `carat/use_cases/handle_key.rb`, `carat/use_cases/repeat_last.rb`: the readers of the stored shared keywords.
- [ ] 3.2 `test/adapters_assembly.rb`: a strangers row for every holder the rule finds unnamed. Tested by `make test-one T=test/adapters_assembly.rb`.
- [ ] 3.3 `test/lint.rb` `assembly_readers` and `holder_problems`. Tested by the self-check "the shared holder rule" (a stored shared keyword without a reader, a shared reader the test never names, a named one and a non-shared one passing) and "no lint violations".

## 4. Changed tools need a case (d)

- [ ] 4.1 `tools/gates.sh` `gate_cases`, in `static` and `pre-push`, and its usage line. Tested by the `tools/tools_test.sh` cases "gates: cases refuses a changed tool without a case", "gates: cases passes a changed tool with a case", "gates: cases passes a comment-only tool change", and "gates: cases leaves a branch without tools alone".

## 5. Docs and bookkeeping

- [ ] 5.1 `docs/codebase-map.md` (the lint and gates lines), `docs/architecture.md` section 10 if it lists the lint rules.
- [ ] 5.2 `docs/backlog.md`: remove 'The dispatcher and HandleKey hold shared objects without readers' and the stale 'The hover owner is spelled in two use cases'.
- [ ] 5.3 Run `make lint`, `make test-one T=test/adapters_assembly.rb`, `make tools-test`, `make docs-lint`, `make gates`, `make spec-validate`, and `openspec validate implement-contracts --strict --no-interactive`.
