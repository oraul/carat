# Design

## Context

The palette and the finder both hold the command line (`Mode::CMDLINE`) for their typed text and show a float for the list. `FramePresenter#paint_message` draws the prompt and the text on the last row and `place_cursor` puts the cursor there.

## Goals / Non-Goals

**Goals:**
- The query row and the cursor inside the float for the palette and every finder picker, one prompt text and one `N/M` title form.
- `PICKER_BUDGETS` held.

**Non-Goals:**
- The dim count, the left-aligned title, the bottom-border keys, and the joined query/list/preview frame (`float-polish`, `finder-refined`).
- Scrolling a query wider than the float.

## Decisions

- The text stays the command line's (`state.cmdline`, its cursor, its keys, the live-prompt keymap, the answer on Enter); only where it is drawn moves. The presenter finds the float (`prompt_float`): the palette's own float while active, else the float a plugin attached to its prompt (`PluginUi#prompt_float`). It draws nothing on the command-line row and puts the cursor at the float's first text row, `window.col` plus the cells of the prompt and the text before the cursor, kept inside the text area.
- The owner writes the first row. The palette (`FollowPalette`) and the finder already rebuild the float's lines after every change of text, so the row costs one string a key; no new draw path, and `lh-float` is untouched. The cursor moves (Left, Home) change no text, so they need no refill.
- A new request, `float_prompt(window)`, rather than a rule such as "the plugin's first float": the finder reopens its floats when the screen changes, and an explicit attachment survives that (it is re-sent after each refresh and when Enter with no match opens the prompt again). It is refused for the current window, a float of another plugin, and with no open prompt, and ends with the prompt (`PluginUi#close_prompt`) or when the float is gone (the presenter looks the id up, so a closed float falls back to the command-line row).
- The palette's height is the list rows plus one; with fewer than two rows of room it shows no float, and the prompt stays on the command line rather than disappearing.
- Selected rows move down by one (`FloatWindow#selected`, the finder's style spans).

## Risks / Trade-offs

- A query longer than the float is cut, not scrolled; the cursor stays on the last cell. Accepted: the command line had the same limit on a narrow screen.
- The API minor bump touches the version-naming scenarios of `plugin-host` and their tests.
