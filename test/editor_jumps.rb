require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorJumpsTest
  # Three files of four lines on disk; the finder and the explorer list
  # them.
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/p")
    files.put("a.txt", "a1\na2\na3\na4\n")
    files.put("b.txt", "b1\nb2\nb3\nb4\n")
    files.put("c.txt", "c1\nc2\nc3\nc4\n")
    files
  end

  # A 24 by 80 editor over the shipped configuration and the registry's
  # plugins, before any file is opened.
  def self.editor
    config = Carat::Doubles::FixedConfig.with("option.icons ascii\n")
    Carat::Doubles::EditorHarness.new(files: disk, config: config, rows: 24, cols: 80, plugins: Carat::Plugins::Registry.all)
  end

  # The editor on a.txt after typing keys.
  def self.fresh(keys)
    h = editor
    h.open("a.txt")
    h.type(keys.to_s)
    h
  end

  # The editor on a.txt with b.txt and c.txt listed after it (buffers 1
  # to 3, a.txt current), after typing keys.
  def self.listed(keys)
    fresh(":e b.txt<CR>:e c.txt<CR>:b 1<CR>#{keys}")
  end

  # The path the current window shows and its cursor as "path row:col".
  def self.where(h)
    path = h.buffer.path
    "#{path.nil? ? "" : path} #{h.cursor[0]}:#{h.cursor[1]}"
  end

  def self.main
    t = Carat::Testing.new("editor_jumps")

    # Scenario "Every buffer switch records the position left": from
    # line 3 of a.txt each switch shows another buffer, then Ctrl-O
    # returns to line 3 and Ctrl-I to the buffer switched to. Rows are
    # [label, keys of the switch, "after Ctrl-O | after Ctrl-I"].
    t.table([
      [":e records the position left", ":e b.txt<CR>", "a.txt 2:0 | b.txt 0:0"],
      [":b N records the position left", ":b 3<CR>", "a.txt 2:0 | c.txt 0:0"],
      [":bn records the position left", ":bn<CR>", "a.txt 2:0 | b.txt 0:0"],
      [":bp records the position left", ":bp<CR>", "a.txt 2:0 | c.txt 0:0"],
      [":bN records the position left", ":bN<CR>", "a.txt 2:0 | c.txt 0:0"],
      [":blast records the position left", ":blast<CR>", "a.txt 2:0 | c.txt 0:0"],
      [":bfirst records the position left", ":bl<CR>:bfirst<CR>", "c.txt 0:0 | a.txt 2:0"],
      ["<leader>bn records the position left", "<Space>bn", "a.txt 2:0 | b.txt 0:0"],
      ["<leader>bp records the position left", "<Space>bp", "a.txt 2:0 | c.txt 0:0"],
      ["The finder records the position left", "<Space>ffc.txt<CR>", "a.txt 2:0 | c.txt 0:0"],
      ["The explorer records the position left", "<Space>ej<CR>", "a.txt 2:0 | b.txt 0:0"]
    ]) do |keys|
      h = listed("jj#{keys}")
      h.type("<C-o>")
      back = where(h)
      h.type("<C-i>")
      "#{back} | #{where(h)}"
    end

    # Scenario "Ctrl-O walks back through several switches".
    h = fresh("j:e b.txt<CR>jj:e c.txt<CR><C-o>")
    first = where(h)
    h.type("<C-o>")
    t.assert_equal(["b.txt 2:0", "a.txt 1:0"], [first, where(h)], "Ctrl-O walks back through several switches")

    # Scenario "A file opened over the startup buffer records nothing".
    h = editor
    h.type(":e a.txt<CR><C-o>")
    t.assert_equal(["a.txt 0:0", 0], [where(h), h.state.window.jumps.count], "A file opened over the startup buffer records nothing")

    # Scenario "Deleting a buffer records nothing".
    h = fresh(":e b.txt<CR>:bd<CR>")
    t.assert_equal(["a.txt 0:0", 1], [where(h), h.state.window.jumps.count], "Deleting a buffer records nothing")

    h = fresh(":e b.txt<CR>:e b.txt<CR>")
    t.assert_equal(1, h.state.window.jumps.count, ":e of the buffer shown records nothing")

    # Scenario "A split copies the jump list": the new window walks back
    # to a.txt and the other window still shows b.txt.
    h = fresh("jj:e b.txt<CR>:sp<CR><C-o>")
    copied = where(h)
    h.type("<C-w>j")
    t.assert_equal(["a.txt 2:0", "b.txt 0:0"], [copied, where(h)], "A split copies the jump list")

    # Scenario "A window walks only its own list": the lower window's
    # list holds only a.txt's entry, never the one the upper window's
    # :e left.
    h = fresh("jj:e b.txt<CR>:sp<CR>:e c.txt<CR><C-w>j<C-o>")
    own = where(h)
    h.type("<C-o>")
    oldest = where(h)
    h.type("<C-w>k<C-o>")
    t.assert_equal(["a.txt 2:0", "a.txt 2:0", "b.txt 0:0"], [own, oldest, where(h)], "A window walks only its own list")

    # Scenario "A new tab page copies the jump list".
    h = fresh("jj:e b.txt<CR>:tabnew<CR><C-o>")
    t.assert_equal([2, "a.txt 2:0"], [h.tab_index, where(h)], "A new tab page copies the jump list")

    # Scenario "A walk back to a scratch buffer keeps the file's tab": a
    # window on a scratch buffer another window also shows opens b.txt,
    # and Ctrl-O shows the scratch buffer again without unlisting b.txt.
    h = fresh("")
    scratch = Carat::Domain::Buffer.new(lines: ["l"], path: nil, line_ending: "\n")
    scratch.owner = "hello"
    scratch.title = "list"
    h.assembly.buffers.add(scratch)
    h.assembly.buffers.load(scratch)
    h.type(":sp<CR>:e b.txt<CR><C-o>")
    held = h.assembly.buffers.for_path("b.txt")
    t.assert_equal([true, true], [h.buffer.equal?(scratch), !held.nil? && held.listed], "A walk back to a scratch buffer keeps the file's tab")

    t.finish
  end
end

EditorJumpsTest.main if __FILE__ == $0
