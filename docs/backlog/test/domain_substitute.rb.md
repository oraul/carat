# Backlog: test/domain_substitute.rb

### The never-built substitute check fails its reverted fix only by exhausting memory
- Location: test/domain_substitute.rb, "a replacement past the budget is never built" (files-ex-lows quality review).
- Why: with the charge moved back after the build, the check builds a 16 GiB string, so a regression shows as a runner killed or stalled for want of memory rather than as one FAIL line; the outcome of the fixed code (stopped, unchanged) is the same as the old code's once it had built the string, so no smaller observable tells the two apart.
- Fix: count the bytes `Replacement.expand` builds through a counter the test can read (a `SearchBudget` member of bytes built, or a test double of the budget that records the charges in order), and assert the charge came before any byte was built, with a small string.
none
- Category: code-quality
- Added: 2026-11-22
