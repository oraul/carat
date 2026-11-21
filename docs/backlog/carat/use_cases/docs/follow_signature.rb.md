# Backlog: carat/use_cases/docs/follow_signature.rb

## Parameter info follows a call on one row only

- Where: `FollowSignature` in `carat/use_cases/docs/follow_signature.rb` and `SignatureRequest.open_paren` in `carat/domain/signature_request.rb` (`parameter-info`): the call is the innermost `(` left open before the cursor on its row, scanned as plain bytes.
- Why it matters: a call whose arguments span several rows closes the float at the first line break, and a `(` inside a string or comment can start a follow the server then answers empty.
- Fix outline: keep following across rows while the server answers a signature (stop on an empty answer rather than on a row change), and skip strings and comments with the syntax cache's tokens when the buffer has them, with rows in `test/adapters_signature.rb`.
- Also: carat/domain/signature_request.rb, test/adapters_signature.rb
- Category: editor
- Added: 2026-11-07
