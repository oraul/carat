require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorMessagesTest
  D = Carat::Domain
  H = D::Highlight

  def self.editor(plain)
    files = Carat::Doubles::MemoryFiles.new
    text = +""
    i = 1
    while i <= 30
      text << "line #{i} of the file\n"
      i += 1
    end
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.default(files, 12, 60)
    h.terminal.no_color = plain
    h.open("a.txt")
    h.state.history.clear
    h
  end

  # The message row after typing keys into a fresh editor.
  def self.after(keys)
    h = editor(false)
    h.type(keys.to_s)
    h.message_row.strip
  end

  # The lines of the listing above the message row after typing keys.
  def self.listed(keys)
    h = editor(false)
    h.type(keys.to_s)
    out = []
    r = 0
    while r < 12
      row = h.row(r)
      out << row.strip if row.start_with?("E") || row.start_with?("Press")
      r += 1
    end
    out
  end

  def self.notify(h, text, level)
    h.assembly.notices.add(text.to_s, level.to_i, h.clock.now)
    h.redraw
  end

  # The count of rows of 0 to 10 holding a box's top corner.
  def self.boxes(h, corner)
    count = 0
    r = 0
    while r < 11
      count += 1 if h.frame.code_at(r, 58) == corner.to_i
      r += 1
    end
    count
  end

  def self.main
    t = Carat::Testing.new("editor_messages")

    # Rows are [label, keys, message row].
    t.table([
      ["an error is kept after the next key", ":foo<CR>l:messages<CR>", "E492: Not an editor command: foo"],
      ["the abbreviation", ":foo<CR>l:mes<CR>", "E492: Not an editor command: foo"],
      ["a listing is not kept", ":registers<CR><CR>:messages<CR>", ""],
      ["no history shows nothing", ":messages<CR>", ""],
      ["clear empties the history", ":foo<CR>:messages clear<CR>:messages<CR>", ""],
      ["another argument is refused", ":messages all<CR>", "E474: Invalid argument"],
      ["the output of :messages is not kept", ":foo<CR>:messages<CR>:messages<CR>", "E492: Not an editor command: foo"]
    ]) do |keys|
      after(keys)
    end

    t.assert_equal(["E492: Not an editor command: foo", "E492: Not an editor command: bar", "Press ENTER or type command to continue"], listed(":foo<CR>:bar<CR>:mes<CR>"), "several entries are listed in order with the hit-enter prompt")
    h = editor(false)
    h.type(":messages all<CR>")
    t.assert_equal(H::MESSAGE_ERROR, h.frame.hl_at(11, 0), "the refusal is an error")

    # A warning at the top right of a 60-column screen.
    h = editor(false)
    notify(h, "disk almost full", D::MessageHistory::WARNING)
    t.assert_equal(["╭Warning───────────╮", "│ disk almost full │", "╰──────────────────╯"], [h.row(0)[39, 20], h.row(1)[39, 20], h.row(2)[39, 20]], "a warning box ends one column before the right edge")
    t.assert_equal([59, "line 2 of the fi"], [h.row(1).rstrip.length, h.row(1)[4, 16]], "the last column and the window beside the box are kept")
    t.assert_equal([H::FLOAT_BORDER, H::DIAGNOSTIC_WARN, H::NORMAL_FLOAT], [h.frame.hl_at(0, 39), h.frame.hl_at(0, 40), h.frame.hl_at(1, 41)], "the border, the title in its severity's group, the text in NormalFloat")
    t.assert_equal(0, h.state.history.to_s.index("disk almost full"), "a notification is kept in the history")

    # Keys go on under a notification, and the screen equals a full repaint.
    h.type("jjlh")
    t.assert_equal([2, 0, "│ disk almost full │"], [h.cursor[0], h.cursor[1], h.row(1)[39, 20]], "keys move the cursor and the box stays")
    h.type("<C-e><C-e>")
    t.assert_equal("│ disk almost full │", h.row(1)[39, 20], "a scroll under the box keeps it drawn")

    # Expiry by severity.
    h = editor(false)
    notify(h, "an info", D::MessageHistory::INFO)
    notify(h, "a warning", D::MessageHistory::WARNING)
    notify(h, "an error", D::MessageHistory::ERROR)
    counts = [boxes(h, 0x256E)]
    h.clock.advance(4.0)
    h.wait
    counts << boxes(h, 0x256E)
    h.clock.advance(1.75)
    h.wait
    counts << boxes(h, 0x256E)
    h.clock.advance(2.75)
    h.wait
    counts << boxes(h, 0x256E)
    t.assert_equal([3, 2, 1, 0], counts, "three boxes, two after 4 seconds, one after 6, none after 9")
    t.assert_equal("line 1 of the file", h.row(0)[4, 18], "the rows under a box that left show the window again")

    h = editor(false)
    i = 1
    while i <= 4
      notify(h, "note #{i}", D::MessageHistory::INFO)
      i += 1
    end
    t.assert_equal([3, false, true], [boxes(h, 0x256E), h.screen.join("\n").include?("note 1"), h.screen.join("\n").include?("note 4")], "a fourth replaces the oldest")

    # Plain under NO_COLOR.
    h = editor(true)
    notify(h, "bundle failed", D::MessageHistory::ERROR)
    t.assert_equal(["+Error----------+", "| bundle failed |", "+---------------+"], [h.row(0)[42, 17], h.row(1)[42, 17], h.row(2)[42, 17]], "a plain box in ASCII, as wide as its text")
    t.assert_equal([H::NORMAL, H::NORMAL, H::NORMAL], [h.frame.hl_at(0, 42), h.frame.hl_at(0, 43), h.frame.hl_at(1, 44)], "a plain box is all in Normal")

    t.finish
  end
end

EditorMessagesTest.main if __FILE__ == $0
