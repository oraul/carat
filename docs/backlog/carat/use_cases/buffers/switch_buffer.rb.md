# Backlog: carat/use_cases/buffers/switch_buffer.rb

## No row reaches the E85 branch of :bfirst and :blast

- Where: `carat/use_cases/buffers/switch_buffer.rb:37`, against `docs/compatibility.md:292`. Quality advisory of `jump-list`.
- Why it matters: the compatibility rows promise E85 for a list without file buffers, but no test runs that branch, so a regression there goes unseen.
- Fix outline: a row in `test/editor_buffers.rb` running `:bfirst` and `:blast` with only a scratch buffer, and with no file buffer, listed. Queue item `buffer-list-tidy`.
- Also: docs/compatibility.md, test/editor_buffers.rb
- Category: editor
- Added: 2026-11-10

### Ctrl-^ shows a scratch alternate buffer that N Ctrl-^ and :b N refuse (`jump-motions` quality advisory)

- Location: `carat/use_cases/buffers/switch_buffer.rb:37`.
- Why it matters: load records a scratch buffer's id as the alternate, so Ctrl-^ shows a scratch buffer while 'N Ctrl-^' and ':b N' refuse the same buffer with E86, an inconsistency between paths to one buffer.
- Fix outline: skip scratch buffers when load sets the alternate, or refuse a scratch alternate in SwitchBuffer as :number does, with an editor_jumps case.
- Category: editor
- Added: 2026-11-12

## carat/use_cases/buffers/switch_buffer.rb:37 Ctrl-^ shows a scratch alternate that N Ctrl-^ and :b N refuse (jump-motions, quality advisory)

- Location: carat/use_cases/buffers/switch_buffer.rb:37
- Why: load records a scratch buffer's id as the alternate, so Ctrl-^ shows it, while 'N Ctrl-^' and ':b N' refuse a scratch buffer with E86, an inconsistent answer for the same buffer.
- Fix outline: skip scratch buffers when load sets the alternate, or refuse a scratch alternate in SwitchBuffer as :number does.
- Category: editor
- Added: 2026-11-12
