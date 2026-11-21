# Backlog: carat/use_cases/actions/message_handler.rb

### The Ctrl-C hint says abandon all changes when nothing is modified

- Location: `carat/use_cases/actions/message_handler.rb:10`.
- Why: on a pristine `[No Name]` buffer the hint tells the user to `:q!` and abandon all changes, spells the name `Carat` where carat writes `carat` everywhere else, copies Neovim's sentence, and clears the start screen (ux-pass review finding 2). Reproduction: start with no file, `<C-c>`, `openspec/changes/archive/*-ux-pass/screens/first-quit-hint.txt`.
- Fix: name `:q` when no buffer is modified and `:q!` only when one is, in carat's own words with a lowercase name, and keep the start screen under the message.
- Category: editor
- Added: 2026-11-15
