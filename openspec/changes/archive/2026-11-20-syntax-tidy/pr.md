fix(syntax): count ruby nesting in full and cut names by bytes

## Summary

Ruby percent literals and interpolations nested deeper than the line state encodes now stay open to their real end on the same line, and filetype detection cuts program names and basenames by bytes. Before, the rest of such a line was drawn with the wrong colors, `Filetype.program_type` mixed character lengths with byte reads, and the byte basename was cut in three places, one of them by characters. This is the first part of the backlog lane's syntax tidy, the bugs a test can show broken today.

---

## Changes

- Fix the Ruby tokenizer to count the nesting depth of a paired delimiter and the brace depth of an interpolation in full within a line, clamping them to the state's field (7 pairs, 3 braces) only when the line's state is packed.
- Add `Filetype.program_name`, which cuts the version digits and dots off a program name by bytes, and make `program_type` look that name up.
- Remove `Filetype.base` and make `from_name` and `from_shebang` use `PluginApi::Paths.basename`, leaving one basename helper.
- Change `Buffer#name_start` to follow `Paths.basename` on the root, so a buffer at `/` starts its name at byte 0 and its buffer tab draws `/` instead of an empty name, still allocating nothing per frame.
- Add a scenario for nesting deeper than the state holds to the `ruby-syntax` requirements on interpolation and percent literals, and a requirement that such nesting is clamped at the end of the line.
- Add tests for the deep nesting, the byte cut of multi-byte program names and basenames, the root's name start, and the root's buffer tab.
- Document the program name cut and the depth clamp in the code map's syntax-highlighting area.
- Record the two headings split off this change in its findings file.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the quality review of the committed diff, pass with no blocking or advisory finding
- Run the benchmark review against main's recorded figures, pass
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run make spec-validate after the archive, all 54 items pass

---

## Notes

The queue line's ten headings were split at the start. Two are recorded in the findings file rather than fixed: tokenizing every row above on G, since any fix trades exact colors for speed and changes a specified behavior, and the cursor line doubling the highlight group-id space, which breaks nothing and needs a redesign of how the layers are carried. The other five (the security marks of the run state tool, the options and boolean switches of :set, themes at runtime, and semantic highlighting) are queued separately. No plugin API change, so no version bump.
