require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainMessagesTest
  D = Carat::Domain
  H = D::MessageHistory

  # A history after showing each text, an "E" first meaning an error,
  # read back as "level:text" lines.
  def self.kept(texts)
    history = H.new
    list = texts.to_a
    i = 0
    while i < list.length
      text = list[i].to_s
      history.add(text, text.start_with?("E") ? H::ERROR : H::INFO)
      i += 1
    end
    out = []
    i = 0
    while i < history.count
      out << "#{history.level_at(i)}:#{history.text_at(i)}"
      i += 1
    end
    out
  end

  # Notices added at time 0 with the levels given, then expired at each
  # time; answers the texts left after each.
  def self.left(levels, times)
    notices = D::Notices.new(history: H.new)
    list = levels.to_a
    i = 0
    while i < list.length
      notices.add("n#{i}", list[i].to_i, 0.0)
      i += 1
    end
    out = []
    steps = times.to_a
    i = 0
    while i < steps.length
      notices.expire(steps[i].to_s.to_f)
      out << texts_of(notices)
      i += 1
    end
    out
  end

  def self.texts_of(notices)
    words = []
    i = 0
    while i < notices.count
      words << notices.text_at(i)
      i += 1
    end
    words.join(",")
  end

  def self.main
    t = Carat::Testing.new("domain_messages")

    # Rows are [label, texts shown, history kept].
    t.table([
      ["one-line texts in order with their levels", ["saved", "E37: No write"], ["0:saved", "2:E37: No write"]],
      ["an empty text is not kept", ["", "x"], ["0:x"]],
      ["a listing is not kept", ["a\nb", "y"], ["0:y"]],
      ["nothing shown, nothing kept", [], []]
    ]) do |texts|
      kept(texts)
    end

    history = H.new
    i = 0
    while i < 501
      history.add("m#{i}", H::INFO)
      i += 1
    end
    t.assert_equal([500, "m1", "m500"], [history.count, history.text_at(0), history.text_at(499)], "past 500 the oldest is dropped")
    history.clear
    t.assert_equal([0, ""], [history.count, history.to_s], "clear empties the history")

    state = D::EditorState.new(tabs: D::TabList.new(window: D::Window.new(buffer: D::Buffer.from_text("", nil))), options: D::Options.new)
    state.show("E492: Not an editor command: foo", true)
    state.show_output("listing")
    state.show("info", false)
    t.assert_equal(["E492: Not an editor command: foo\ninfo", "info"], [state.history.to_s, state.message], "show keeps a message, show_output does not")

    # Rows are [label, [levels added at 0, times expired at], texts left].
    t.table([
      ["info leaves at 3, warning at 5, error at 8", [[0, 1, 2], ["2.9", "3.0", "5.0", "7.9", "8.0"]], ["n0,n1,n2", "n1,n2", "n2", "n2", ""]],
      ["a fourth replaces the oldest", [[2, 2, 2, 2], ["0.0"]], ["n1,n2,n3"]],
      ["a level out of range is info", [[7], ["2.9", "3.0"]], ["n0", ""]]
    ]) do |input|
      left(input[0], input[1])
    end

    notices = D::Notices.new(history: H.new)
    t.assert_equal(8.0, notices.wait(1.0), "with none shown the wait is the longest lifetime")
    notices.add("w", H::WARNING, 1.0)
    notices.add("i", H::INFO, 2.0)
    t.assert_equal([4.0, 0.0, "w\ni", [1, 2]], [notices.wait(1.0), notices.wait(9.0), notices.history.to_s, [notices.serial_at(0), notices.serial_at(1)]], "the wait to the next deadline, each notice kept in the history with a serial")
    t.assert_equal([true, false], [notices.expire(5.0), notices.expire(5.0)], "expire answers whether one went")

    t.finish
  end
end

DomainMessagesTest.main if __FILE__ == $0
