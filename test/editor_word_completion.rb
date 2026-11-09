require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorWordCompletionTest
  # A 24 by 80 editor on "a.txt" with the text, "b.txt" listed behind it
  # with the other text, and "c.txt" on disk only.
  def self.editor(text, other)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text.to_s)
    files.put("b.txt", other.to_s)
    files.put("c.txt", "fizz\nzebu\n")
    h = Carat::Doubles::EditorHarness.default(files, 24, 80)
    h.open("b.txt")
    h.open("a.txt")
    h
  end

  # The popup's labels in row order.
  def self.labels(h)
    menu = h.assembly.completion_menu
    out = [""]
    out.clear
    i = 0
    while i < menu.matches.length
      out << menu.candidates.at(menu.matches[i]).label
      i += 1
    end
    out
  end

  # What the keys left: the popup's labels, the selected label ("" for
  # none), the cursor's line, the mode, and the message.
  def self.after(text, keys)
    h = editor(text, "")
    h.type(keys.to_s)
    menu = h.assembly.completion_menu
    [labels(h), menu.showing? ? menu.chosen.label : "", h.state.buffer.line(h.state.cursor.row), h.mode, h.message]
  end

  def self.main
    t = Carat::Testing.new("editor_word_completion")

    # Rows are [label, [text, keys], [labels, selected, line, mode, message]].
    t.table([
      ["Ctrl-N selects the nearest match forward", ["alpha\nfi\nfile\nfinal\nfilter\n", "jA<C-n>"], [["file", "final", "filter"], "file", "fi", :insert, ""]],
      ["a second Ctrl-N selects the next match", ["alpha\nfi\nfile\nfinal\nfilter\n", "jA<C-n><C-n>"], [["file", "final", "filter"], "final", "fi", :insert, ""]],
      ["repeated presses move and wrap: Ctrl-N wraps to the first match", ["alpha\nfi\nfile\nfinal\nfilter\n", "jA<C-n><C-n><C-n><C-n>"], [["file", "final", "filter"], "file", "fi", :insert, ""]],
      ["Ctrl-P selects the nearest match backward, on the last row", ["first\nfine\nfi\nfile\n", "jjA<C-p>"], [["file", "first", "fine"], "fine", "fi", :insert, ""]],
      ["a second Ctrl-P selects the farther match above", ["first\nfine\nfi\nfile\n", "jjA<C-p><C-p>"], [["file", "first", "fine"], "first", "fi", :insert, ""]],
      ["Ctrl-P wraps to the last match", ["first\nfine\nfi\nfile\n", "jjA<C-p><C-p><C-p><C-p>"], [["file", "first", "fine"], "fine", "fi", :insert, ""]],
      ["the forward scan wraps to the top", ["fine\nfi\nfile\n", "jA<C-n>"], [["file", "fine"], "file", "fi", :insert, ""]],
      ["the rest of the cursor's line comes first", ["x fi fiz\nfib\n", "0wea<C-n>"], [["fiz", "fib"], "fiz", "x fi fiz", :insert, ""]],
      ["backward, the line before the cursor comes first", ["fib\nfia fi\n", "jA<C-p>"], [["fib", "fia"], "fia", "fia fi", :insert, ""]],
      ["duplicates are listed once, where first found", ["fi\nfile file\nfinal\nfile\n", "A<C-n>"], [["file", "final"], "file", "fi", :insert, ""]],
      ["case counts", ["fi\nFile\nfile\n", "A<C-n>"], [["file"], "file", "fi", :insert, ""]],
      ["a word equal to the typed part is no match", ["fi\nfi\nfix\n", "A<C-n>"], [["fix"], "fix", "fi", :insert, ""]],
      ["a non-ASCII word is one word", ["fi\nfiné-x\n", "A<C-n>"], [["finé"], "finé", "fi", :insert, ""]],
      ["with no word before the cursor every word matches", ["ab cd\n\n", "jA<C-n>"], [["ab", "cd"], "ab", "", :insert, ""]],
      ["no match reads Pattern not found and changes nothing", ["zq\nalpha\n", "A<C-n>"], [[], "", "zq", :insert, "Pattern not found"]],
      ["Ctrl-P with no match reads the same", ["zq\nalpha\n", "A<C-p>"], [[], "", "zq", :insert, "Pattern not found"]],
      ["Enter puts the word over the typed part", ["fi\nfile\n", "A<C-n><CR>"], [[], "", "file", :insert, ""]],
      ["Tab puts it over the whole word", ["fi\nfinal\nfile\n", "A<C-n><C-n><Tab>"], [[], "", "file", :insert, ""]],
      ["Esc closes the popup and stays in insert mode", ["fi\nfile\n", "A<C-n><Esc>"], [[], "", "fi", :insert, ""]],
      ["typing filters the words", ["fi\nfile\nfinal\n", "A<C-n>n"], [["final"], "final", "fin", :insert, ""]]
    ]) do |input|
      after(input[0], input[1])
    end

    # The error flag of the message.
    h = editor("zq\nalpha\n", "")
    h.type("A<C-n>")
    t.assert_equal([true, false, 0], [h.state.message_error, h.assembly.completion_menu.showing?, h.state.tab.floats.count], "no match is an error and opens no float")

    # Other listed buffers follow the current one; a file only on disk is
    # not read.
    h = editor("fi\nfile\n", "final\nfile\n")
    h.type("A<C-n>")
    t.assert_equal([["a.txt", "b.txt"].sort, ["file", "final"], "file"], [h.buffer_paths.sort, labels(h), h.assembly.completion_menu.chosen.label], "Ctrl-N reads the other listed buffer after the current one")
    h = editor("fi\nfile\n", "final\nfile\n")
    h.type("A<C-p>")
    t.assert_equal([["final", "file"], "file"], [labels(h), h.assembly.completion_menu.chosen.label], "Ctrl-P reads the current buffer backward, then the other buffer bottom to top")

    # The popup is the completion popup: a float under the word.
    h = editor("fi\nfile\nfinal\n", "")
    h.type("A<C-n>")
    t.assert_equal([1, 2], [h.state.tab.floats.count, h.state.tab.floats.at(0).window.buffer.line_count], "the words show in one popup float, a row each")
    h.type("<C-p>")
    t.assert_equal([1, 1], [h.state.tab.floats.at(0).selected, h.state.tab.floats.at(0).window.cursor.row], "Ctrl-P in the popup selects the row above, wrapping")
    h = editor("first\nfine\nfi\n", "")
    h.type("jjA<C-p>")
    t.assert_equal([1, 1], [h.state.tab.floats.at(0).selected, h.state.tab.floats.at(0).window.cursor.row], "a Ctrl-P popup opens on its last row")

    # The dot command repeats the accepted word, not the scan.
    h = editor("fi\nfile\nfi\n", "")
    h.type("A<C-n><CR><Esc>jj.")
    t.assert_equal(["file", "file", "file"], [h.lines[0], h.lines[1], h.lines[2]], "the dot command repeats the inserted word")

    # With the language server's popup open, Ctrl-N moves its selection.
    h = editor("fi_tail\nfinal_word\n", "")
    h.completions.add("file_name", "variable", "", "")
    h.completions.add("filter", "function", "", "")
    h.type("ifi")
    first = h.assembly.completion_menu.chosen.label
    h.type("<C-n>")
    t.assert_equal([["file_name", "filter"].sort, true, true], [labels(h).sort, h.assembly.completion_menu.chosen.label != first, h.assembly.completion_menu.showing?], "the server's popup keeps its keys: Ctrl-N moves its selection and reads no buffer")

    # A large buffer is scanned within the bound: a match before it is
    # offered, one past a million bytes is not.
    text = +"ze\nzest\n"
    row = "x" * 40 + "\n"
    i = 0
    while i < 30_000
      text << row
      i += 1
    end
    text << "zebra\n"
    h = editor(text, "")
    h.type("A<C-n>")
    t.assert_equal([["zest"], 30_003], [labels(h), h.lines.length], "a match past the byte bound is not offered")

    t.finish
  end
end

EditorWordCompletionTest.main if __FILE__ == $0
