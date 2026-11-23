# Design

## Context

`EditorState#show` kept a text in the history only when it had no line feed, which dropped the two-line refusal of `Quit` and `QuitAll` along with listings, and `JumpToMatch` returned its echo as a success outcome, so `show` kept it.

## Goals / Non-Goals

**Goals:**
- Echoes stay out of the history, an error is kept whole, the history is built once in the assembly with one clear and no member nothing reads.

**Non-Goals:**
- Any other message, the notification levels, wording.

## Decisions

- The echo is shown with `show_output`, the existing path for output the history does not keep, rather than a new flag on `Outcome`: `Outcome` is built in several places and the echo is the one case. The wrap message keeps `Outcome.success`, so it stays in the history.
- Whole errors, not whole texts: the only multi-line text that must be kept is an error (the refusal), and a multi-line non-error is a listing (`:registers`, `:ls`). Keying on `error` needs no new parameter.
- `MessageHistory#add` keeps any non-empty text and its callers decide what is a listing; `Notices#add` keeps its one-line rule.
- The levels are dropped from the history, not from `Notices`, which needs them for its lifetimes and its title; the constants stay in `MessageHistory`, where the adapters already read them.
- The history is a required keyword of `EditorState`, built in the assembly and shared by reference with `Notices`; `test/adapters_assembly.rb` checks both hold the one instance.
