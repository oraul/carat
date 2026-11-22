# Design

## Context

The finder keeps one picker at a time. `open(host, source, query, selected)` lists the source, opens the live prompt on the query, and filters; `close` records the source, query, and highlight for the resume and clears the state; `pick` already closes the prompt without an answer (`close_prompt`) before closing the picker. Every change of the typed text reaches `on_prompt_change`, which stores it in `@query`.

## Goals / Non-Goals

**Goals:**
- Switch between the file and grep pickers keeping the text, and grep the word under the cursor, with no API change.

**Non-Goals:**
- A new host request, a `<cword>` that looks right of the cursor, switching to the buffer or recent picker, and a configurable switch key beyond the manifest's and the configuration's existing rebinding.

## Decisions

- The switch is `close_prompt`, the finder's own `close`, then `open` on the other source with the stored `@query` and highlight 0, so the prompt, the list, the floats, and the grep index are built by the one path every opening uses, and a key typed afterwards behaves as in any picker. It costs the grep's one read of the files when the target is grep, as opening it does. Alternative: keeping the open prompt and swapping only the list, which `live_prompt`'s one-prompt rule and the grep index's load make no simpler.
- The word is read in `on_action` with `read_buffer(0)`: its row, column, and copied lines give the line and the code point column of the cursor; `Matcher.word_at` walks the line's bytes to that column (continuation bytes skipped), then out to the edges of the keyword run, and returns a validated UTF-8 string. It is a module function of `Matcher`, which already owns the bytes' word classes, so it is tested alone and allocates one string.
- `<C-g>` joins `KEYS`, the bindings every picker's prompt passes to `live_prompt`; they answer before the command-line keymap while the prompt is open.

## Risks / Trade-offs

- A long line is walked once from its start, not per key; the one-off cost is linear.
- `close` records the left picker for the resume, so a resume after a switch and Esc opens the picker the switch ended on, since its close overwrites the record.
