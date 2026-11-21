require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorCommentsTest
  # An editor over the default options with one file open: a ".rb" path
  # is a ruby buffer, a ".txt" path one of no filetype.
  def self.editor(path, text)
    files = Carat::Doubles::MemoryFiles.new
    files.put(path.to_s, text.to_s)
    h = Carat::Doubles::EditorHarness.default(files, 12, 80)
    h.open(path.to_s)
    h
  end

  def self.main
    t = Carat::Testing.new("editor_comments")
    ten = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n"

    # The comment operator gc, gcc, visual gc, and the gc text object:
    # rows are [label, [path, text, start, keys], [lines, cursor, mode]].
    # A label naming a scenario of the change's delta specs proves it.
    t.cases([
      # Comment operator.
      ["gcc comments the line", ["a.rb", "a = 1\n", [0, 2], "gcc"], [["# a = 1"], [0, 0], :normal]],
      ["gc with a motion and a count", ["a.rb", "a\nb\nc\nd\ne\n", [0, 0], "3gcj"], [["# a", "# b", "# c", "# d", "e"], [0, 0], :normal]],
      ["gc with a count after the operator", ["a.rb", "a\nb\nc\n", [0, 0], "gc2j"], [["# a", "# b", "# c"], [0, 0], :normal]],
      ["gcc with a count", ["a.rb", "a\nb\nc\nd\n", [1, 0], "2gcc"], [["a", "# b", "# c", "d"], [1, 0], :normal]],
      ["gc with a text object", ["a.rb", "a\nb\n\nc\n", [0, 0], "gcip"], [["# a", "# b", "", "c"], [0, 0], :normal]],
      ["gcc never deletes text", ["a.rb", ten, [2, 0], "gcc8G"], [["1", "2", "# 3", "4", "5", "6", "7", "8", "9", "10"], [7, 0], :normal]],
      ["gcc twice never deletes text", ["a.rb", ten, [2, 0], "gccgcc"], [["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], [2, 0], :normal]],
      ["gcc on the last line", ["a.rb", "a\nb\n", [1, 0], "gcc"], [["a", "# b"], [1, 0], :normal]],
      ["a count past the last line stops there", ["a.rb", "a\nb\n", [0, 0], "5gcc"], [["# a", "# b"], [0, 0], :normal]],
      ["gc on a motion that fails does nothing", ["a.rb", "a\nb\n", [1, 0], "gcj"], [["a", "b"], [1, 0], :normal]],
      ["gc then another operator cancels", ["a.rb", "a\nb\n", [0, 0], "gcdj"], [["a", "b"], [1, 0], :normal]],
      ["another g operator then c still cancels", ["a.rb", "ab\n", [0, 0], "gUc"], [["ab"], [0, 0], :normal]],
      # Comment toggle rule.
      ["Uncomment removes the marker and one space", ["a.rb", "# a\n#b\n  #  c\n", [0, 0], "gc2j"], [["a", "b", "   c"], [0, 0], :normal]],
      ["A line of only the marker becomes empty", ["a.rb", "# a\n  #\n", [0, 0], "gcj"], [["a", ""], [0, 0], :normal]],
      ["A mixed range is commented", ["a.rb", "# a\nb\n", [0, 0], "gcj"], [["# # a", "# b"], [0, 0], :normal]],
      ["Blank lines are untouched", ["a.rb", "a\n\nb\n", [0, 0], "gc2j"], [["# a", "", "# b"], [0, 0], :normal]],
      ["Blank lines are untouched when uncommenting", ["a.rb", "# a\n  \n# b\n", [0, 0], "gc2j"], [["a", "  ", "b"], [0, 0], :normal]],
      ["The marker goes at the smallest indent", ["a.rb", "    a\n  b\n", [0, 0], "gcj"], [["  #   a", "  # b"], [0, 2], :normal]],
      ["tabs of indent keep their place", ["a.rb", "\ta\n\t\tb\n", [0, 0], "gcj"], [["\t# a", "\t# \tb"], [0, 1], :normal]],
      ["trailing blanks are kept", ["a.rb", "a  \n", [0, 0], "gcc"], [["# a  "], [0, 0], :normal]],
      ["a multi-byte line is commented and uncommented", ["a.rb", "  éa\n", [0, 0], "gccgcc"], [["  éa"], [0, 2], :normal]],
      ["a multi-byte line takes the marker before it", ["a.rb", "  éa\n", [0, 0], "gcc"], [["  # éa"], [0, 2], :normal]],
      ["CRLF lines toggle as lines", ["a.rb", "a\r\nb\r\n", [0, 0], "gcj"], [["# a", "# b"], [0, 0], :normal]],
      ["a blank line alone stays as it is", ["a.rb", "  \n", [0, 0], "gcc"], [["  "], [0, 1], :normal]],
      ["an empty buffer stays empty", ["a.rb", "", [0, 0], "gcc"], [[""], [0, 0], :normal]],
      # Comment marker by filetype.
      ["An unknown filetype uses the default marker", ["a.txt", "a\n", [0, 0], "gcc"], [["# a"], [0, 0], :normal]],
      # Repeating and undoing a comment toggle.
      ["One undo restores the toggled lines", ["a.rb", "a\nb\nc\n", [0, 0], "3gccu"], [["a", "b", "c"], [0, 0], :normal]],
      ["One undo restores the uncommented lines", ["a.rb", "# a\n# b\n", [0, 0], "gcju"], [["# a", "# b"], [0, 0], :normal]],
      ["Dot repeats the toggle", ["a.rb", "a\nb\nc\n", [0, 0], "gccj."], [["# a", "# b", "c"], [1, 0], :normal]],
      ["Dot repeats the count", ["a.rb", "a\nb\nc\nd\ne\n", [0, 0], "2gccjj."], [["# a", "# b", "# c", "# d", "e"], [2, 0], :normal]],
      ["Dot repeats a visual toggle", ["a.rb", "a\nb\nc\nd\ne\n", [0, 0], "Vjgcjj."], [["# a", "# b", "# c", "# d", "e"], [2, 0], :normal]],
      # Comment operator in the visual modes.
      ["Visual gc", ["a.rb", "a\nb\nc\n", [0, 0], "vjgc"], [["# a", "# b", "c"], [0, 0], :normal]],
      ["Visual line gc uncomments", ["a.rb", "# a\n# b\n", [0, 0], "Vjgc"], [["a", "b"], [0, 0], :normal]],
      ["Visual block gc toggles whole lines", ["a.rb", "abc\ndef\n", [0, 1], "<C-v>jlgc"], [["# abc", "# def"], [0, 0], :normal]],
      ["visual gc upward puts the cursor on the first line", ["a.rb", "a\nb\nc\n", [2, 0], "vkgc"], [["a", "# b", "# c"], [1, 0], :normal]],
      # Comment object.
      ["dgc deletes the comment block", ["a.rb", "a\n# b\n# c\nd\n", [1, 0], "dgc"], [["a", "d"], [1, 0], :normal]],
      ["dgc off a comment does nothing", ["a.rb", "a\n# b\n", [0, 0], "dgc"], [["a", "# b"], [0, 0], :normal]],
      ["a blank line ends the comment block", ["a.rb", "# a\n\n# b\n", [0, 0], "dgc"], [["", "# b"], [0, 0], :normal]],
      ["gcgc uncomments the comment block", ["a.rb", "x\n# a\n  # b\ny\n", [2, 0], "gcgc"], [["x", "a", "  b", "y"], [1, 0], :normal]]
    ]) do |input|
      h = editor(input[0], input[1])
      h.state.cursor.move_to(Carat::Json.element(input[2], 0), Carat::Json.element(input[2], 1))
      h.type(input[3])
      [h.lines, h.cursor, h.mode]
    end

    # ygc yanks the comment block: the register holds its lines.
    h = editor("a.rb", "# a\n# b\nc\n")
    h.state.cursor.move_to(1, 0)
    h.type("ygc")
    t.assert_equal(["# a\n# b", true, ["# a", "# b", "c"]], [h.assembly.registers.read("").text, h.assembly.registers.read("").linewise?, h.lines], "ygc yanks the comment block")

    # A toggle that changes nothing leaves the buffer unmodified.
    h = editor("a.rb", "\n")
    h.type("gcc")
    t.assert_true(!h.buffer.modified?, "a toggle of blank lines does not modify the buffer")
    h.type("igcc<Esc>")
    t.assert_equal(["gcc"], h.lines, "gcc in insert mode is text")

    # The marker table.
    t.assert_equal(["#", "#", "#"], [Carat::Domain::Comments.marker_for("ruby"), Carat::Domain::Comments.marker_for("unknown"), Carat::Domain::Comments.marker_for("")], "the marker is the filetype's row, # by default")

    t.finish
  end
end

EditorCommentsTest.main if __FILE__ == $0
