require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorBuffersTest
  A1 = "  1 %a   \"a.txt\"                        line 1"
  E37 = "E37: No write since last change (add ! to override)"

  # A 24 by 80 editor on "a.txt" (three lines) with "b.txt" and "c.txt"
  # on disk, after typing keys.
  def self.session(keys)
    h = Carat::Doubles::EditorHarness.default(disk, 24, 80)
    h.open("a.txt")
    h.type(keys.to_s)
    h
  end

  # "a.txt" (three lines), "b.txt", and "c.txt".
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    files.put("b.txt", "zz\n")
    files.put("c.txt", "c1\nc2\n")
    files
  end

  # The session under option.gt tabpages, where the top row shows tab
  # pages and :q and :bd keep Neovim's window rules.
  def self.tabpages(keys)
    h = Carat::Doubles::EditorHarness.new(files: disk, config: Carat::Doubles::FixedConfig.with("option.gt tabpages\n"), rows: 24, cols: 80, plugins: [])
    h.open("a.txt")
    h.type(keys.to_s)
    h
  end

  # The path the current window shows, "" for an unnamed buffer.
  def self.path(h)
    current = h.buffer.path
    current.nil? ? "" : current
  end

  # E37 and E162 naming the buffer, as quitting over its changes shows.
  def self.unsaved(name)
    "E37: No write since last change\nE162: No write since last change for buffer \"#{name}\""
  end

  def self.main
    t = Carat::Testing.new("editor_buffers")

    # :ls and its spellings, flags, and filters: rows are [label, keys, message].
    # Scenarios "Hidden and modified buffers" (modified buffers carry +)
    # and "Filtered by a flag" (h keeps the hidden buffers); the = flag
    # and filter are in adapters_definitions, over a gd target.
    t.table([
      ["one buffer", ":ls<CR>", A1],
      [":buffers lists the same", ":buffers<CR>", A1],
      [":files lists the same", ":files<CR>", A1],
      ["the buffer left stays listed, hidden, with its line", "jj:e b.txt<CR>:ls<CR>", "  1  h   \"a.txt\"                        line 3\n  2 %a   \"b.txt\"                        line 1"],
      ["modified buffers carry +", "x:sp b.txt<CR>x<C-w>c:ls<CR>", "  1 %a + \"a.txt\"                        line 1\n  2  h + \"b.txt\"                        line 1"],
      ["a buffer another window shows is active", ":new<CR>:ls<CR>", "  1  a   \"a.txt\"                        line 1\n  2 %a   \"[No Name]\"                    line 1"],
      ["the current line of the current buffer", "jj:ls<CR>", "  1 %a   \"a.txt\"                        line 3"],
      ["h keeps the hidden buffers", ":sp b.txt<CR><C-w>c:ls h<CR>", "  2  h   \"b.txt\"                        line 1"],
      ["a keeps the active buffers", ":sp b.txt<CR><C-w>c:ls a<CR>", A1],
      ["% keeps the current buffer", ":sp b.txt<CR><C-w>c:ls %<CR>", A1],
      ["+ keeps the modified buffers", ":sp b.txt<CR>x<C-w>c:ls +<CR>", "  2  h + \"b.txt\"                        line 1"],
      ["flags combine", ":sp b.txt<CR><C-w>c:ls ah<CR>", ""],
      ["# keeps none, as no buffer is alternate", ":ls #<CR>", ""],
      ["- keeps none", ":ls -<CR>", ""],
      ["u keeps only scratch buffers", ":ls u<CR>", ""],
      ["other characters are ignored", ":ls t<CR>", A1],
      ["a long name is followed by one space", ":e dddddddddddddddddddddddddddddddddddddddd.txt<CR>:bd 1<CR>:ls<CR>", "  2 %a   \"dddddddddddddddddddddddddddddddddddddddd.txt\" line 1"]
    ]) do |keys|
      session(keys).message
    end
    # Scenario "Tab edit a listed file leaves no empty buffer".
    h = session(":e b.txt<CR>:tabe a.txt<CR>")
    t.assert_equal([2, 2, "a.txt", ["a.txt", "b.txt"], false], [h.tab_count, h.tab_index, h.buffer.path.to_s, h.buffer_paths, h.row(0).include?("[No Name]")], "Tab edit a listed file leaves no empty buffer: the row lists a.txt and b.txt only")
    h.type(":ls<CR>")
    t.assert_equal(false, h.message.include?("No Name"), "and :ls lists no empty buffer")
    h = session(":tabe<CR>")
    t.assert_equal([2, ["a.txt", ""]], [h.tab_count, h.buffer_paths], ":tabe with no name keeps opening an empty buffer")

    # Scratch buffers show only with the bang or u.
    # Scenario "Scratch buffers with the bang".
    h = session("")
    scratch = Carat::Domain::Buffer.new(lines: ["l"], path: nil, line_ending: "\n")
    scratch.owner = "hello"
    scratch.title = "list"
    h.assembly.buffers.add(scratch)
    h.type(":ls<CR>")
    t.assert_equal(A1, h.message, "a scratch buffer is left out")
    h.type(":ls!<CR>")
    t.assert_equal(A1 + "\n  2u h   \"list\"                         line 1", h.message, ":ls! lists it, flagged u, by its title")
    h.type(":ls u<CR>")
    t.assert_equal("  2u h   \"list\"                         line 1", h.message, ":ls u lists only it")
    h.type(":bn<CR>")
    t.assert_equal("a.txt", path(h), ":bn skips it")
    h.type(":b 2<CR>")
    t.assert_equal(["a.txt", "E86: Buffer 2 does not exist"], [path(h), h.message], ":b N does not show it")
    h.type(":bd 2<CR>")
    t.assert_equal("E516: No buffers were deleted: bd 2", h.message, ":bd N does not delete it")

    # Moving through the list: rows are [label, keys, [path, cursor, message]].
    t.table([
      [":bn wraps to the first buffer", ":e b.txt<CR>:e c.txt<CR>:bn<CR>", ["a.txt", [0, 0], ""]],
      [":bp goes back", ":e b.txt<CR>:e c.txt<CR>:bp<CR>", ["b.txt", [0, 0], ""]],
      [":bp wraps to the last buffer", ":e b.txt<CR>:e c.txt<CR>:b 1<CR>:bp<CR>", ["c.txt", [0, 0], ""]],
      [":bN goes back", ":e b.txt<CR>:bN<CR>", ["a.txt", [0, 0], ""]],
      [":bnext", ":e b.txt<CR>:e c.txt<CR>:bnext<CR>", ["a.txt", [0, 0], ""]],
      [":bprevious", ":e b.txt<CR>:bprevious<CR>", ["a.txt", [0, 0], ""]],
      [":bNext", ":e b.txt<CR>:bNext<CR>", ["a.txt", [0, 0], ""]],
      [":bn with a count", ":e b.txt<CR>:e c.txt<CR>:b 1<CR>:bn 2<CR>", ["c.txt", [0, 0], ""]],
      [":bp with a count wraps", ":e b.txt<CR>:e c.txt<CR>:b 1<CR>:bp 2<CR>", ["b.txt", [0, 0], ""]],
      [":bn with a count past the end wraps around", ":e b.txt<CR>:e c.txt<CR>:b 1<CR>:bn 7<CR>", ["b.txt", [0, 0], ""]],
      [":bn 0 stays", ":e b.txt<CR>:bn 0<CR>", ["b.txt", [0, 0], ""]],
      [":bn with a huge count does not hang", ":e b.txt<CR>:bn 99999999999999999999<CR>", ["a.txt", [0, 0], ""]],
      [":bn with one buffer stays", ":bn<CR>", ["a.txt", [0, 0], ""]],
      [":bn with a word", ":bn x<CR>", ["a.txt", [0, 0], "E488: Trailing characters: x"]],
      [":b N shows the buffer", ":e b.txt<CR>:b 1<CR>", ["a.txt", [0, 0], ""]],
      [":buffer N", ":e b.txt<CR>:buffer 1<CR>", ["a.txt", [0, 0], ""]],
      [":b of the current buffer stays", ":b 1<CR>", ["a.txt", [0, 0], ""]],
      [":b alone stays", ":e b.txt<CR>:b<CR>", ["b.txt", [0, 0], ""]],
      [":b of no buffer", ":b 9<CR>", ["a.txt", [0, 0], "E86: Buffer 9 does not exist"]],
      [":b 0 names no buffer", ":b 0<CR>", ["a.txt", [0, 0], "E86: Buffer 0 does not exist"]],
      [":b with a name", ":b b.txt<CR>", ["a.txt", [0, 0], "Not implemented: :buffer b.txt"]],
      ["the cursor comes back", "jjl:e b.txt<CR>:b 1<CR>", ["a.txt", [2, 1], ""]],
      ["the cursor comes back through :e", "jj:e b.txt<CR>:e a.txt<CR>", ["a.txt", [2, 0], "\"a.txt\" 3L, 14B"]],
      ["the cursor comes back after :only", ":sp b.txt<CR><C-w>jjj<C-w>k:only<CR>:b 1<CR>", ["a.txt", [2, 0], ""]],
      ["a modified buffer refuses", ":set nohidden<CR>:e b.txt<CR>:b 1<CR>x:bn<CR>", ["a.txt", [0, 0], E37]],
      ["the bang keeps it hidden", ":e b.txt<CR>:b 1<CR>x:bn!<CR>", ["b.txt", [0, 0], ""]],
      ["a count before the command is refused", ":e b.txt<CR>:2bn<CR>", ["b.txt", [0, 0], "E481: No range allowed"]],
      # Scenarios "First and last", "Rewind is first", and "First
      # refused on a modified buffer".
      ["First and last: :bfirst shows the first buffer", ":e b.txt<CR>:e c.txt<CR>:b 2<CR>:bfirst<CR>", ["a.txt", [0, 0], ""]],
      ["First and last: :blast then shows the last", ":e b.txt<CR>:e c.txt<CR>:b 2<CR>:bfirst<CR>:blast<CR>", ["c.txt", [0, 0], ""]],
      [":bf and :bl", ":e b.txt<CR>:bf<CR>:bl<CR>", ["b.txt", [0, 0], ""]],
      ["Rewind is first", ":e b.txt<CR>:br<CR>", ["a.txt", [0, 0], ""]],
      [":brewind", ":e b.txt<CR>:brewind<CR>", ["a.txt", [0, 0], ""]],
      [":bfirst of the first buffer stays", ":e b.txt<CR>:b 1<CR>:bfirst<CR>", ["a.txt", [0, 0], ""]],
      ["First refused on a modified buffer", ":set nohidden<CR>:e b.txt<CR>x:bfirst<CR>", ["b.txt", [0, 0], E37]],
      [":bfirst! keeps it hidden", ":e b.txt<CR>x:bfirst!<CR>", ["a.txt", [0, 0], ""]],
      [":blast with a number", ":blast 2<CR>", ["a.txt", [0, 0], "E488: Trailing characters: 2"]]
    ]) do |keys|
      h = session(keys)
      [path(h), h.cursor, h.message]
    end
    h = session(":e b.txt<CR>:b 1<CR>x:bn!<CR>:ls<CR>")
    t.assert_equal("  1  h + \"a.txt\"                        line 1\n  2 %a   \"b.txt\"                        line 1", h.message, "the buffer left with the bang is hidden and modified")
    h.type(":b 1<CR>")
    t.assert_equal([["ne", "two", "three"], true], [h.lines, h.buffer.modified?], "its changes come back with it")

    # The hidden option over a modified buffer: rows are [label, keys,
    # [path, message]], each switch with option.hidden on, the default,
    # and off. Scenarios "A modified buffer is left hidden under hidden"
    # (buffer-list), "First and last leave a modified buffer hidden"
    # (buffer-list), and "Edit leaves a modified buffer hidden under
    # hidden" (command-line-mode), and "Set hidden changes the next
    # switch" (set-command).
    off = ":set nohidden<CR>"
    t.table([
      ["A modified buffer is left hidden under hidden: :e", "x:e b.txt<CR>", ["b.txt", "\"b.txt\" 1L, 3B"]],
      ["A modified buffer is left hidden under hidden: :b N", ":e b.txt<CR>x:b 1<CR>", ["a.txt", ""]],
      ["A modified buffer is left hidden under hidden: :bn", ":e b.txt<CR>:b 1<CR>x:bn<CR>", ["b.txt", ""]],
      ["A modified buffer is left hidden under hidden: :bp", ":e b.txt<CR>x:bp<CR>", ["a.txt", ""]],
      ["A modified buffer is left hidden under hidden: :bN", ":e b.txt<CR>x:bN<CR>", ["a.txt", ""]],
      ["First and last leave a modified buffer hidden: :bfirst", ":e b.txt<CR>x:bfirst<CR>", ["a.txt", ""]],
      ["First and last leave a modified buffer hidden: :blast", ":e b.txt<CR>:b 1<CR>x:blast<CR>", ["b.txt", ""]],
      ["Edit leaves a modified buffer hidden under hidden: :e of the current file stays refused", "x:e<CR>", ["a.txt", E37]],
      ["Edit leaves a modified buffer hidden under hidden: :e! discards", "x:e!<CR>", ["a.txt", "\"a.txt\" 3L, 14B"]],
      ["A modified buffer is refused with hidden off: :e", off + "x:e b.txt<CR>", ["a.txt", E37]],
      ["A modified buffer is refused with hidden off: :b N", off + ":e b.txt<CR>x:b 1<CR>", ["b.txt", E37]],
      ["A modified buffer is refused with hidden off: :bn", off + ":e b.txt<CR>:b 1<CR>x:bn<CR>", ["a.txt", E37]],
      ["A modified buffer is refused with hidden off: :bp", off + ":e b.txt<CR>x:bp<CR>", ["b.txt", E37]],
      ["A modified buffer is refused with hidden off: :bN", off + ":e b.txt<CR>x:bN<CR>", ["b.txt", E37]],
      ["A modified buffer is refused with hidden off: :bfirst", off + ":e b.txt<CR>x:bfirst<CR>", ["b.txt", E37]],
      ["A modified buffer is refused with hidden off: :blast", off + ":e b.txt<CR>:b 1<CR>x:blast<CR>", ["a.txt", E37]],
      ["Set hidden changes the next switch: off, then on again", off + ":set hid<CR>x:e b.txt<CR>", ["b.txt", "\"b.txt\" 1L, 3B"]]
    ]) do |keys|
      h = session(keys)
      [path(h), h.message]
    end
    h = session(off + ":e b.txt<CR>:b 1<CR>x:bn<CR>")
    t.assert_equal(["a.txt", E37], [path(h), h.message], "Set hidden changes the next switch: the first :bn is refused")
    h.type(":set hid<CR>:bn<CR>")
    t.assert_equal(["b.txt", ""], [path(h), h.message], "Set hidden changes the next switch: the second :bn shows b.txt")
    h = session("x:e b.txt<CR>:ls<CR>")
    t.assert_equal("  1  h + \"a.txt\"                        line 1\n  2 %a   \"b.txt\"                        line 1", h.message, "the buffer left under hidden is hidden and modified")
    h = session("x:e b.txt<CR>")
    t.assert_equal("b.txt", path(h), "A modified hidden buffer is named by :qa under hidden: the window shows b.txt first")
    h.type(":qa<CR>")
    t.assert_equal([false, unsaved("a.txt"), "a.txt"], [h.quit?, h.message, path(h)], "A modified hidden buffer is named by :qa under hidden")

    # Deleting: rows are [label, keys, [listed paths, path, windows, tab pages, message]].
    # Under option.gt buffers no window closes. Scenarios:
    # "Delete the current buffer", "Delete the last buffer",
    # "Delete a hidden buffer by number",
    # "Delete keeps the windows showing the buffer",
    # "Delete in a split keeps the window".
    t.table([
      [":bd shows the next buffer", ":e b.txt<CR>:b 1<CR>:bd<CR>", [["b.txt"], "b.txt", 1, 1, ""]],
      [":bd of the last in the list shows the one before", ":e b.txt<CR>:bd<CR>", [["a.txt"], "a.txt", 1, 1, ""]],
      [":bdelete", ":e b.txt<CR>:bdelete<CR>", [["a.txt"], "a.txt", 1, 1, ""]],
      [":bd of the only buffer shows a new empty one", ":bd<CR>", [[""], "", 1, 1, ""]],
      [":bd N of a hidden buffer", ":e b.txt<CR>:bd 1<CR>", [["b.txt"], "b.txt", 1, 1, ""]],
      [":bd N keeps the windows showing it", ":sp b.txt<CR><C-w>j:bd 2<CR>", [["a.txt"], "a.txt", 2, 1, ""]],
      [":bd in a split keeps the window", ":sp b.txt<CR>:bd<CR>", [["a.txt"], "a.txt", 2, 1, ""]],
      [":bd of a buffer two windows show keeps both", ":sp b.txt<CR>:sp<CR>:bd<CR>", [["a.txt"], "a.txt", 3, 1, ""]],
      [":bd of the only buffer in a split shows an empty one in both", ":sp<CR>:bd<CR>", [[""], "", 2, 1, ""]],
      [":bd keeps a tab page", ":tabe b.txt<CR>:bd<CR>", [["a.txt"], "a.txt", 1, 2, ""]],
      [":bd N keeps another tab page showing it", ":tabe b.txt<CR>:tabfir<CR>:bd 2<CR>", [["a.txt"], "a.txt", 1, 2, ""]],
      [":bd shows the replacement in every window showing it", ":sp b.txt<CR><C-w>j:bd 2<CR><C-w>k", [["a.txt"], "a.txt", 2, 1, ""]],
      [":bd of a modified buffer is refused", "x:bd<CR>", [["a.txt"], "a.txt", 1, 1, "E89: No write since last change for buffer 1 (add ! to override)"]],
      [":bd! discards the changes", "x:bd!<CR>", [[""], "", 1, 1, ""]],
      [":bd N of no buffer", ":bd 9<CR>", [["a.txt"], "a.txt", 1, 1, "E516: No buffers were deleted: bd 9"]],
      [":bdelete! N of no buffer names the command as typed", ":bdelete! 9<CR>", [["a.txt"], "a.txt", 1, 1, "E516: No buffers were deleted: bdelete! 9"]],
      [":bd with a name", ":bd a.txt<CR>", [["a.txt"], "a.txt", 1, 1, "Not implemented: :bdelete a.txt"]]
    ]) do |keys|
      h = session(keys)
      [h.buffer_paths, path(h), h.window_count, h.tab_count, h.message]
    end
    # Under option.gt tabpages the windows close as in Neovim. Scenarios:
    # "Delete closes the windows showing the buffer",
    # "Delete in a split closes the window".
    t.table([
      [":bd N closes the windows showing it", ":sp b.txt<CR><C-w>j:bd 2<CR>", [["a.txt"], "a.txt", 1, 1, ""]],
      [":bd in a split closes the window", ":sp b.txt<CR>:bd<CR>", [["a.txt"], "a.txt", 1, 1, ""]],
      [":bd of a buffer two windows show closes both but the last", ":sp b.txt<CR>:sp<CR>:bd<CR>", [["a.txt"], "a.txt", 1, 1, ""]],
      [":bd of the only buffer in a split leaves one empty window", ":sp<CR>:bd<CR>", [[""], "", 1, 1, ""]],
      [":bd closes a tab page with its last window", ":tabe b.txt<CR>:bd<CR>", [["a.txt"], "a.txt", 1, 1, ""]],
      [":bd N closes another tab page showing it", ":tabe b.txt<CR>:tabfir<CR>:bd 2<CR>", [["a.txt"], "a.txt", 1, 1, ""]]
    ]) do |keys|
      h = tabpages(keys)
      [h.buffer_paths, path(h), h.window_count, h.tab_count, h.message]
    end
    h = session(":bd<CR>")
    t.assert_equal(2, h.buffer.id, "the new empty buffer gets a new number")
    h.type(":e b.txt<CR>:ls<CR>")
    t.assert_equal("  2 %a   \"b.txt\"                        line 1", h.message, "a file opened over it takes that number")
    h = session("jj:e b.txt<CR>:bd<CR>")
    t.assert_equal(["a.txt", [2, 0]], [path(h), h.cursor], "the buffer shown in place of the deleted one gets its cursor back")
    h = session(":e b.txt<CR>:bd 1<CR>:e a.txt<CR>")
    t.assert_equal(3, h.buffer.id, "a file opened again after :bd gets a new number")
    h = session(":e b.txt<CR>:new<CR>ix<Esc>:bd 1<CR>:wa<CR>")
    t.assert_equal("E141: No file name for buffer 3", h.message, "E141 names the buffer number, which does not shift when a buffer leaves")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\n")
    h = Carat::Doubles::EditorHarness.default(files, 24, 80)
    h.type(":e a.txt<CR>:ls<CR>")
    t.assert_equal(A1, h.message, "a file opened over the empty startup buffer is buffer 1")

    # Quitting over unsaved changes names the buffer and goes to it: rows
    # are [label, keys, [message, quit, path, tab page]].
    t.table([
      [":qa names the current buffer", "x:qa<CR>", [unsaved("a.txt"), false, "a.txt", 1]],
      [":qa shows a hidden buffer", ":sp b.txt<CR>x<C-w>c:qa<CR>", [unsaved("b.txt"), false, "b.txt", 1]],
      [":qa goes to the tab page showing it", ":tabe b.txt<CR>x:tabfir<CR>:qa<CR>", [unsaved("b.txt"), false, "b.txt", 2]],
      [":qa goes to the window showing it", ":sp b.txt<CR>x<C-w>j:qa<CR>", [unsaved("b.txt"), false, "b.txt", 1]],
      [":qa prefers the current buffer", ":sp b.txt<CR>x<C-w>jx:qa<CR>", [unsaved("a.txt"), false, "a.txt", 1]],
      [":qa names an unnamed buffer", ":new<CR>ix<Esc>:q!<CR>:qa<CR>", [unsaved("[No Name]"), false, "", 1]],
      [":qa! ends the editor", "x:qa!<CR>", ["", true, "a.txt", 1]],
      [":q on a modified current buffer keeps one line", "x:q<CR>", [E37, false, "a.txt", 1]],
      [":q! twice ends the editor", ":sp b.txt<CR>x<C-w>c:q!<CR>:q!<CR>", ["", true, "b.txt", 1]],
      [":q closes the buffer tab and a modified hidden buffer is shown", ":sp b.txt<CR>x<C-w>c:q<CR>", ["", false, "b.txt", 1]]
    ]) do |keys|
      h = session(keys)
      [h.message, h.quit?, path(h), h.tab_index]
    end
    # Under option.gt tabpages the quit rule is Neovim's. Scenarios:
    # "Quit refused by a hidden buffer",
    # "Forced quit shows the hidden buffer",
    # "Under tab pages quit on the last window ends the editor".
    t.table([
      [":q names a hidden buffer", ":sp b.txt<CR>x<C-w>c:q<CR>", [unsaved("b.txt"), false, "b.txt", 1]],
      [":q! names a hidden buffer", ":sp b.txt<CR>x<C-w>c:q!<CR>", [unsaved("b.txt"), false, "b.txt", 1]],
      [":x names a hidden buffer", ":sp b.txt<CR>x<C-w>c:x<CR>", [unsaved("b.txt"), false, "b.txt", 1]],
      [":wq names a hidden buffer", ":sp b.txt<CR>x<C-w>c:wq<CR>", [unsaved("b.txt"), false, "b.txt", 1]],
      ["Under tab pages quit on the last window ends the editor", ":e b.txt<CR>:b 1<CR>:q<CR>", ["", true, "a.txt", 1]],
      ["under tab pages :q closes one of two windows as before", ":sp b.txt<CR>:q<CR>", ["", false, "a.txt", 1]]
    ]) do |keys|
      h = tabpages(keys)
      [h.message, h.quit?, path(h), h.tab_index]
    end

    # :q on the last window closes the buffer tab while another listed
    # file buffer exists: rows are [label, keys, [message, quit, path,
    # listed paths]]. Scenarios "Quit closes the buffer tab and shows the
    # next", "Quit on the last listed buffer ends the editor", "Quit on a
    # modified buffer with others listed is refused", and "Forced quit
    # closes the buffer tab discarding its changes"; with these, proved
    # above, in test/use_cases_ex.rb, and in test/editor_windows.rb:
    # "Quit a clean buffer",
    # "Quit refused", "Forced quit", "Quit one of two windows",
    # "Quit the last window showing a modified buffer".
    t.table([
      ["Quit closes the buffer tab and shows the next", ":e b.txt<CR>:b 1<CR>:q<CR>", ["", false, "b.txt", ["b.txt"]]],
      ["the last in the list shows the one before", ":e b.txt<CR>:q<CR>", ["", false, "a.txt", ["a.txt"]]],
      ["Quit on the last listed buffer ends the editor", ":e b.txt<CR>:q<CR>:q<CR>", ["", true, "a.txt", ["a.txt"]]],
      ["Quit on a modified buffer with others listed is refused", ":e b.txt<CR>:b 1<CR>x:q<CR>", [E37, false, "a.txt", ["a.txt", "b.txt"]]],
      ["Forced quit closes the buffer tab discarding its changes", ":e b.txt<CR>:b 1<CR>x:q!<CR>", ["", false, "b.txt", ["b.txt"]]],
      [":wq closes the buffer tab after its write", ":e b.txt<CR>:b 1<CR>x:wq<CR>", ["", false, "b.txt", ["b.txt"]]],
      [":x closes the buffer tab after its write", ":e b.txt<CR>:b 1<CR>x:x<CR>", ["", false, "b.txt", ["b.txt"]]],
      ["Ctrl-W q on the last window closes the buffer tab", ":e b.txt<CR>:b 1<CR><C-w>q", ["", false, "b.txt", ["b.txt"]]],
      [":q in a split closes only the window", ":sp b.txt<CR>:q<CR>", ["", false, "a.txt", ["a.txt", "b.txt"]]]
    ]) do |keys|
      h = session(keys)
      [h.message, h.quit?, path(h), h.buffer_paths]
    end
    h = session(":e b.txt<CR>:b 1<CR>x:wq<CR>")
    t.assert_equal("ne\ntwo\nthree\n", h.files.read("a.txt", 100), ":wq wrote the buffer before closing its tab")
    h = session(":sp b.txt<CR>x<C-w>cx:q!<CR>")
    t.assert_equal([["b.txt"], "b.txt", false], [h.buffer_paths, path(h), h.quit?], ":q! over a hidden buffer discards the current buffer's changes")

    # A newline in a file name is ^J, so the name adds no line to either
    # message. Scenarios "A newline in a name in the listing" and "A
    # newline in a name in E162".
    files = Carat::Doubles::MemoryFiles.new
    files.put("x\ny.txt", "one\n")
    h = Carat::Doubles::EditorHarness.default(files, 24, 80)
    h.open("x\ny.txt")
    h.type(":ls<CR>")
    t.assert_equal("  1 %a   \"x^Jy.txt\"" + " " * 21 + "line 1", h.message, "A newline in a name in the listing: :ls shows it as ^J on one line")
    h.type("x:qa<CR>")
    t.assert_equal([unsaved("x^Jy.txt"), false], [h.message, h.quit?], "A newline in a name in E162: :qa names it with ^J")
    t.assert_equal("a^Ib^?c^@", Carat::Domain::ControlText.caret("a\tb\x7Fc\x00"), "a tab, DEL, and NUL in caret notation")
    t.assert_equal("ä.txt", Carat::Domain::ControlText.caret("ä.txt"), "a UTF-8 name is kept")

    t.finish
  end
end

EditorBuffersTest.main if __FILE__ == $0
