# Backlog: carat/use_cases/files/save_all.rb

## SaveAll branches twice for one assignment

- Where: `carat/use_cases/files/save_all.rb` line 164 at c1b3a12 (periodic quality). Queued in `file-access-tidy`.
- Why it matters: both branches assign the same result and differ only in the failed flag.
- Fix outline: one assignment and one conditional flag.
- Category: editor
- Added: 2026-11-09

### SaveAll#call never reads its state parameter
- Location: carat/use_cases/files/save_all.rb:24
- Why: an unused parameter every caller must supply. Folded into ex-handlers-tidy.
- Fix: drop it and update FileCommandHandler and the map.
- Category: editor
- Added: 2026-11-17
