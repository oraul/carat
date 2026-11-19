# Design

## Context

`FramePresenter#paint_window` paints a row, then lifts its cells onto the cursor-line layer from `x + gutter`. The number's group is chosen from the layer alone. `shape_of` gives the block to the command line.

## Goals / Non-Goals

Goals: parts 1 to 3 of the queue line, in every palette, with no new allocation per frame. Non-goals: see the proposal.

## Decisions

- The lift starts at `x`: `Frame#lift` adds the layer to any cell whose group is below it, so the sign cell, number, and gap take `CursorLine` as a background where their group has none, and the selection (own background) is untouched.
- A new UI group `LineNrFifth` (DIM) is added after `Removed`, shifting the syntax, icon, and markup ids by one; ids are only used through constants. Rejected: a theme-wide DIM/FAINT split by attribute, which a group id carries better. `FramePresenter#number_group` picks it for relative numbers that are multiples of five off the cursor row.
- `LineNr` becomes FAINT. FAINT is below 4.5:1, so `LineNr` joins the decorations the contrast test holds to 3:1 (as `NonText` and `Whitespace` are).
- `shape_of` returns the bar for `CMDLINE`; the search, palette, and plugin prompts all run in that mode, so they share it. `DECSCUSR` was already steady.

## Risks / Trade-offs

A row repaints only when its record differs; the group of a number follows the number, the layer, and the cursor row, and `relativenumber` is part of the frame's geometry key, so toggling it invalidates both frames' rows.
- `LineNrFifth` uses the theme's DIM as the plan says; in Light+ DIM is the teal accent, so every fifth number is an accent there, a deliberate choice.
