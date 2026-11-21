# Backlog: carat/use_cases/actions/operator_handler.rb

### carat/use_cases/actions/operator_handler.rb:29: public attr_reader :recase_selection (and carat/use_cases/actions/selection_handler.rb:31) exists only for the (sprint-22 sweep quality)

- Location: `carat/use_cases/actions/operator_handler.rb:29`
- Why: public attr_reader :recase_selection (and carat/use_cases/actions/selection_handler.rb:31) exists only for the shared-instance check in test/adapters_assembly.rb:146-147, widening the handlers past call where d7f5de8 moved such checks to the WiringLedger
- Fix: record both holders' recase_selection in EditorAssembly's ledger, read it there in the assembly test, and drop the two readers
- Also: carat/use_cases/actions/selection_handler.rb, test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-20
