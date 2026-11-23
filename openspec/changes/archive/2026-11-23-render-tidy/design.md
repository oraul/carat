# Design

## Context

Keys are Integer codes with flag bits (`Key::ALT`). A paste has to cross `InputController` and `HandleKey` in order with the keys around it, and never reach a keymap.

## Decisions

- A flag bit, `Key::PASTED`, on each pasted code, like `Key::ALT`: order is kept, no new port or queue, and `HandleKey#call` tests it once before its lookup. The decoder drops `Esc` and the other control bytes of a paste, so nothing a paste carries can leave a mode or reach a binding.
- The decoder reads a paste with a local index and consumes once, so a large paste is linear, not a copy per byte.
- A paste short of its end mark keeps its bytes pending and `flush` returns nothing for it, so the escape timeout never turns a pasted Escape into the Escape key. The cost is that a terminal that never sends the end mark leaves the decoder in the paste.
- Normal and the other modes ignore a paste: running its characters as commands is the hazard, and putting the text in is a new feature.
- A row painted after the highlighting budget stopped gets the stamp -1 in the row record, which no frame computes, so the next frame (fresh budget) repaints it; rows before the stop keep their stamp.
- `paint_row`, `paint_matches`, and `paint_pair` take the row, currency, and number group as arguments: the values are per row, and the instance variables hid that.
