# Backlog: carat/domain/signature_request.rb

## Signature help reads the cursor column as a byte index

- Where: `open_paren` in `carat/domain/signature_request.rb` line 147, and the row at `test/domain_signature_request.rb` line 41, at 38628bb (periodic quality blocking). Queued in `signature-tidy`.
- Why it matters: the column is a character index, so with multibyte text before the `(` the scan starts left of the cursor and signature help never starts; the test row passes a byte column the editor never gives.
- Fix outline: convert the column to its byte offset before scanning, keep one unit, and add rows with multibyte text before the `(` at the character column.
- Also: test/domain_signature_request.rb
- Category: editor
- Added: 2026-11-09
