require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_frame")
D = Carat::Domain
H = D::Highlight

# A fresh frame: flat cells, all blank, every row dirty, no base.
f = D::Frame.new(3, 5)
t.assert_equal([15, 15, 15], [f.codes.length, f.widths.length, f.hls.length], "three flat arrays of rows * cols cells")
t.assert_equal([D::Frame::SPACE, 1, H::NORMAL], [f.code_at(2, 4), f.width_at(2, 4), f.hl_at(2, 4)], "a fresh cell is a blank")
t.assert_equal([0, 1, 2], f.dirty_rows, "every row of a fresh frame is dirty")
t.assert_equal([[0, 1, 2], -1, 0], [f.sources, f.base_serial, f.scroll_count], "a fresh frame has no base and no scroll")
t.assert_equal(7, f.index(1, 2), "cells are indexed row * cols + col")

# put: one cell per code point, wide characters with a continuation.
t.assert_equal(4, f.put(0, 0, "a中b", H::STATUS), "put returns the column after the text")
t.assert_equal([[97, 1, H::STATUS], [0x4E2D, 2, H::STATUS], [0, 0, H::STATUS], [98, 1, H::STATUS]], [f.cell(0, 0).to_a, f.cell(0, 1).to_a, f.cell(0, 2).to_a, f.cell(0, 3).to_a], "a wide character takes a cell and a continuation cell")
t.assert_equal("a中b", f.row_text(0), "row_text joins the characters and skips continuations")
t.assert_equal(4, f.put(1, 3, "x中", H::NORMAL), "a wide character that would cross the right edge is not written")
t.assert_equal("   x", f.row_text(1), "the row keeps what fit")
t.assert_equal(3, f.put(2, 0, "a\u009Bb", H::NORMAL), "put stores one cell per control code point")
t.assert_equal([97, D::Frame::REPLACEMENT, 98], [f.code_at(2, 0), f.code_at(2, 1), f.code_at(2, 2)], "a C1 control is stored as U+FFFD")
f.put(2, 0, "\u0001\u007F", H::NORMAL)
t.assert_equal([D::Frame::REPLACEMENT, D::Frame::REPLACEMENT], [f.code_at(2, 0), f.code_at(2, 1)], "C0 controls and delete are stored as U+FFFD")
t.assert_equal(2, f.put(2, 0, "éx", H::NORMAL), "a combining mark takes no cell")

# Line numbers, blanks, and highlights.
g = D::Frame.new(2, 8)
g.put_number(0, 0, 3, 42, 4, H::LINE_NUMBER)
t.assert_equal(" 42", g.row_text(0), "a number right-aligned in its field and a space")
t.assert_equal([H::LINE_NUMBER, H::LINE_NUMBER], [g.hl_at(0, 0), g.hl_at(0, 3)], "the whole gutter takes the highlight")
g.put_number(1, 0, 3, 1234, 5, H::LINE_NUMBER)
t.assert_equal("1234", g.row_text(1), "a number wider than its field keeps every digit")
g.put_number(1, 0, 3, 7, 2, H::LINE_NUMBER)
t.assert_equal("  34", g.row_text(1), "only the visible cells of a cut gutter are written")
g.blank(1, 0, 8)
g.fill(1, 2, 5, H::VISUAL)
t.assert_equal([H::NORMAL, H::VISUAL, H::VISUAL, H::NORMAL], [g.hl_at(1, 1), g.hl_at(1, 2), g.hl_at(1, 4), g.hl_at(1, 5)], "fill sets the highlight of a span of cells")
g.blank(1, 0, 99)
t.assert_equal(H::NORMAL, g.hl_at(1, 7), "blank stops at the right edge")

# Comparing rows and the bookkeeping of a paint.
a = D::Frame.new(2, 4)
b = D::Frame.new(2, 4)
a.put(0, 0, "ab", H::NORMAL)
b.put(1, 0, "ab", H::NORMAL)
t.assert_equal([true, false, true], [a.same_row?(0, b, 1), a.same_row?(0, b, 0), a.same_row?(1, b, 0)], "rows are compared cell by cell, from any row of another frame")
b.put(1, 0, "ab", H::STATUS)
t.assert_equal(false, a.same_row?(0, b, 1), "a different highlight is a different row")
t.assert_equal(false, a.same_row?(0, D::Frame.new(2, 5), 0), "a frame of another width never has the same row")
a.reset_rows
t.assert_equal([], a.dirty_rows, "a paint starts with every row clean")
a.add_scroll(0, 1, -1)
t.assert_equal([[0, 1, -1], 1], [a.scrolls, a.scroll_count], "a scroll is three integers")
a.mark_all_dirty
t.assert_equal([[0, 1], 0], [a.dirty_rows, a.scroll_count], "marking every row dirty drops the scrolls")

# Resizing is reallocation: a frame of another size is a new frame.
c = D::Frame.new(4, 6)
t.assert_equal([24, 4, 4], [c.codes.length, c.dirty.length, c.sources.length], "a frame of another size has arrays of its size")

t.finish
