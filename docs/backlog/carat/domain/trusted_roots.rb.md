# Backlog: carat/domain/trusted_roots.rb

### TrustedRoots#cover? repeats under?'s absolute check

- Location: carat/domain/trusted_roots.rb:19, :35 (sweep, quality).
- Why: cover? checks cwd is absolute while under? already checks every word.
- Fix outline: drop the check from cover?.
- Category: editor
- Added: 2026-11-17
