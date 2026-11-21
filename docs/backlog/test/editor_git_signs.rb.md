# Backlog: test/editor_git_signs.rb

### git_signs activation test does not assert the startup activation
- Location: test/editor_git_signs.rb:70
- Why: the scenario calls plugins.activate_all a second time on an editor the harness already activated before git was installed, a state bin/carat never reaches, so the startup activation itself is not asserted.
- Fix: let EditorHarness take a processes double prepared before construction (or a with_plugins variant) and assert the first activation.
- Category: code-quality
- Added: 2026-11-16

### git_signs split assertion cannot tell whether the split refreshed
- Location: test/editor_git_signs.rb:61
- Why: the assertion 'a split keeps the branch' runs while git still answers main, so it cannot tell whether the split refreshed.
- Fix: drop it, or script another branch before the window split if the split's refresh matters.
- Category: code-quality
- Added: 2026-11-16
