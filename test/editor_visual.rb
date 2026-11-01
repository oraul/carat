require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_visual")

# An editor over the default options: autoindent on, shiftwidth 2,
# tabstop 2, expandtab on, as config/default.json sets them.
def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.default(files, 10, 80)
  h.open("a.txt")
  h
end

# The text and kind of a register, or nil when it is empty.
def register_of(h, name)
  entry = h.assembly.registers.read(name)
  entry.nil? ? nil : [entry.text, entry.kind]
end

# Every key of visual mode in each kind it applies to: rows are
# [label, [text, start, keys], [lines, cursor, mode]].
t.table([
  # Entering, switching, and leaving.
  ["v starts charwise visual mode", ["abc\n", [0, 1], "v"], [["abc"], [0, 1], :visual]],
  ["V starts linewise visual mode", ["a\nb\n", [1, 0], "V"], [["a", "b"], [1, 0], :visual_line]],
  ["<C-v> starts blockwise visual mode", ["abc\n", [0, 0], "<C-v>"], [["abc"], [0, 0], :visual_block]],
  ["v again leaves", ["abc\n", [0, 0], "vlv"], [["abc"], [0, 1], :normal]],
  ["V again leaves", ["a\nb\n", [0, 0], "VjV"], [["a", "b"], [1, 0], :normal]],
  ["<C-v> again leaves", ["abc\n", [0, 0], "<C-v>l<C-v>"], [["abc"], [0, 1], :normal]],
  ["V after v switches to linewise", ["ab\ncd\nef\n", [0, 1], "vjV"], [["ab", "cd", "ef"], [1, 1], :visual_line]],
  ["<C-v> after V switches to blockwise", ["ab\ncd\n", [0, 1], "Vj<C-v>"], [["ab", "cd"], [1, 1], :visual_block]],
  ["v after <C-v> switches to charwise", ["ab\ncd\n", [0, 1], "<C-v>jv"], [["ab", "cd"], [1, 1], :visual]],
  ["the switched kind keeps the anchor", ["ab\ncd\nef\n", [0, 1], "vjVd"], [["ef"], [0, 0], :normal]],
  ["Escape leaves and steps off the line end", ["abc\n", [0, 0], "v$<Esc>"], [["abc"], [0, 2], :normal]],
  ["<C-c> leaves", ["a\nb\n", [0, 0], "Vj<C-c>"], [["a", "b"], [1, 0], :normal]],
  ["a count before v is ignored", ["abc\n", [0, 0], "3vd"], [["bc"], [0, 0], :normal]],
  ["an unbound key stays in visual mode", ["ab\n", [0, 0], "vQ"], [["ab"], [0, 0], :visual]],
  ["an unbound key drops a pending count", ["abcd\n", [0, 0], "v2Qld"], [["cd"], [0, 0], :normal]],
  # Motions move the cursor end.
  ["l reaches the end of the line", ["ab\n", [0, 0], "vlll"], [["ab"], [0, 2], :visual]],
  ["$ goes to the end of the line", ["abc\n", [0, 0], "v$"], [["abc"], [0, 3], :visual]],
  ["j to a shorter line rests on its end", ["abcd\nab\n", [0, 3], "vj"], [["abcd", "ab"], [1, 2], :visual]],
  ["a count multiplies a motion", ["abcdef\n", [0, 0], "v3ld"], [["ef"], [0, 0], :normal]],
  ["f reads its character", ["abcd\n", [0, 0], "vfcd"], [["d"], [0, 0], :normal]],
  ["t stops before its character", ["abcd\n", [0, 0], "vtcd"], [["cd"], [0, 0], :normal]],
  ["e extends to the word end", ["one two\n", [0, 0], "ved"], [[" two"], [0, 0], :normal]],
  ["b moves the cursor before the anchor", ["one two\n", [0, 4], "vbd"], [["wo"], [0, 0], :normal]],
  ["} selects through the empty line", ["a\nb\n\nc\n", [0, 0], "v}d"], [["c"], [0, 0], :normal]],
  ["G in linewise mode", ["a\nb\nc\n", [0, 0], "VGd"], [[""], [0, 0], :normal]],
  ["gg in linewise mode", ["a\nb\nc\n", [2, 0], "Vggd"], [[""], [0, 0], :normal]],
  # d, x, and <Del>.
  ["d deletes a charwise selection", ["abcd\n", [0, 1], "vld"], [["ad"], [0, 1], :normal]],
  ["x deletes a charwise selection", ["abcd\n", [0, 1], "vlx"], [["ad"], [0, 1], :normal]],
  ["<Del> deletes a charwise selection", ["abcd\n", [0, 1], "vl<Del>"], [["ad"], [0, 1], :normal]],
  ["d across lines", ["abc\ndef\n", [0, 1], "vjd"], [["af"], [0, 1], :normal]],
  ["d with the end on the line end joins", ["ab\ncd\n", [0, 1], "v$d"], [["acd"], [0, 1], :normal]],
  ["d on an empty line deletes it", ["a\n\nb\n", [1, 0], "vd"], [["a", "b"], [1, 0], :normal]],
  ["d to the end of the last line", ["ab\n", [0, 1], "v$d"], [["a"], [0, 0], :normal]],
  ["d deletes lines to the first non-blank", ["a\nb\n  c\n", [0, 0], "Vjd"], [["  c"], [0, 2], :normal]],
  ["d on the last line", ["a\nb\n", [1, 0], "Vd"], [["a"], [0, 0], :normal]],
  ["x deletes a block", ["abcd\nefgh\n", [0, 1], "<C-v>jlx"], [["ad", "eh"], [0, 1], :normal]],
  ["d leaves a row that ends before the block", ["abcd\na\nabcd\n", [0, 1], "<C-v>jjld"], [["ad", "a", "ad"], [0, 1], :normal]],
  ["d after $ deletes to every row's end", ["abc\nd\n", [0, 1], "<C-v>j$d"], [["a", "d"], [0, 0], :normal]],
  # y.
  ["y puts the cursor at the start", ["abcd\n", [0, 1], "vly"], [["abcd"], [0, 1], :normal]],
  ["y backward puts the cursor at the start", ["abcd\n", [0, 2], "vhy"], [["abcd"], [0, 1], :normal]],
  ["y of lines from the anchor goes to column 0", ["abcd\nefgh\n", [0, 2], "Vjy"], [["abcd", "efgh"], [0, 0], :normal]],
  ["y of lines with the cursor on top keeps its column", ["abcd\nefgh\n", [1, 2], "Vky"], [["abcd", "efgh"], [0, 2], :normal]],
  ["y of a block goes to its top-left", ["abcd\nefgh\n", [0, 2], "<C-v>jhy"], [["abcd", "efgh"], [0, 1], :normal]],
  # c and s.
  ["c changes a charwise selection", ["abcd\n", [0, 1], "vlc"], [["ad"], [0, 1], :insert]],
  ["s changes a charwise selection", ["abcd\n", [0, 1], "vls"], [["ad"], [0, 1], :insert]],
  ["c of lines keeps the indent", ["  a\nb\nc\n", [0, 0], "Vjc"], [["  ", "c"], [0, 2], :insert]],
  ["c of a block repeats the text", ["abcd\nefgh\n", [0, 1], "<C-v>jlcX<Esc>"], [["aXd", "eXh"], [0, 1], :normal]],
  ["c of a block skips a short row", ["abc\n\nabc\n", [0, 1], "<C-v>jjcX<Esc>"], [["aXc", "", "aXc"], [0, 1], :normal]],
  # > and <.
  ["> shifts lines by the count", ["a\nb\n", [0, 0], "Vj2>"], [["    a", "    b"], [0, 4], :normal]],
  ["< shifts a charwise selection's line", ["    a\n", [0, 0], "v<"], [["  a"], [0, 2], :normal]],
  ["> shifts a block at its left edge", ["ab\ncd\n", [0, 1], "<C-v>j>"], [["a  b", "c  d"], [0, 1], :normal]],
  ["< removes blanks at the block's left edge", ["a    b\nc    d\n", [0, 1], "<C-v>j<"], [["a  b", "c  d"], [0, 1], :normal]],
  ["> leaves a row that ends inside the block", ["abcd\na\n", [0, 0], "<C-v>lj>"], [["  abcd", "a"], [0, 0], :normal]],
  # J and gJ.
  ["J joins the selected lines", ["a\nb\nc\n", [0, 0], "VjjJ"], [["a b c"], [0, 3], :normal]],
  ["J on one line joins it with the next", ["a\n  b\n", [0, 0], "vJ"], [["a b"], [0, 1], :normal]],
  ["gJ keeps the blanks", ["a\n  b\n", [0, 0], "VgJ"], [["a  b"], [0, 1], :normal]],
  ["J on the last line does nothing", ["a\nb\n", [1, 0], "VJ"], [["a", "b"], [1, 0], :normal]],
  # p and P.
  ["p replaces a word", ["one two\n", [0, 0], "yiwwviwp"], [["one one"], [0, 6], :normal]],
  ["P replaces a word", ["one two\n", [0, 0], "yiwwviwP"], [["one one"], [0, 6], :normal]],
  ["a count repeats the text", ["ab\n", [0, 0], "ylvl2p"], [["aa"], [0, 1], :normal]],
  ["lines into a charwise selection split the line", ["ab\ncd\n", [0, 0], "yyjlvp"], [["ab", "c", "ab", ""], [2, 0], :normal]],
  ["text into a linewise selection becomes a line", ["a\nb\n", [0, 0], "yljVp"], [["a", "a"], [1, 0], :normal]],
  ["lines over the whole buffer", ["a\nb\n", [0, 0], "yyjVkp"], [["a"], [0, 0], :normal]],
  ["one line of text into every row of a block", ["xab\nycd\n", [0, 0], "yll<C-v>jp"], [["xxb", "yxd"], [0, 1], :normal]],
  ["a block into a block", ["ab\ncd\n", [0, 0], "<C-v>jyl<C-v>jp"], [["aa", "cc"], [0, 1], :normal]],
  ["lines into a block go below it with p", ["ab\ncd\n", [0, 0], "yy<C-v>jp"], [["b", "d", "ab"], [2, 0], :normal]],
  ["lines into a block go above it with P", ["ab\ncd\n", [0, 0], "yy<C-v>jP"], [["ab", "b", "d"], [0, 0], :normal]],
  ["a block into a charwise selection", ["ab\ncd\n", [0, 0], "<C-v>jyvp"], [["ab", "ccd"], [0, 0], :normal]],
  ["an empty register changes nothing", ["ab\n", [0, 0], "vlp"], [["ab"], [0, 1], :normal]],
  # r.
  ["r replaces every character", ["abc\n", [0, 0], "vlrx"], [["xxc"], [0, 0], :normal]],
  ["r replaces a block", ["ab\ncd\n", [0, 1], "<C-v>jrx"], [["ax", "cx"], [0, 1], :normal]],
  ["r replaces whole lines", ["ab\n", [0, 1], "Vrx"], [["xx"], [0, 0], :normal]],
  ["r leaves the line breaks", ["ab\ncd\n", [0, 1], "vjrx"], [["ax", "xx"], [0, 1], :normal]],
  ["r then a special key stays in visual mode", ["ab\n", [0, 0], "vr<Esc>"], [["ab"], [0, 0], :visual]],
  # ~, u, and U.
  ["~ toggles the case", ["aB\n", [0, 0], "v$~"], [["Ab"], [0, 0], :normal]],
  ["U upper-cases lines", ["ab\ncd\n", [0, 0], "VjU"], [["AB", "CD"], [0, 0], :normal]],
  ["u lower-cases a block", ["ABC\nDEF\n", [0, 0], "<C-v>jlu"], [["abC", "deF"], [0, 0], :normal]],
  ["~ on lines with the cursor on top", ["ab\ncD\n", [1, 1], "Vk~"], [["AB", "Cd"], [0, 1], :normal]],
  # Uppercase keys.
  ["X deletes the lines", ["ab\ncd\n", [0, 1], "vX"], [["cd"], [0, 0], :normal]],
  ["D deletes the lines", ["ab\ncd\n", [0, 1], "vD"], [["cd"], [0, 0], :normal]],
  ["D in a block deletes to the end", ["abc\ndef\n", [0, 1], "<C-v>jD"], [["a", "d"], [0, 0], :normal]],
  ["X in a block deletes the block", ["abc\ndef\n", [0, 1], "<C-v>jX"], [["ac", "df"], [0, 1], :normal]],
  ["C changes the lines", ["ab\ncd\ne\n", [0, 1], "vjC"], [["", "e"], [0, 0], :insert]],
  ["C in a block changes to the end", ["abc\ndef\n", [0, 1], "<C-v>jCX<Esc>"], [["aX", "dX"], [0, 1], :normal]],
  ["S changes the lines", ["ab\ncd\n", [0, 1], "vS"], [["", "cd"], [0, 0], :insert]],
  ["R changes the lines", ["ab\ncd\n", [0, 1], "vR"], [["", "cd"], [0, 0], :insert]],
  ["S in a block changes whole lines", ["ab\ncd\ne\n", [0, 1], "<C-v>jS"], [["", "e"], [0, 0], :insert]],
  ["Y yanks the lines", ["ab\ncd\n", [0, 1], "vY"], [["ab", "cd"], [0, 0], :normal]],
  ["Y in a block yanks the block", ["ab\ncd\n", [0, 1], "<C-v>jY"], [["ab", "cd"], [0, 1], :normal]],
  # I and A.
  ["I in a block inserts on every row that reaches it", ["ab\n\ncd\n", [0, 1], "<C-v>jjIX<Esc>"], [["aXb", "", "cXd"], [0, 1], :normal]],
  ["A in a block appends after it", ["ab\ncd\n", [0, 0], "<C-v>jAX<Esc>"], [["aXb", "cXd"], [0, 0], :normal]],
  ["A pads a short row", ["a\nabc\n", [0, 0], "<C-v>jllAX<Esc>"], [["a  X", "abcX"], [0, 0], :normal]],
  ["A after $ appends at every row's end", ["ab\nc\n", [0, 0], "<C-v>j$AX<Esc>"], [["abX", "cX"], [0, 0], :normal]],
  ["I with nothing typed repeats nothing", ["ab\ncd\n", [0, 1], "<C-v>jI<Esc>"], [["ab", "cd"], [0, 0], :normal]],
  ["a new line stops the repeat", ["ab\ncd\n", [0, 1], "<C-v>jIX<CR><Esc>"], [["aX", "b", "cd"], [1, 0], :normal]],
  ["I of lines inserts at the start", ["ab\ncd\n", [0, 1], "VjIX<Esc>"], [["Xab", "cd"], [0, 0], :normal]],
  ["A of a charwise selection appends to the last line", ["ab\ncd\n", [0, 0], "vjAX<Esc>"], [["ab", "cdX"], [1, 2], :normal]],
  # o, O, and gv.
  ["o swaps the ends", ["abcd\n", [0, 0], "vllo"], [["abcd"], [0, 0], :visual]],
  ["o keeps the selection", ["abcd\n", [0, 0], "vllod"], [["d"], [0, 0], :normal]],
  ["O moves to the other corner of a block", ["abcd\nefgh\n", [0, 0], "<C-v>jllO"], [["abcd", "efgh"], [1, 0], :visual_block]],
  ["O keeps the block", ["abcd\nefgh\n", [0, 0], "<C-v>jllOd"], [["d", "h"], [0, 0], :normal]],
  ["O back to the first corner", ["abcd\nefgh\n", [0, 0], "<C-v>jllOO"], [["abcd", "efgh"], [1, 2], :visual_block]],
  ["O outside a block acts as o", ["a\nb\n", [0, 0], "VjO"], [["a", "b"], [0, 0], :visual_line]],
  ["gv reselects after an escape", ["abcd\n", [0, 1], "vl<Esc>0gvd"], [["ad"], [0, 1], :normal]],
  ["gv reselects after a delete", ["a\nb\n", [0, 0], "Vdgv"], [["b"], [0, 0], :visual_line]],
  ["gv restores the kind", ["a\nb\n", [0, 0], "Vj<Esc>gv"], [["a", "b"], [1, 0], :visual_line]],
  ["gv with nothing stored does nothing", ["ab\n", [0, 0], "gv"], [["ab"], [0, 0], :normal]],
  ["gv in visual mode goes to the last selection", ["abcd\n", [0, 0], "vl<Esc>$vgv"], [["abcd"], [0, 1], :visual]],
  ["gv twice comes back", ["abcd\n", [0, 0], "vl<Esc>$vgvgv"], [["abcd"], [0, 3], :visual]],
  ["gv clamps to a shorter buffer", ["abc\ndef\n", [1, 2], "v<Esc>ggdGgv"], [[""], [0, 0], :visual]],
  # Text objects.
  ["viw selects the word", ["one two three\n", [0, 5], "viw"], [["one two three"], [0, 6], :visual]],
  ["vaw deletes the word and a blank", ["one two three\n", [0, 0], "vawd"], [["two three"], [0, 0], :normal]],
  ["vip turns linewise", ["a\nb\n\nc\n", [0, 0], "vip"], [["a", "b", "", "c"], [1, 0], :visual_line]],
  ["vip then d", ["a\nb\n\nc\n", [0, 0], "vipd"], [["", "c"], [0, 0], :normal]],
  ["ip again extends over the empty lines", ["a\nb\n\nc\n", [0, 0], "vipip"], [["a", "b", "", "c"], [2, 0], :visual_line]],
  ["iw turns a linewise selection charwise", ["one two\n", [0, 0], "Viw"], [["one two"], [0, 2], :visual]],
  ["iw keeps a block", ["one two\n", [0, 0], "<C-v>iw"], [["one two"], [0, 2], :visual_block]],
  ["an inner block between lines of their own is linewise", ["{\n  a\n}\n", [1, 2], "vi{d"], [["{", "}"], [1, 0], :normal]],
  ["a bracket object with no pair leaves the selection", ["abc\n", [0, 1], "vi(d"], [["ac"], [0, 1], :normal]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor, h.mode]
end

# What the registers hold: rows are [label, [text, start, keys, register], [text, kind]].
t.table([
  ["a charwise yank", ["abcd\n", [0, 1], "vly", ""], ["bc", :charwise]],
  ["a yank across lines", ["abc\ndef\n", [0, 1], "vjy", ""], ["bc\nde", :charwise]],
  ["a yank with the cursor before the anchor", ["abcd\n", [0, 2], "vhhy", ""], ["abc", :charwise]],
  ["a yank with a counted word motion", ["one two three\n", [0, 0], "v2wy", ""], ["one two t", :charwise]],
  ["a yank of the line end", ["ab\ncd\n", [0, 0], "v$y", ""], ["ab\n", :charwise]],
  ["a linewise yank", ["abcd\nefgh\n", [0, 2], "Vjy", ""], ["abcd\nefgh", :linewise]],
  ["a blockwise yank", ["abcd\nefgh\n", [0, 1], "<C-v>jly", ""], ["bc\nfg", :blockwise]],
  ["a block over a tab takes it whole", ["abcd\n\tab\nabcd\n", [0, 1], "<C-v>jjly", ""], ["bc\n\ta\nbc", :blockwise]],
  ["a block over a wide character takes it whole", ["abcd\na中b\nabcd\n", [0, 2], "<C-v>jjy", ""], ["c\n中\nc", :blockwise]],
  ["a register prefix names the register", ["ab\n", [0, 0], "v\"ay", "a"], ["a", :charwise]],
  ["a delete into a named register", ["ab\n", [0, 0], "v\"ad", "a"], ["a", :charwise]],
  ["a block delete", ["abcd\nefgh\n", [0, 1], "<C-v>jlx", ""], ["bc\nfg", :blockwise]],
  ["a linewise delete", ["a\nb\nc\n", [0, 0], "Vjd", ""], ["a\nb", :linewise]],
  ["a change", ["abcd\n", [0, 1], "vlc<Esc>", ""], ["bc", :charwise]],
  ["a block change", ["abcd\nefgh\n", [0, 1], "<C-v>jlc<Esc>", ""], ["bc\nfg", :blockwise]],
  ["p stores the replaced text", ["one two\n", [0, 0], "yiwwviwp", ""], ["two", :charwise]],
  ["P keeps the register", ["one two\n", [0, 0], "yiwwviwP", ""], ["one", :charwise]],
  ["p from a named register stores in the unnamed one", ["one two\n", [0, 0], "\"ayiwwviw\"ap", ""], ["two", :charwise]],
  ["p leaves the named register", ["one two\n", [0, 0], "\"ayiwwviw\"ap", "a"], ["one", :charwise]],
  ["Y yanks lines", ["ab\ncd\n", [0, 1], "vY", ""], ["ab", :linewise]],
  ["Y in a block yanks the block", ["ab\ncd\n", [0, 1], "<C-v>jY", ""], ["b\nd", :blockwise]],
  ["X in a block deletes the block", ["abc\ndef\n", [0, 1], "<C-v>jX", ""], ["b\ne", :blockwise]],
  ["D in a block deletes to the end", ["abc\ndef\n", [0, 1], "<C-v>jD", ""], ["bc\nef", :blockwise]],
  ["X deletes lines", ["ab\ncd\n", [0, 1], "vX", ""], ["ab", :linewise]],
  ["o keeps the selection", ["abcd\n", [0, 0], "vlloy", ""], ["abc", :charwise]],
  ["iw selects the word", ["one two three\n", [0, 5], "viwy", ""], ["two", :charwise]],
  ["iw again extends forward", ["one two three\n", [0, 0], "viwiwiwy", ""], ["one two", :charwise]],
  ["iw extends backward from the cursor", ["one two three\n", [0, 8], "vhiwy", ""], ["two t", :charwise]],
  ["i( on a larger selection goes outward", ["(a(bc)d)\n", [0, 3], "vi(i(y", ""], ["a(bc)d", :charwise]],
  ["a( selects the brackets", ["(a(bc)d)\n", [0, 3], "va(y", ""], ["(bc)", :charwise]],
  ["i\" selects the string", ["say \"hi\" now\n", [0, 6], "vi\"y", ""], ["hi", :charwise]],
  ["is selects the sentence", ["One. Two.\n", [0, 6], "visy", ""], ["Two.", :charwise]],
  ["an uppercase register appends to a block", ["ab\ncd\n", [0, 0], "<C-v>j\"ayl\"Ayl", "a"], ["a\nc\nb", :blockwise]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  register_of(h, input[3])
end

# Putting a blockwise register in normal mode: rows are [label, [text, start, keys], [lines, cursor]].
t.table([
  ["p puts a block after the cursor", ["abc\ndef\n", [0, 0], "<C-v>jly$p"], [["abcab", "defde"], [0, 3]]],
  ["P pads a short row", ["xabc\nyd\n", [0, 0], "<C-v>jdllP"], [["abxc", "d y"], [0, 2]]],
  ["rows past the end are added", ["x\ny\na\n", [0, 0], "<C-v>j\"aydddd\"ap"], [["ax", " y"], [0, 1]]],
  ["a count repeats every row", ["ab\ncd\n", [0, 0], "<C-v>jy2P"], [["aaab", "cccd"], [0, 0]]],
  ["a narrow row is padded to the block's width", ["ab\nc\nxyz\nxyz\n", [0, 0], "<C-v>jly2jlP"], [["ab", "c", "xabyz", "xc yz"], [2, 1]]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor]
end

# The mode line: rows are [label, keys, [first characters of the message row, its last character]].
t.table([
  ["charwise indicator", "v", ["-- VISUAL --", "-"]],
  ["linewise indicator", "V", ["-- VISUAL LINE --", "-"]],
  ["blockwise indicator", "<C-v>", ["-- VISUAL BLOCK --", "-"]],
  ["a pending count shows at the right", "v2", ["-- VISUAL --", "2"]],
  ["a pending register shows at the right", "v\"a", ["-- VISUAL --", "a"]],
  ["leaving clears the indicator", "v<Esc>", ["", ""]]
]) do |keys|
  h = editor("abc\n")
  h.type(keys)
  row = h.message_row
  [row.split("  ")[0].to_s, row.empty? ? "" : row[row.length - 1, 1]]
end

h = editor("ab\n")
h.type("vp")
t.assert_equal("E353: Nothing in register \"", h.message, "p with an empty register reports E353")
h = editor("ab\n")
h.type("vl<Esc>")
t.assert_true(!h.buffer.modified?, "visual mode alone does not modify the buffer")

t.finish
