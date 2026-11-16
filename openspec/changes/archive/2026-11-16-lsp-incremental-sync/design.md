# Design

## Context

`JsonRpcLanguageGateway#sync_buffer` compares the buffer's change counters with the ones stored at the last send and, when they moved, sends the whole text. The buffer's `ChangeRecord`s are line-granular and live in its transactions and undo tree; `revert_to` undoes records without recording and decrements the counter, so the records since the last sync are not a reliable edit log at an idle tick. Positions in the protocol are zero-based lines and UTF-16 code units; the gateway already has `utf16_length`.

## Goals / Non-Goals

**Goals:**
- Read the announced sync kind, number or options object, once at `initialized`.
- Under kind 2 send a ranged change that, applied to the server's text, gives the buffer, for any edits, undo included, and in UTF-16 units.
- Keep kind 1 as today and send no `didChange` under kind 0 or none.
- Leave the edit path and its allocations untouched.

**Non-Goals:**
- One content change per buffer edit, the `openClose` and `save` options, and `willSave`.

## Decisions

- The sync kind is a new `LanguageServer` member `sync_kind` (Integer, 0 until `initialized` reads it). A number is taken as is, a Hash's `change` field likewise; anything else is 0. Only 1 and 2 send a `didChange`.
- Under kind 2 the gateway keeps `texts[uri]`, a copy of the buffer's line array at the last send (the array is copied, its strings shared, since a line string is never mutated in place). At a change it compares the stored lines with the buffer's: the common leading and trailing lines, then within the first and the last differing lines the common leading and trailing bytes, backed off to a character boundary and bounded so prefix and suffix never overlap on a line both sides share. The range runs from the first differing character to the end of the old span, the text is the new span joined with the buffer's line ending. A pure line insert or delete gives a range at column 0. The positions are line indexes and `utf16_length` of the byteslices before them. Because `to_text` always ends in a line ending, the position after the last line (line count, character 0) is valid for the server.
- Diffing the text instead of replaying the records: the records can be reverted unrecorded (`revert_to`) and span several transactions and undo tree nodes between two idle ticks, while the stored lines are exactly what the server holds. One ranged change per sync reproduces the buffer and is minimal for the usual single-place edit; the protocol allows any number of changes per notification.
- Equal text under kind 2 (an edit undone before the idle tick) sends nothing and keeps the version, storing the new counters.
- Under kind 1 nothing is stored, so a full-sync server pays nothing more.

## Risks / Trade-offs

- [Two edits far apart between ticks become one large range] -> correct, only less minimal; idle ticks follow each key burst.
- [The stored line array per document] -> one array of shared strings per open document of a kind 2 server, replaced at each send.
- [A buffer whose line ending is CRLF] -> the protocol counts CRLF as one line break, and the new span is joined with the buffer's own ending, so the ranges stay right.
