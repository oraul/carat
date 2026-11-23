require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# FloatPainter on its own, without the frame presenter: the boxes it keys,
# the rows it paints for a float and a notification, plain and not, and
# the rows it leaves when only some were painted again. The whole frames
# with floats and notifications are test/editor_floats.rb and
# test/editor_messages.rb.
module AdaptersFloatPainterTest
  D = Carat::Domain
  H = D::Highlight
  ROWS = 8
  COLS = 30

  # A float painter, the floats it paints, and a frame to paint on.
  class Setup
    attr_reader :painter #: Carat::Adapters::FloatPainter
    attr_reader :floats #: Carat::Domain::FloatLayer
    attr_reader :frame #: Carat::Domain::Frame

    def initialize(painter:, floats:, frame:)
      @painter = painter
      @floats = floats
      @frame = frame
    end
  end

  # A painter with a bordered float titled T over two lines when float,
  # and a notification when notice, plain when asked, under the default
  # options with the icons of the icon set given.
  def self.setup(float, notice, plain, icons)
    notices = D::Notices.new(message_history: D::MessageHistory.new)
    notices.add("saved", D::MessageHistory::WARNING, 0.0) if notice
    painter = Carat::Adapters::FloatPainter.new(cache: D::LineCache.new, notices: notices)
    painter.plain = plain
    options = D::Options.new
    options.icons = icons.to_s
    painter.configure(options)
    floats = D::FloatLayer.new
    if float
      spec = D::FloatSpec.new(anchor: "editor", row: 3, col: 1, height: 2, width: 8, border: true, title: "T", z: 50)
      window = D::Window.new(buffer: D::Buffer.new(lines: ["one", "two"], path: nil, line_ending: "\n"))
      box = D::FloatWindow.new(window: window, spec: spec)
      box.place(0, 0, ROWS, COLS, true)
      floats.add(box, false)
    end
    Setup.new(painter: painter, floats: floats, frame: D::Frame.new(rows: ROWS, cols: COLS))
  end

  # The rows a setup paints in full, joined by "/".
  def self.painted(s)
    s.painter.build_key(s.floats, ROWS, COLS, 0)
    s.painter.paint(s.frame, s.floats, Array.new(ROWS, 1), 8, ROWS, COLS, true)
    s.frame.text_rows.join("/")
  end

  # The rows a case paints.
  def self.case_rows(name)
    case name.to_s
    when "float" then painted(setup(true, false, false, "unicode"))
    when "notice" then painted(setup(false, true, false, "unicode"))
    when "plain" then painted(setup(false, true, true, "unicode"))
    when "ascii" then painted(setup(true, false, false, "ascii"))
    when "both" then painted(setup(true, true, false, "unicode"))
    else "unknown case #{name}"
    end
  end

  # The key of a float and a notification: STRIDE integers a box.
  def self.key_of
    s = setup(true, true, false, "unicode")
    s.painter.build_key(s.floats, ROWS, COLS, 0)
    out = []
    s.painter.key.each { |v| out << v }
    out
  end

  # With full off only the rows marked in repainted are painted.
  def self.partial_rows
    s = setup(true, false, false, "unicode")
    s.painter.build_key(s.floats, ROWS, COLS, 0)
    repainted = Array.new(ROWS, 0)
    repainted[4] = 1
    s.painter.paint(s.frame, s.floats, repainted, 8, ROWS, COLS, false)
    s.frame.text_rows.join("/")
  end

  # The groups of a case's border corner, title, and text cells, at the
  # cells given as row and column pairs.
  def self.groups(name, cells)
    kind = name.to_s
    float = kind == "float"
    s = setup(float, !float, kind == "plain", "unicode")
    painted(s)
    out = []
    i = 0
    while i + 1 < cells.length
      out << s.frame.hl_at(cells[i].to_i, cells[i + 1].to_i)
      i += 2
    end
    out
  end

  def self.main
    t = Carat::Testing.new("adapters_float_painter")

    # Rows are [label, case, the rows painted joined by "/"].
    t.table([
      ["a bordered float with its title, its padding, and its text", "float", "/// ╭─── T ────╮/ │ one      │/ │ two      │/ ╰──────────╯/"],
      ["a notification at the top right with its severity as the title", "notice", "         ╭──── Warning ─────╮/         │ saved            │/         ╰──────────────────╯/////"],
      ["a plain notification in ASCII", "plain", "         +---- Warning -----+/         | saved            |/         +------------------+/////"],
      ["a float under option.icons ascii in ASCII", "ascii", "/// +--- T ----+/ | one      |/ | two      |/ +----------+/"],
      ["a float and a notification together", "both", "         ╭──── Warning ─────╮/         │ saved            │/         ╰──────────────────╯/ ╭─── T ────╮/ │ one      │/ │ two      │/ ╰──────────╯/"]
    ]) { |name| case_rows(name) }

    t.assert_equal([3, 7, 1, 13, 0, 0, 0, 0, 0, -1, 0, 0, 3, 9, 29, 1, 1, 0, 0, 0, -1, 0], key_of, "the key: the float's box, then the notification's")
    t.assert_equal("//// │ one      │///", partial_rows, "with full off only a row painted again is painted")
    t.assert_equal([H::FLOAT_BORDER, H::FLOAT_TITLE, H::NORMAL_FLOAT], groups("float", [3, 1, 3, 5, 4, 3]), "a float's corner in FloatBorder, its title in FloatTitle, its text in NormalFloat")
    t.assert_equal([H::FLOAT_BORDER, H::DIAGNOSTIC_WARN, H::NORMAL_FLOAT], groups("notice", [0, 9, 0, 18, 1, 11]), "a notification's corner in FloatBorder, its title in DiagnosticWarn, its text in NormalFloat")
    t.assert_equal([H::NORMAL, H::NORMAL, H::NORMAL], groups("plain", [0, 9, 0, 18, 1, 11]), "a plain notification all in Normal")
    t.assert_equal([false, true, true], [setup(false, false, false, "unicode").painter.boxes?(D::FloatLayer.new), setup(false, true, false, "unicode").painter.boxes?(D::FloatLayer.new), setup(true, false, false, "unicode").painter.boxes?(setup(true, false, false, "unicode").floats)], "boxes? with no float and no notification, with a notification, with a float")

    t.finish
  end
end

AdaptersFloatPainterTest.main if __FILE__ == $0
