
### A visual case key that changes nothing is not the dot command's last change
- Location: carat/use_cases/visual/recase_selection.rb (the set_lines guard) and Dispatcher#record, which needs transaction_edits to grow
- Why: a visual ~, u, or U over text already in the target case makes no edit, so a later . repeats the change before it, where Neovim repeats the case key; normal-mode gUU over capitals already records through Operators.recase_range, so the two differ
- Fix: let the dispatcher record a repeat-kind command that made no edit, or state the choice in the operators spec, with an editor row such as xvlgUl. on aBC
