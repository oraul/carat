require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The scenarios of the operators spec for g~, gu, and gU, by the labels
# of their rows: "g~ gu gU over motions", "g~ gu gU over text objects",
# "g~ gu gU with counts", "the doubled forms", "multibyte letters",
# "the edges of the buffer", "dot repeats a case operator", "one undo
# for a case operator", and "the visual modes".
module EditorCaseOperatorsTest
  def self.editor(text)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.default(files, 10, 80)
    h.open("a.txt")
    h
  end

  # The text of a recase, the way the library takes it: a typed string and
  # a symbol for the table's word.
  def self.recased(text, how)
    kind = :replace
    kind = :toggle if how == "toggle"
    kind = :lower if how == "lower"
    kind = :upper if how == "upper"
    Carat::Domain::Operators.recase(text, kind, "x")
  end

  def self.main
    t = Carat::Testing.new("editor_case_operators")

    # Keys over a buffer: rows are [label, [text, start, keys], [lines, cursor, mode]].
    t.cases([
      # g~ gu gU over motions.
      ["g~ gu gU over motions: g~w toggles to the next word", ["abC def\n", [0, 0], "g~w"], [["ABc def"], [0, 0], :normal]],
      ["g~ gu gU over motions: gUw upper-cases the word", ["abc def\n", [0, 0], "gUw"], [["ABC def"], [0, 0], :normal]],
      ["g~ gu gU over motions: guw lower-cases the word", ["ABC DEF\n", [0, 0], "guw"], [["abc DEF"], [0, 0], :normal]],
      ["g~ gu gU over motions: gU$ from the middle", ["abcd\n", [0, 1], "gU$"], [["aBCD"], [0, 1], :normal]],
      ["g~ gu gU over motions: gu0 back to the start", ["ABCD\n", [0, 2], "gu0"], [["abCD"], [0, 0], :normal]],
      ["g~ gu gU over motions: gUb back a word keeps the cursor at its start", ["abc def\n", [0, 4], "gUb"], [["ABC def"], [0, 0], :normal]],
      ["g~ gu gU over motions: gUe is inclusive", ["abc def\n", [0, 0], "gUe"], [["ABC def"], [0, 0], :normal]],
      ["g~ gu gU over motions: gUf. through the dot", ["ab.cd\n", [0, 0], "gUf."], [["AB.cd"], [0, 0], :normal]],
      ["g~ gu gU over motions: gUt. up to the dot", ["ab.cd\n", [0, 0], "gUt."], [["AB.cd"], [0, 0], :normal]],
      ["g~ gu gU over motions: gUj covers two lines and keeps the column", ["ab\ncd\nef\n", [0, 1], "gUj"], [["AB", "CD", "ef"], [0, 1], :normal]],
      ["g~ gu gU over motions: gUk goes to the upper line", ["ab\ncd\nef\n", [1, 1], "gUk"], [["AB", "CD", "ef"], [0, 1], :normal]],
      ["g~ gu gU over motions: gUG to the end of the buffer", ["ab\ncd\nef\n", [1, 0], "gUG"], [["ab", "CD", "EF"], [1, 0], :normal]],
      ["g~ gu gU over motions: gUgg to the start of the buffer", ["ab\ncd\nef\n", [1, 0], "gUgg"], [["AB", "CD", "ef"], [0, 0], :normal]],
      ["g~ gu gU over motions: g~} across lines from the middle of a line", ["ab\ncd\n\nef\n", [0, 1], "g~}"], [["aB", "CD", "", "ef"], [0, 1], :normal]],
      ["g~ gu gU over motions: g~l on the last character", ["abc\n", [0, 2], "g~l"], [["abC"], [0, 2], :normal]],
      ["g~ gu gU over motions: a search motion", ["abc def abc\n", [0, 0], "gU/def<CR>"], [["ABC def abc"], [0, 0], :normal]],
      ["g~ gu gU over motions: no register is written", ["abc\n", [0, 0], "ylgUwp"], [["AaBC"], [0, 1], :normal]],
      # g~ gu gU over text objects.
      ["g~ gu gU over text objects: g~iw", ["abc def\n", [0, 5], "g~iw"], [["abc DEF"], [0, 4], :normal]],
      ["g~ gu gU over text objects: gUiw", ["abc def\n", [0, 1], "gUiw"], [["ABC def"], [0, 0], :normal]],
      ["g~ gu gU over text objects: guaw takes the blank after", ["ABC DEF GHI\n", [0, 4], "guaw"], [["ABC def GHI"], [0, 4], :normal]],
      ["g~ gu gU over text objects: gUi( inside the parentheses", ["f(ab, cd)\n", [0, 3], "gUi("], [["f(AB, CD)"], [0, 2], :normal]],
      ["g~ gu gU over text objects: gUa( with the parentheses", ["f(ab)x\n", [0, 3], "gUa("], [["f(AB)x"], [0, 1], :normal]],
      ["g~ gu gU over text objects: gUi\" inside the quotes", ["say \"hi\" now\n", [0, 6], "gUi\""], [["say \"HI\" now"], [0, 5], :normal]],
      ["g~ gu gU over text objects: gUip over lines", ["ab\ncd\n\nef\n", [1, 0], "gUip"], [["AB", "CD", "", "ef"], [0, 0], :normal]],
      ["g~ gu gU over text objects: gUis", ["One. Two.\n", [0, 6], "gUis"], [["One. TWO."], [0, 5], :normal]],
      # Counts.
      ["g~ gu gU with counts: 2gUw", ["ab cd ef\n", [0, 0], "2gUw"], [["AB CD ef"], [0, 0], :normal]],
      ["g~ gu gU with counts: gU2w", ["ab cd ef\n", [0, 0], "gU2w"], [["AB CD ef"], [0, 0], :normal]],
      ["g~ gu gU with counts: 2gU2w multiplies", ["a b c d e\n", [0, 0], "2gU2w"], [["A B C D e"], [0, 0], :normal]],
      ["g~ gu gU with counts: 2g~iw reaches the blank and the next word", ["ab cd ef\n", [0, 0], "2g~iw"], [["AB cd ef"], [0, 0], :normal]],
      ["g~ gu gU with counts: gUl takes one character", ["abc\n", [0, 0], "gUl"], [["Abc"], [0, 0], :normal]],
      ["g~ gu gU with counts: 2gUl takes two", ["abc\n", [0, 0], "2gUl"], [["ABc"], [0, 0], :normal]],
      ["g~ gu gU with counts: 9gUl stops at the line end", ["abc\n", [0, 1], "9gUl"], [["aBC"], [0, 1], :normal]],
      # The doubled forms.
      ["the doubled forms: g~~ toggles the line and keeps the cursor", ["abC dE\n", [0, 2], "g~~"], [["ABc De"], [0, 2], :normal]],
      ["the doubled forms: guu lower-cases the line", ["AbC\n", [0, 1], "guu"], [["abc"], [0, 1], :normal]],
      ["the doubled forms: gUU upper-cases the line", ["abC\n", [0, 1], "gUU"], [["ABC"], [0, 1], :normal]],
      ["the doubled forms: g~g~ is g~~", ["abC\n", [0, 0], "g~g~"], [["ABc"], [0, 0], :normal]],
      ["the doubled forms: gugu is guu", ["ABC\n", [0, 0], "gugu"], [["abc"], [0, 0], :normal]],
      ["the doubled forms: gUgU is gUU", ["abc\n", [0, 0], "gUgU"], [["ABC"], [0, 0], :normal]],
      ["the doubled forms: 2g~~ takes two lines", ["ab\ncD\nef\n", [0, 0], "2g~~"], [["AB", "Cd", "ef"], [0, 0], :normal]],
      ["the doubled forms: 3gUU takes three lines", ["ab\ncd\nef\ngh\n", [1, 1], "3gUU"], [["ab", "CD", "EF", "GH"], [1, 1], :normal]],
      ["the doubled forms: gU2U counts after the operator", ["ab\ncd\nef\n", [0, 0], "gU2U"], [["AB", "CD", "ef"], [0, 0], :normal]],
      ["the doubled forms: 9guu clamps to the buffer", ["AB\nCD\n", [0, 0], "9guu"], [["ab", "cd"], [0, 0], :normal]],
      ["the doubled forms: gUd cancels", ["ab\ncd\n", [0, 0], "gUd"], [["ab", "cd"], [0, 0], :normal]],
      ["the doubled forms: g~ then Escape cancels", ["ab\n", [0, 0], "g~<Esc>x"], [["b"], [0, 0], :normal]],
      # Multibyte letters.
      ["multibyte letters: g~~ toggles accents and keeps the sharp s", ["éÜß a\n", [0, 0], "g~~"], [["Éüß A"], [0, 0], :normal]],
      ["multibyte letters: gUU turns the sharp s into SS", ["éüß\n", [0, 1], "gUU"], [["ÉÜSS"], [0, 1], :normal]],
      ["multibyte letters: guu lower-cases accents", ["ÀÉÎ\n", [0, 0], "guu"], [["àéî"], [0, 0], :normal]],
      ["multibyte letters: gUiw over Cyrillic", ["привет мир\n", [0, 2], "gUiw"], [["ПРИВЕТ мир"], [0, 0], :normal]],
      ["multibyte letters: g~w over Greek", ["αβγ ΔΕΖ\n", [0, 0], "g~w"], [["ΑΒΓ ΔΕΖ"], [0, 0], :normal]],
      ["multibyte letters: gUl on one accented letter", ["éa\n", [0, 0], "gUl"], [["Éa"], [0, 0], :normal]],
      ["multibyte letters: gUl on the sharp s becomes two letters", ["ßa\n", [0, 0], "gUl"], [["SSa"], [0, 0], :normal]],
      ["multibyte letters: gUw after a multibyte word counts characters", ["éé ab\n", [0, 0], "gUw"], [["ÉÉ ab"], [0, 0], :normal]],
      ["multibyte letters: gUe from after a multibyte letter", ["éab cd\n", [0, 1], "gUe"], [["éAB cd"], [0, 1], :normal]],
      ["multibyte letters: a final sigma lowers as a plain sigma", ["ΑΣ\n", [0, 0], "guu"], [["ασ"], [0, 0], :normal]],
      ["multibyte letters: a letter with no single-letter form stays", ["ﬁa\n", [0, 0], "gUU"], [["ﬁA"], [0, 0], :normal]],
      ["multibyte letters: a dotted capital I lowers to i", ["İa\n", [0, 0], "guu"], [["ia"], [0, 0], :normal]],
      # The edges of the buffer.
      ["the edges of the buffer: gUU on an empty line", ["\nab\n", [0, 0], "gUU"], [["", "ab"], [0, 0], :normal]],
      ["the edges of the buffer: gUU in an empty buffer", ["", [0, 0], "gUU"], [[""], [0, 0], :normal]],
      ["the edges of the buffer: gUl on an empty line changes nothing", ["\n", [0, 0], "gUl"], [[""], [0, 0], :normal]],
      ["the edges of the buffer: gUh at column 0 changes nothing", ["abc\n", [0, 0], "gUh"], [["abc"], [0, 0], :normal]],
      ["the edges of the buffer: gUj on the last line changes nothing", ["a\nb\n", [1, 0], "gUj"], [["a", "b"], [1, 0], :normal]],
      ["the edges of the buffer: gUU keeps trailing blanks", ["ab \t\n", [0, 0], "gUU"], [["AB \t"], [0, 0], :normal]],
      ["the edges of the buffer: gUU on the last line without a final newline", ["a\nbc", [1, 0], "gUU"], [["a", "BC"], [1, 0], :normal]],
      ["the edges of the buffer: gUU in a CRLF file changes the line and no other", ["ab\r\ncd\r\n", [0, 0], "gUU"], [["AB", "cd"], [0, 0], :normal]],
      ["the edges of the buffer: gUw at the last word of a line stays on it", ["ab\ncd\n", [0, 0], "gUw"], [["AB", "cd"], [0, 0], :normal]],
      ["the edges of the buffer: gUU on an unchanged line keeps the buffer as it was", ["AB\n", [0, 1], "gUU"], [["AB"], [0, 1], :normal]],
      # The visual modes.
      ["the visual modes: vgU on characters", ["abcd\n", [0, 0], "vlgU"], [["ABcd"], [0, 0], :normal]],
      ["the visual modes: vg~ toggles", ["aBcd\n", [0, 0], "vllg~"], [["AbCd"], [0, 0], :normal]],
      ["the visual modes: vgu lower-cases backwards", ["ABCD\n", [0, 2], "vhgu"], [["AbcD"], [0, 1], :normal]],
      ["the visual modes: Vgu on lines", ["AB\nCD\nEF\n", [0, 0], "Vjgu"], [["ab", "cd", "EF"], [0, 0], :normal]],
      ["the visual modes: VgU leaves the cursor on the top line at the column it had", ["ab\ncd\n", [1, 1], "VkgU"], [["AB", "CD"], [0, 1], :normal]],
      ["the visual modes: <C-v>g~ over a block", ["aBc\ndEf\n", [0, 0], "<C-v>jlg~"], [["Abc", "Def"], [0, 0], :normal]],
      ["the visual modes: <C-v>gU over a block to the line ends", ["abc\nde\n", [0, 1], "<C-v>j$gU"], [["aBC", "dE"], [0, 1], :normal]],
      ["the visual modes: vgU over multibyte letters", ["éßa\n", [0, 0], "vlgU"], [["ÉSSa"], [0, 0], :normal]],
      ["the visual modes: v~ over multibyte letters", ["ÉüB\n", [0, 0], "vll~"], [["éÜb"], [0, 0], :normal]],
      ["the visual modes: Vu over multibyte letters", ["ÀÉ\n", [0, 0], "Vu"], [["àé"], [0, 0], :normal]],
      ["the visual modes: <C-v>U over multibyte letters", ["éa\nüb\n", [0, 0], "<C-v>jlU"], [["ÉA", "ÜB"], [0, 0], :normal]],
      ["the visual modes: v$gU on an empty line", ["\nab\n", [0, 0], "vgU"], [["", "ab"], [0, 0], :normal]],
      # Dot repeats a case operator.
      ["dot repeats a case operator: gUiw then w and dot", ["ab cd ef\n", [0, 0], "gUiww."], [["AB CD ef"], [0, 3], :normal]],
      ["dot repeats a case operator: g~w from the start of the next word", ["ab cD ef\n", [0, 0], "g~ww."], [["AB Cd ef"], [0, 3], :normal]],
      ["dot repeats a case operator: guu on the next line", ["AB\nCD\n", [0, 0], "guuj."], [["ab", "cd"], [1, 0], :normal]],
      ["dot repeats a case operator: 2gUU repeats with its count", ["a\nb\nc\nd\ne\n", [0, 0], "2gUUjj."], [["A", "B", "C", "D", "e"], [2, 0], :normal]],
      ["dot repeats a case operator: a new count replaces the old", ["a b c d e\n", [0, 0], "gUwww3."], [["A b C D E"], [0, 4], :normal]],
      ["dot repeats a case operator: gUgU repeats as gUU", ["ab\ncd\n", [0, 0], "gUgUj."], [["AB", "CD"], [1, 0], :normal]],
      ["dot repeats a case operator: over multibyte letters", ["éa ib\n", [0, 0], "gUiww."], [["ÉA IB"], [0, 3], :normal]],
      ["dot repeats a case operator: visual gU repeats on as many characters", ["abcd\n", [0, 0], "vlgUll."], [["ABCD"], [0, 2], :normal]],
      ["dot repeats a case operator: a visual ~ repeats", ["abcd\n", [0, 0], "v~l."], [["ABcd"], [0, 1], :normal]],
      ["dot repeats a case operator: a visual line gu repeats", ["AB\nCD\nEF\n", [0, 0], "Vgujj."], [["ab", "CD", "ef"], [2, 0], :normal]],
      # One undo for a case operator.
      ["one undo for a case operator: u after gUiw", ["ab cd\n", [0, 0], "gUiwu"], [["ab cd"], [0, 0], :normal]],
      ["one undo for a case operator: u after gUj over two lines", ["ab\ncd\n", [0, 0], "gUju"], [["ab", "cd"], [0, 0], :normal]],
      ["one undo for a case operator: u after g~ over a paragraph", ["ab\ncd\n\nef\n", [0, 0], "g~}u"], [["ab", "cd", "", "ef"], [0, 0], :normal]],
      ["one undo for a case operator: u after the repeat leaves the first change", ["ab cd\n", [0, 0], "gUiww.u"], [["AB cd"], [0, 3], :normal]],
      ["one undo for a case operator: a second u undoes the first", ["ab cd\n", [0, 0], "gUiww.uu"], [["ab cd"], [0, 0], :normal]],
      ["one undo for a case operator: u after a visual gU", ["abcd\n", [0, 0], "vlgUu"], [["abcd"], [0, 0], :normal]],
      ["one undo for a case operator: u after gUU over multibyte letters", ["éß\n", [0, 0], "gUUu"], [["éß"], [0, 0], :normal]],
      ["one undo for a case operator: a change of nothing leaves no undo step", ["ab\n", [0, 0], "xgUUuu"], [["ab"], [0, 0], :normal]]
    ]) do |input|
      h = editor(input[0])
      h.state.cursor.move_to(Carat::Json.element(input[1], 0), Carat::Json.element(input[1], 1))
      h.type(input[2])
      [h.lines, h.cursor, h.mode]
    end

    # Operators.recase over text: rows are [label, [text, how], result].
    t.cases([
      ["recase toggles ASCII", ["aBc", "toggle"], "AbC"],
      ["recase lowers ASCII", ["aBc", "lower"], "abc"],
      ["recase uppers ASCII", ["aBc", "upper"], "ABC"],
      ["recase replaces every character", ["aé", "replace"], "xx"],
      ["recase toggles accented letters", ["éÜ", "toggle"], "Éü"],
      ["recase keeps the sharp s when toggled", ["ß", "toggle"], "ß"],
      ["recase keeps the sharp s when lowered", ["ß", "lower"], "ß"],
      ["recase makes SS of the sharp s when upper-cased", ["straße", "upper"], "STRASSE"],
      ["recase lowers the dotted capital I to i", ["İ", "lower"], "i"],
      ["recase toggles the dotted capital I to i", ["İ", "toggle"], "i"],
      ["recase keeps a ligature when upper-cased", ["ﬁ", "upper"], "ﬁ"],
      ["recase of an empty string", ["", "upper"], ""],
      ["recase changes only the ASCII letters of text that is not valid UTF-8", ["a\xffé", "upper"], "A\xffé"]
    ]) do |input|
      recased(input[0].to_s, input[1].to_s)
    end

    t.finish
  end
end

EditorCaseOperatorsTest.main if __FILE__ == $0
