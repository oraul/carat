# Backlog: carat/use_cases/docs/request_signature.rb

## A signature request in a buffer without a path re-asks on every key

- Where: `carat/use_cases/docs/request_signature.rb` line 24 at c1b3a12; the gateway's send drops a pathless buffer silently. Queued in `signature-tidy`.
- Why it matters: FollowSignature keeps following a call that is never sent, asking again on every key, while RequestHover refuses such a buffer up front.
- Fix outline: refuse a pathless buffer as RequestHover does, with a row typing ( in an unnamed ruby buffer expecting no active signature.
- Category: editor
- Added: 2026-11-09
