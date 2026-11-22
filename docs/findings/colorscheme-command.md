### Packaging and the pull request text are two starts for one text (hidden-option retro)
- Location: .claude/workflows/deliver-change.js, the package and prtext contributor starts
- Why: hidden-option spent package 8,032 output tokens in 14 calls plus prtext 8,397 in 8, 16,429 output tokens (8.2 percent) and 22 of 172 calls (12.8 percent), with 0 findings appended; prtext's 8,397 is the highest of the last 11 feature rows (set-options 8,192, cmdline-editing 1,350); near backlog Pool 10 pr-claims.
- Fix: run the archive, the gated pr.md, and the push in one start when no finding is appended; accepted when that start finishes in at most 12 calls on the next three runs with no prtext round.
