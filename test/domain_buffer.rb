require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainBufferTest
  D = Carat::Domain

  def self.pos(row, col)
    Carat::Domain::Position.new(row: row, col: col)
  end

  # A table row's values are untyped; the buffer takes typed arrays, and an
  # untyped argument would widen its parameters for the whole program.
  #: (untyped) -> Array[String]
  def self.strings(value)
    out = []
    i = 0
    while i < value.length
      out << value[i].to_s
      i += 1
    end
    out
  end

  def self.range(r1, c1, r2, c2)
    Carat::Domain::Range.charwise(pos(r1, c1), pos(r2, c2))
  end

  # Read helpers for operators: rows are [label, [lines, range], expected].
  def self.rng(r1, c1, r2, c2, inclusive)
    D::Range.new(from: D::Position.new(row: r1, col: c1), to: D::Position.new(row: r2, col: c2), kind: :charwise, inclusive: inclusive)
  end

  # A diagnostic on a row.
  def self.diag(row, severity, message)
    D::Diagnostic.new(row: row.to_i, col: 0, severity: severity.to_i, message: message.to_s)
  end

  # A published list of the diagnostics.
  def self.listed(items)
    list = D::DiagnosticList.new
    items.each { |item| list.add(item) }
    list
  end

  def self.main
    t = Carat::Testing.new("domain_buffer")

    # Loading: rows are [label, text, expected lines].
    t.table([
      ["trailing newline", "one\ntwo\n", ["one", "two"]],
      ["no trailing newline", "one\ntwo", ["one", "two"]],
      ["empty text", "", [""]],
      ["only a newline", "\n", [""]],
      ["blank line in the middle", "a\n\nb\n", ["a", "", "b"]],
      ["windows endings", "a\r\nb\r\n", ["a", "b"]]
    ]) { |text| D::Buffer.from_text(text, nil).lines }

    t.table([
      ["unix ending", "a\nb\n", "\n"],
      ["windows ending", "a\r\nb\r\n", "\r\n"],
      ["no terminator", "a", "\n"]
    ]) { |text| D::Buffer.from_text(text, nil).line_ending }

    t.table([
      ["windows round trip", "a\r\nb\r\n", "a\r\nb\r\n"],
      ["missing final newline added", "a\nb", "a\nb\n"],
      ["empty becomes one newline", "", "\n"]
    ]) { |text| D::Buffer.from_text(text, nil).to_text }

    # Bytes that are not UTF-8 load into their lines and are written back
    # unchanged: rows are [label, text, [lines, file text]].
    t.table([
      ["a Latin-1 letter", "caf\xE9\n", [["caf\xE9"], "caf\xE9\n"]],
      ["an overlong slash", "a\xC0\xAFb\n", [["a\xC0\xAFb"], "a\xC0\xAFb\n"]],
      ["a surrogate", "\xED\xA0\x80\n", [["\xED\xA0\x80"], "\xED\xA0\x80\n"]],
      ["above U+10FFFF", "\xF4\x90\x80\x80\n", [["\xF4\x90\x80\x80"], "\xF4\x90\x80\x80\n"]],
      ["a truncated sequence", "\xE4\xB8\n", [["\xE4\xB8"], "\xE4\xB8\n"]],
      ["a lone continuation byte", "\x80\n", [["\x80"], "\x80\n"]],
      ["a NUL", "a\x00b\n", [["a\x00b"], "a\x00b\n"]],
      ["several lines with illegal bytes", "\xFF\nok\n\xFE\xFF\n", [["\xFF", "ok", "\xFE\xFF"], "\xFF\nok\n\xFE\xFF\n"]],
      ["windows endings with an illegal byte", "\xFFa\r\nb\r\n", [["\xFFa", "b"], "\xFFa\r\nb\r\n"]]
    ]) do |text|
      loaded = D::Buffer.from_text(text.to_s, nil)
      [loaded.lines, loaded.to_text]
    end
    t.assert_equal("\r\n", D::Buffer.from_text("\xFFa\r\nb\r\n", nil).line_ending, "windows endings are found after an illegal byte")
    t.assert_equal("", D::Buffer.from_text("#!/usr/bin/\xFF ruby\n", "x").filetype, "a shebang that is not UTF-8 names no filetype")
    renamed = D::Buffer.from_text("x\n", "src/a.rb")
    icons = [renamed.icon, renamed.name_start]
    renamed.rename("Makefile")
    t.assert_equal([["ruby", 4], ["makefile", 0], "default"], [icons, [renamed.icon, renamed.name_start], D::Buffer.from_text("", nil).icon], "the icon name follows the file name, and the name starts after the last slash")
    hostile = D::Buffer.from_text("a\xFFb\n", nil)
    hostile.insert(pos(0, 1), "\xC0\n\xAF")
    t.assert_equal(["a\xC0", "\xAF\xFFb"], hostile.lines, "text with illegal bytes and a newline is inserted by bytes")

    fresh = D::Buffer.from_text("x\n", "f.txt")
    t.assert_equal(false, fresh.modified?, "loaded buffer is unmodified")
    t.assert_equal("f.txt", fresh.path, "loaded buffer keeps its path")
    t.assert_equal(1, fresh.line_count, "line count")
    t.assert_equal("", fresh.line(5), "line outside the buffer is empty")
    t.assert_equal(2, fresh.byte_count, "byte count includes the newline")

    # Insert: rows are [label, [lines, row, col, text], expected lines].
    t.table([
      ["insert within a line", [["xy"], 0, 1, "ab"], ["xaby"]],
      ["insert a newline", [["xy"], 0, 1, "\n"], ["x", "y"]],
      ["insert multi-line text", [["xy"], 0, 1, "1\n2\n3"], ["x1", "2", "3y"]],
      ["insert at line end", [["xy"], 0, 2, "z"], ["xyz"]],
      ["insert past line end clamps", [["xy"], 0, 9, "z"], ["xyz"]],
      ["insert empty text", [["xy"], 0, 1, ""], ["xy"]],
      ["insert on second line", [["a", "b"], 1, 0, "z"], ["a", "zb"]]
    ]) do |input|
      b = D::Buffer.new(lines: strings(input[0]), path: nil, line_ending: "\n")
      b.insert(pos(input[1].to_i, input[2].to_i), input[3].to_s)
      b.lines
    end

    b = D::Buffer.new(lines: ["xy"], path: nil, line_ending: "\n")
    b.insert(pos(0, 1), "a")
    t.assert_true(b.modified?, "insert marks the buffer modified")

    # Delete: rows are [label, [lines, r1, c1, r2, c2], expected lines].
    t.table([
      ["delete within a line", [["abcd"], 0, 1, 0, 3], ["ad"]],
      ["delete across lines", [["ab", "cd", "ef"], 0, 1, 2, 1], ["af"]],
      ["delete a line break", [["ab", "cd"], 0, 2, 1, 0], ["abcd"]],
      ["delete reversed range", [["abcd"], 0, 3, 0, 1], ["ad"]],
      ["delete nothing", [["abcd"], 0, 2, 0, 2], ["abcd"]],
      ["delete whole buffer", [["ab", "cd"], 0, 0, 1, 2], [""]]
    ]) do |input|
      b = D::Buffer.new(lines: strings(input[0]), path: nil, line_ending: "\n")
      b.delete(range(input[1].to_i, input[2].to_i, input[3].to_i, input[4].to_i))
      b.lines
    end

    inclusive = D::Range.new(from: pos(0, 1), to: pos(0, 2), kind: :charwise, inclusive: true)
    b = D::Buffer.new(lines: ["abcd"], path: nil, line_ending: "\n")
    b.delete(inclusive)
    t.assert_equal(["ad"], b.lines, "inclusive range deletes its end character")

    # Replace.
    b = D::Buffer.new(lines: ["abcd"], path: nil, line_ending: "\n")
    b.replace(range(0, 1, 0, 3), "XYZ")
    t.assert_equal(["aXYZd"], b.lines, "replace within a line")
    b = D::Buffer.new(lines: ["ab", "cd"], path: nil, line_ending: "\n")
    b.replace(range(0, 1, 1, 1), "-\n-")
    t.assert_equal(["a-", "-d"], b.lines, "replace across lines")

    # Set lines: rows are [label, [lines, from, to, new lines], expected lines].
    t.table([
      ["replace two lines with one", [["a", "b", "c"], 0, 2, ["z"]], ["z", "c"]],
      ["insert lines without removing", [["a", "b"], 1, 1, ["x", "y"]], ["a", "x", "y", "b"]],
      ["remove every line leaves one", [["a", "b"], 0, 2, []], [""]],
      ["append at the end", [["a"], 1, 1, ["b"]], ["a", "b"]]
    ]) do |input|
      b = D::Buffer.new(lines: strings(input[0]), path: nil, line_ending: "\n")
      b.set_lines(input[1].to_i, input[2].to_i, strings(input[3]))
      b.lines
    end

    b = D::Buffer.new(lines: ["a", "b"], path: nil, line_ending: "\n")
    b.set_lines(0, 2, strings([]))
    t.assert_true(b.modified?, "set_lines marks the buffer modified")

    # Modified flag across load, edit, save.
    b = D::Buffer.from_text("one\n", "f.txt")
    t.assert_equal(false, b.modified?, "unmodified after load")
    b.insert(pos(0, 0), "x")
    t.assert_equal(true, b.modified?, "modified after insert")
    b.mark_saved
    t.assert_equal(false, b.modified?, "unmodified after save")

    # Data semantics the domain relies on: value equality, hashing, immutability.
    p1 = pos(2, 3)
    p2 = pos(2, 3)
    t.assert_true(p1 == p2, "positions are equal by value")
    t.assert_true(p1.eql?(p2), "positions are eql by value")
    t.assert_equal(p1.hash, p2.hash, "equal positions hash alike")
    t.assert_equal("here", { p1 => "here" }[p2], "a position works as a hash key by value")
    t.assert_true(p1.frozen?, "positions are frozen")
    t.assert_equal([2, 4], p1.with(col: 4).to_a, "with copies a position")
    t.assert_equal([2, 3], p1.to_a, "with leaves the original unchanged")
    r1 = D::Range.charwise(pos(0, 0), pos(0, 2))
    r2 = D::Range.new(from: pos(0, 0), to: pos(0, 2), kind: :charwise, inclusive: false)
    t.assert_true(r1 == r2, "ranges are equal by value")
    t.assert_true(r1.frozen?, "ranges are frozen")

    # Struct semantics the mutable records rely on: keyword construction,
    # readers and writers, members, and the constructor defaults.
    c = D::Cursor.new(row: 2, col: 3)
    t.assert_equal([true, true, true, true], [D::Cursor.keyword_init? == true, D::Buffer.keyword_init? == true, D::Cell.keyword_init? == true, D::Window.keyword_init? == true], "struct records are built with keywords")
    t.assert_equal([2, 3, 3], [c.row, c.col, c.want_col], "a cursor starts wanting its column")
    c.col = 5
    t.assert_equal(5, c.col, "a cursor member has a writer")
    c.move_to(4, 1)
    t.assert_equal([4, 1], c.to_a, "to_a is the position pair without want_col")
    t.assert_equal([:row, :col, :want_col], D::Cursor.members, "cursor members in constructor order")
    t.assert_equal(false, c.frozen?, "records are not frozen")
    w = D::Window.new(buffer: D::Buffer.from_text("ab\n", "w.txt"))
    t.assert_equal([0, 0, 0, "w.txt", [0, 0], false], [w.top, w.left, w.height, w.buffer.path, w.cursor.to_a, w.fixed_width], "a window starts at the origin with no height, showing its buffer from the start")
    w.top = 7
    t.assert_equal(7, w.top, "a window member has a writer")
    t.assert_equal([:lines, :path, :line_ending, :saved_change, :owner, :title, :keymap, :sign_layers, :changes, :id, :transaction, :last_transaction, :closed_count, :feed, :undo, :filetype, :syntax, :syntax_cache, :global_marks, :last_cursor, :icon, :diagnostics, :diagnostic_marks, :styles], D::Buffer.members, "buffer members in constructor order")
    t.assert_equal([:code, :width, :hl], D::Cell.members, "cell members")
    o = D::Options.new
    t.assert_equal([false, 8, 0], [o.number, o.tabstop, o.scrolloff], "options start with Vim's defaults")

    t.table([
      ["text of a range on one line", [["abcdef"], rng(0, 1, 0, 4, false)], "bcd"],
      ["text of an inclusive range", [["abcdef"], rng(0, 1, 0, 4, true)], "bcde"],
      ["text of a backward range", [["abcdef"], rng(0, 4, 0, 1, false)], "bcd"],
      ["text of a range over lines", [["ab", "cd", "ef"], rng(0, 1, 2, 1, false)], "b\ncd\ne"],
      ["text of a range to a line end", [["ab", "cd"], rng(0, 1, 0, 2, false)], "b"],
      ["text of an empty range", [["ab"], rng(0, 1, 0, 1, false)], ""]
    ]) do |input|
      D::Buffer.new(lines: strings(input[0]), path: nil, line_ending: "\n").text_of(input[1])
    end
    b = D::Buffer.new(lines: ["  ab", "cd", "", "\tef"], path: nil, line_ending: "\n")
    t.assert_equal(["cd", ""], b.lines_of(1, 2), "lines_of copies the rows")
    copy = b.lines_of(0, 0)
    copy << "x"
    t.assert_equal(4, b.line_count, "lines_of does not share the array")
    t.assert_equal([2, 0, 0, 1], [b.first_nonblank(0), b.first_nonblank(1), b.first_nonblank(2), b.first_nonblank(3)], "first_nonblank per row")
    t.assert_equal(["  ", "", "", "\t"], [b.indent_of(0), b.indent_of(1), b.indent_of(2), b.indent_of(3)], "indent_of per row")
    t.assert_equal("", b.line(9), "a row outside the buffer reads as empty")

    # Scratch members, signs, and the change counter.
    b = D::Buffer.new(lines: ["ab"], path: nil, line_ending: "\n")
    t.assert_equal([false, "", "", true, nil, 0], [b.scratch?, b.owner, b.title, b.keymap.nil?, b.display_name, b.changes], "a file buffer has no owner, title, keymap, or changes")
    b.insert(D::Position.new(row: 0, col: 1), "x")
    b.delete(rng(0, 0, 0, 1, false))
    b.set_lines(0, 1, ["y"])
    t.assert_equal(3, b.changes, "every primitive counts one change")
    b.reload(["z"])
    t.assert_equal([4, false], [b.changes, b.modified?], "reload counts one change and leaves the buffer unmodified")
    b.owner = "hello"
    b.title = "list"
    t.assert_equal([true, "list"], [b.scratch?, b.display_name], "a scratch buffer is named by its title")
    named = D::Buffer.new(lines: ["ab"], path: "a.txt", line_ending: "\n")
    t.assert_equal("a.txt", named.display_name, "a file buffer is named by its path")
    t.assert_equal(false, b.signs?, "no signs at first")
    b.place_sign("hello", 0, 0, "X")
    t.assert_equal([true, "X", ""], [b.signs?, b.sign_at(0), b.sign_at(1)], "a sign is placed on its row")

    # Diagnostics: the most severe per row, drawn over a plugin's sign.
    d = D::Buffer.new(lines: ["a", "b", "c"], path: "a.rb", line_ending: "\n")
    d.place_sign("git", 0, 1, "+")
    d.place_sign("git", 0, 2, "+")
    glyphs = ["E", "W", "I", "H"]
    list = listed([diag(1, 4, "hint"), diag(1, 2, "warn"), diag(0, 1, "err"), diag(1, 2, "later"), diag(9, 1, "past the end")])
    d.set_diagnostics(list, glyphs)
    t.assert_equal(["E", "W", "+"], [d.sign_at(0), d.sign_at(1), d.sign_at(2)], "a row shows its most severe diagnostic over a plugin's sign")
    t.assert_equal(["err", "warn", true, 5], [d.diagnostic_at(0).message, d.diagnostic_at(1).message, d.diagnostic_at(2).nil?, d.diagnostics.count], "a row's diagnostic is the first of the most severe, one past the end is kept unmarked")
    t.assert_equal([true, true], [d.diagnostic_at(-1).nil?, d.diagnostic_at(9).nil?], "no diagnostic outside the buffer")
    d.set_lines(0, 0, ["new"])
    t.assert_equal(["", "E", "W", "warn"], [d.sign_at(0), d.sign_at(1), d.sign_at(2), d.diagnostic_at(2).message], "an inserted line moves the signs and the messages down")
    d.set_lines(0, 1, strings([]))
    t.assert_equal(["E", "err"], [d.sign_at(0), d.diagnostic_at(0).message], "a deleted line moves them up")
    d.set_diagnostics(listed([diag(2, 3, "info")]), glyphs)
    t.assert_equal(["", "+", "I", true], [d.sign_at(0), d.sign_at(1), d.sign_at(2), d.diagnostic_at(0).nil?], "a later list replaces the earlier one")
    d.set_diagnostics(D::DiagnosticList.new, glyphs)
    t.assert_equal(["+", true, 0], [d.sign_at(2), d.diagnostic_at(2).nil?, d.diagnostic_marks.length], "an empty list clears the diagnostics and keeps the plugin's signs")
    d.set_diagnostics(listed([diag(0, 1, "x")]), glyphs)
    d.clear_diagnostics
    t.assert_equal(["", true], [d.sign_at(0), d.diagnostic_at(0).nil?], "clearing removes the signs and the messages")

    t.finish
  end
end

DomainBufferTest.main if __FILE__ == $0
