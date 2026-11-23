# Design

## Context

A tab was two spaces, the name, a space, the mark cell, and a space; the next tab began with its two spaces, so three blanks stood between the mark and the next name. The name was always the last path segment, so two files named alike read alike.

## Goals / Non-Goals

**Goals:**
- Tabs two blank cells apart; the folder shown only when it tells two tabs apart; no object per frame.
- No unread `icon` on `Buffer`.

**Non-Goals:**
- Showing more than one folder, or shortening a long folder; the file icon; the tab-page numbers.

## Decisions

- Drop the trailing space rather than the leading two: the leading pair keeps the first tab's one-cell padding from the edge and the selected group still covers a whole tab.
- Decide "shared" by comparing the bytes of the last segments of the other file tabs (`shares_name?`), on each paint and each width, with no string cut: the rows are a few tabs, and a cache would need a flush on rename, open, and close. Alternative: cache a flag on `Buffer`, which would add a member that every path change must keep right, the fault `icon` had.
- The folder is `Buffer#parent_start` up to `name_start`, written from the path by `put_from` in the dim group, then the name's cells set to the tab's group with `fill`, as `put_from` cuts no span.
- The dim is `MsgDim` on the selected tab, whose background is the editor's, and `TabLine` on the others, already the dim of the panel they sit on; bare, the tab's own group.
