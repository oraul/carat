# Backlog: carat/domain/completion_menu.rb

## CompletionMenu cleans every candidate the gateway already cleaned

- Where: `carat/domain/completion_menu.rb` line 57 at cd87445 (`fill` runs `CompletionItem.from_source` over items `json_rpc_language_gateway.rb` line 521 built with it). Periodic quality at cd87445.
- Why it matters: up to 200 items are cleaned twice per new word, two boundaries owning one rule.
- Fix outline: clean at one boundary, the doubles doing the same. Queued in `completion-tidy`.
- Category: ide
- Added: 2026-11-07

## CompletionMenu#chosen repeats the chosen index

- Where: `chosen` in `carat/domain/completion_menu.rb` line 88 at 925d759, which repeats `matches[selected]` beside the new `chosen_index`. Quality advisory in `completion-docs`.
- Why it matters: two spellings of the same choice can drift.
- Fix outline: answer `candidates.at(chosen_index)`. Queued in `completion-docs-tidy`.
- Category: ide
- Added: 2026-11-07

## CompletionMenu's constructor repeats clear

- Where: `carat/domain/completion_menu.rb` lines 37 to 45 against 96 to 103 at b0dd342. Periodic quality. Queued in `completion-docs-tidy`.
- Why it matters: a new member must be reset in two places.
- Fix outline: set the two lists in the constructor, then call `clear`.
- Category: ide
- Added: 2026-11-07
