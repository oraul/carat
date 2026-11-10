require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorLeaderTest
  # A 24 by 80 editor with the shipped defaults on "a.txt" (three lines),
  # with "b.txt" and "c.txt" on disk, after typing keys, with no winbar as in
  # Neovim (test/editor_breadcrumbs.rb covers the winbars).
  def self.session(keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    files.put("b.txt", "zz\n")
    files.put("c.txt", "cc\n")
    h = Carat::Doubles::EditorHarness.default(files, 24, 80)
    h.state.options.breadcrumbs = "never"
    h.open("a.txt")
    h.type(keys.to_s)
    h
  end

  # The path the current window shows, "" for an unnamed buffer.
  def self.path(h)
    current = h.buffer.path
    current.nil? ? "" : current
  end

  # The text of a.txt on disk.
  def self.disk(h)
    text = h.files.get("a.txt")
    text.nil? ? "" : text
  end

  # Three files listed, a.txt current again.
  THREE = ":e b.txt<CR>:e c.txt<CR>:b 1<CR>"

  def self.main
    t = Carat::Testing.new("editor_leader")

    # The window group: rows are [label, keys, [windows, current, the
    # first window's text rows]].
    t.table([
      ["leader w s splits", "<Space>ws", [2, 1, 11]],
      ["a count before leader w s sets the new window's rows", "5<Space>ws", [2, 1, 5]],
      ["leader w v splits vertically", "<Space>wv", [2, 1, 22]],
      ["leader w j moves down", "<Space>ws<Space>wj", [2, 2, 11]],
      ["leader w k moves back up", "<Space>ws<Space>wj<Space>wk", [2, 1, 11]],
      ["leader w l moves right", "<Space>wv<Space>wl", [2, 2, 22]],
      ["leader w h moves back left", "<Space>wv<Space>wl<Space>wh", [2, 1, 22]],
      ["leader w c closes the window", "<Space>ws<Space>wc", [1, 1, 22]],
      ["leader w o keeps only the current window", "<Space>ws<Space>ws<Space>wo", [1, 1, 22]],
      ["leader w alone waits and changes nothing", "<Space>w", [1, 1, 22]]
    ]) do |keys|
      h = session(keys)
      h.wait
      [h.window_count, h.window_index, h.windows[0][2]]
    end

    # Saving: rows are [label, keys, [a.txt on disk, modified, mode,
    # cursor, message]].
    t.table([
      ["leader f s writes the file", "x<Space>fs", ["ne\ntwo\nthree\n", false, :normal, [0, 0], "\"a.txt\" 3L, 13B written"]],
      ["Ctrl-S writes the file in normal mode", "x<C-s>", ["ne\ntwo\nthree\n", false, :normal, [0, 0], "\"a.txt\" 3L, 13B written"]],
      ["Ctrl-S in insert mode writes and stays in insert mode", "iab<C-s>", ["abone\ntwo\nthree\n", false, :insert, [0, 2], "\"a.txt\" 3L, 16B written"]],
      ["typing after Ctrl-S in insert mode modifies the buffer again", "iab<C-s>c", ["abone\ntwo\nthree\n", true, :insert, [0, 3], ""]],
      ["leader w no longer writes", "x<Space>w<Esc>", ["one\ntwo\nthree\n", true, :normal, [0, 0], ""]]
    ]) do |keys|
      h = session(keys)
      [disk(h), h.buffer.modified?, h.mode, h.cursor, h.message]
    end
    h = session("x")
    h.raw("\x13")
    t.assert_equal(["ne\ntwo\nthree\n", false], [disk(h), h.buffer.modified?], "Ctrl-S as the raw byte 0x13 writes the file")
    h = session("iab<C-s><Esc>u")
    t.assert_equal(["one\ntwo\nthree\n", true], [h.lines.join("\n") + "\n", h.buffer.modified?], "undo after Ctrl-S in insert mode takes the insert back and the buffer differs from the file")

    # The quit group: rows are [label, keys, [quit, a.txt on disk]].
    t.table([
      ["leader q q quits", "<Space>qq", [true, "one\ntwo\nthree\n"]],
      ["leader q q is refused by unsaved work", "x<Space>qq", [false, "one\ntwo\nthree\n"]],
      ["leader q w writes and quits", "x<Space>qw", [true, "ne\ntwo\nthree\n"]],
      ["leader q alone does not quit", "<Space>q<Esc>", [false, "one\ntwo\nthree\n"]]
    ]) do |keys|
      h = session(keys)
      [h.quit?, disk(h)]
    end
    t.assert_equal(session("x:qa<CR>").message, session("x<Space>qq").message, "leader q q refused shows what :qa shows")

    # The buffer group: rows are [label, keys, [current path, listed
    # paths]].
    t.table([
      ["leader b n goes to the next buffer", THREE + "<Space>bn", ["b.txt", ["a.txt", "b.txt", "c.txt"]]],
      ["leader b p goes back", THREE + "<Space>bn<Space>bp", ["a.txt", ["a.txt", "b.txt", "c.txt"]]],
      ["leader b p wraps to the last buffer", THREE + "<Space>bp", ["c.txt", ["a.txt", "b.txt", "c.txt"]]],
      ["a count before leader b n steps that many", THREE + "2<Space>bn", ["c.txt", ["a.txt", "b.txt", "c.txt"]]],
      ["leader b d deletes the current buffer", ":e b.txt<CR><Space>bd", ["a.txt", ["a.txt"]]],
      ["a count before leader b d deletes that buffer", THREE + "3<Space>bd", ["a.txt", ["a.txt", "b.txt"]]],
      ["leader b d is refused by a change", ":e b.txt<CR>x<Space>bd", ["b.txt", ["a.txt", "b.txt"]]]
    ]) do |keys|
      h = session(keys)
      [path(h), h.buffer_paths]
    end
    t.assert_equal(session(":e b.txt<CR>x:bd<CR>").message, session(":e b.txt<CR>x<Space>bd").message, "leader b d refused shows what :bd shows")
    t.assert_equal("E516: No buffers were deleted: bdelete 9", session(THREE + "9<Space>bd").message, "leader b d with a count of no buffer shows E516")
    t.assert_equal(session(THREE + ":ls<CR>").message, session(THREE + "<Space>bb").message, "leader b b lists the buffers as :ls does")

    t.finish
  end
end

EditorLeaderTest.main if __FILE__ == $0
