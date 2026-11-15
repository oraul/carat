refactor(spinel): read untyped values through typed json readers

## Summary

Reads the language-server messages, the document symbol answer, and the untyped test table values through the typed readers of Carat::Json instead of indexing untyped values, so the test runner compiled at Spinel b582d53e makes 125 code generation rebuilds of the load record instead of 731. From Spinel 2440954d1 on, every index on an untyped receiver costs two whole-program rebuilds, which keeps the pin at 6af548c9; this first part of the requested Spinel bump removes most of that cost, and the next part moves SPINEL_REF.

---

## Changes

- Change JsonRpcLanguageGateway to read every parsed message, result, and notification through Carat::Json.field and Carat::Json.element, keeping the same guards and answers.
- Change SymbolOutline to read the documentSymbol answer the same way.
- Change the test helpers and loops the trace named, DomainGrammarTest, LintTest, and about forty others, to read untyped table values through Carat::Json.element, every check, label, and snapshot unchanged.
- Document in docs/spinel-notes.md the rebuild figures at Spinel b582d53e after this change, 125 instead of 731 rebuilds and 20 s instead of 104 s of code generation, and the causes that remain.
- Document the queue of the next sprint and the metrics row of the last merged change.

---

## Testing

- Run the security review of the committed diff, no findings, passed on the first round.
- Run the quality review, no blocking findings; its six advisories are recorded in the backlog.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run the benchmark check against main's recorded figures, it passes, with the editor and the test runner each at two compile rounds.
- Run make spec-validate after archiving the change, 51 items pass.

---

## Notes

No editor behavior changes and no snapshot changes, so the OpenSpec change sets skip_specs. SPINEL_REF stays at 6af548c9 here; spinel-untyped-bump-b moves it, regenerates the vendored header, and updates the header generator's list of names after this one merges. The figures were measured with the newest Spinel in a separate toolchain under the ignored tmp directory.
