### Grep rows still pass the other invisible format code points

- Location: carat/plugins/finder/grep.rb:221 (`format_control?`), security Low (3)
- Why: the word joiner and invisible operators U+2060 to U+2064, the deprecated format controls U+206A to U+206F, the interlinear annotation marks U+FFF9 to U+FFFB, the tag characters U+E0001 and U+E0020 to U+E007F, and U+180E pass from untrusted file text into grep rows, so a crafted file line could hide characters in a row; they cannot reorder runs or move the path:line prefix, since every bidi embedding, override, isolate, and mark is already replaced.
- Fix: widen `format_control?` to every Unicode Cf code point a row can carry (add U+2060 to U+2064, U+206A to U+206F, U+FFF9 to U+FFFB, U+180E, and U+E0000 to U+E007F), and add one test row per added range in test/editor_finder_grep.rb.
### Feature-lane quality first pass keeps failing after the checklist changes
- Location: .claude/agents/contributor.md (the self-check before a done result)
- Why: 7 of the last 11 feature rows record quality:0, finder-grep (#229) and finder-grep-b both 0 after contributor-checklist (#226); finder-grep-b's one rework round on an untested HIT_ROOM clamp cost 95,622 output tokens, 34% of its 281,571; overall 103/189 (finder-grep-b retro note 10).
- Fix: have the contributor's own check find an untested behavior change before the review; accepted when at least 7 of the next 10 feature rows record quality:1.

### Feature-lane check phase costs several times the backlog lane's
- Location: .claude/agents/checker.md (the checker start's reading of stage logs)
- Why: finder-grep-b spent 32,288 output tokens over 6 calls on two checks that both passed, about 16,000 per start; the feature lane's last 10 check phases run 4,693 to 153,640 (median about 28,900) against the backlog lane's 1,754 to 23,774 (median about 5,500); check first pass 179/189 (finder-grep-b retro note 11).
- Fix: keep a check whose stages all pass under 8,000 output tokens per checker start over the next 5 rows of each lane, first-pass detection unchanged.
