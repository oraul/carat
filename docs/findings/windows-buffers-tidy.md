### The workflow trusts an agent-reported head without git
- Location: .claude/workflows/deliver-change.js:776
- Why: a fabricated sha sharing a 7-character prefix stopped a passing run at check and made record lines fail.
- Fix: resolve each reported head with git rev-parse in the lane and stop on a mismatch.

### The :e and :w messages still print a newline in a file name as a line break
- Location: carat/use_cases/files/open_file.rb:42, :63, :64; carat/use_cases/files/save_file.rb:56
- Why: these messages still put a raw path in quotes, so a file name holding a newline forges message lines the way `:ls` and E162 did before windows-buffers-tidy; no entry tracked them once the proposal left them out of scope.
- Fix: pass the path through Domain::ControlText.caret in those messages, with an editor test of a newline name for each.
