require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The start screen at 24 by 80: the window's 22 text rows hold the 15 by
# 20 canvas from row 3 and column 30. Every frame, in color and plain, is
# printed into the snapshot.
module EditorStartScreenTest
  D = Carat::Domain
  TOP = 3
  LEFT = 30

  def self.files
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\n")
    files.mkdir("src")
    files
  end

  # A harness over the shipped defaults and the project lines given.
  def self.editor(text, rows, cols)
    Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(text.to_s), rows: rows, cols: cols, plugins: [])
  end

  def self.started(text)
    h = editor(text, 24, 80)
    h.open("")
    h
  end

  # The canvas rows of the screen, from its left column.
  def self.canvas(h)
    out = []
    r = TOP
    while r < TOP + D::StartArt::HEIGHT
      text = h.row(r)
      out << (text.length > LEFT ? text[LEFT, text.length - LEFT] : "")
      r += 1
    end
    out
  end

  def self.print_frame(label, h)
    puts "#{label}:"
    canvas(h).each { |line| puts "  |#{line}" }
  end

  # The cells of the canvas that hold anything but a space: [ascii,
  # normal], whether all are ASCII and all are Normal.
  def self.plain_cells(h)
    ascii = true
    normal = true
    r = TOP
    while r < TOP + D::StartArt::HEIGHT
      c = LEFT
      while c < LEFT + D::StartArt::WIDTH
        code = h.frame.code_at(r, c)
        if code != 32
          ascii = false if code >= 128
          normal = false if h.frame.hl_at(r, c) != D::Highlight::NORMAL
        end
        c += 1
      end
      r += 1
    end
    [ascii, normal]
  end

  def self.main
    t = Carat::Testing.new("editor_start_screen")

    # Every frame on the clock, 0.125 s apart.
    h = started("")
    start = h.assembly.start_screen
    print_frame("frame 0", h)
    t.assert_equal([true, 0, 0.0], [start.showing, start.step, h.clock.now], "no argument shows the first frame at once")
    t.assert_equal([D::StartArt::POINT, D::Highlight::TYPE, 1], [h.frame.code_at(7, 39), h.frame.hl_at(7, 39), canvas(h).join.strip.length], "the first frame is the point alone")
    steps = []
    times = []
    i = 1
    while i < D::StartArt::FRAMES
      h.wait
      print_frame("frame #{i}", h)
      steps << start.step
      times << h.clock.now
      i += 1
    end
    t.assert_equal([[1, 2, 3, 4, 5], [0.125, 0.25, 0.375, 0.5, 0.625]], [steps, times], "each frame comes 0.125 s after the one before, the last at 0.625 s")
    t.assert_equal(["c a r a t", "i        insert text", ":e file  open a file", ":q       quit"], [h.row(13).strip, h.row(15).strip, h.row(16).strip, h.row(17).strip], "the wordmark and the key hints under it")
    last = h.screen
    h.wait
    h.wait
    t.assert_equal([5, true, last, 1.125], [start.step, start.showing, h.screen, h.clock.now], "the last frame stays, the loop back at its idle wait")

    # The theme's groups.
    t.assert_equal([D::Highlight::TITLE, D::Highlight::TYPE, D::Highlight::OPERATOR, D::Highlight::FUNCTION, D::Highlight::KEYWORD, D::Highlight::SPECIAL, D::Highlight::COMMENT],
      [h.frame.hl_at(13, 35), h.frame.hl_at(3, 44), h.frame.hl_at(4, 36), h.frame.hl_at(6, 32), h.frame.hl_at(6, 46), h.frame.hl_at(15, 30), h.frame.hl_at(15, 39)],
      "wordmark, sparkle, table, crown, hint key, and hint text in their groups")
    t.assert_equal([D::StartArt::SPARKLE, 0x2588, 0x25E2], [h.frame.code_at(3, 44), h.frame.code_at(4, 36), h.frame.code_at(4, 35)], "the sparkle, a facet, and an edge")
    art = D::StartArt.build(false)
    wide = []
    art.codes.each { |code| wide << code if code != 0 && D::DisplayWidth.of(code) != 1 }
    t.assert_equal([], wide, "every glyph takes one cell")
    plain = D::StartArt.build(true)
    t.assert_equal([D::StartArt::FRAMES * D::StartArt::HEIGHT * D::StartArt::WIDTH, 9], [plain.codes.length, plain.mark_codes.length], "six frames of the canvas and the wordmark, computed once")

    # The status line and the message row stay as they are.
    off = editor("option.startscreen false\n", 24, 80)
    off.open("")
    t.assert_equal([off.row(22), off.row(23)], [h.row(22), h.row(23)], "the status line and the message row are the editor's")

    # Any key ends the screen and is handled.
    h = started("")
    h.wait
    h.type("i")
    off = editor("option.startscreen false\n", 24, 80)
    off.open("")
    off.type("i")
    t.assert_equal([false, :insert, off.screen], [h.assembly.start_screen.showing, h.mode, h.screen], "a key during the animation ends it, enters insert mode, and the window shows the buffer")
    clock = h.clock.now
    h.wait
    t.assert_equal(0.25, h.clock.now - clock, "with the screen gone the loop waits its idle time")
    h = started("")
    6.times { h.wait }
    h.type(":")
    t.assert_equal([false, ":"], [h.assembly.start_screen.showing, h.row(23)], "a key after the animation ends it and reaches the command line")
    h.type("<Esc>")
    t.assert_equal(["  1", "~"], [h.row(0), h.row(1)], "the window is drawn in full after the screen")

    # The options.
    off = editor("option.startscreen false\n", 24, 80)
    off.open("")
    t.assert_equal([false, "  1", "~", ""], [off.assembly.start_screen.showing, off.row(0), off.row(1), off.message], "startscreen false starts on the empty buffer")
    h = started("option.reducedmotion true\n")
    reduced = h.screen
    h = started("")
    5.times { h.wait }
    t.assert_equal(h.screen, reduced, "reducedmotion shows the last frame at once")
    h = started("option.reducedmotion true\n")
    clock = h.clock.now
    h.wait
    t.assert_equal([5, 0.25], [h.assembly.start_screen.step, h.clock.now - clock], "with reducedmotion the clock brings no other frame")

    # NO_COLOR.
    h = editor("", 24, 80)
    h.terminal.no_color = true
    h.open("")
    print_frame("plain frame 0", h)
    i = 1
    while i < D::StartArt::FRAMES
      h.wait
      print_frame("plain frame #{i}", h)
      i += 1
    end
    t.assert_equal([true, true], plain_cells(h), "NO_COLOR draws ASCII glyphs in the Normal group")
    t.assert_equal("c a r a t", h.row(13).strip, "the plain wordmark")

    # A small window: the wordmark alone, cut at the edge.
    h = editor("", 10, 40)
    h.open("")
    t.assert_equal(["", "", "", "               c a r a t", "", "", "", ""], h.screen[0, 8], "a 10 by 40 terminal shows only the wordmark on the window's middle row")
    h.wait
    t.assert_equal("               c a r a t", h.row(3), "every frame shows it")
    h.resize(24, 80)
    4.times { h.wait }
    t.assert_equal(["c a r a t", D::StartArt::SPARKLE], [h.row(13).strip, h.frame.code_at(3, 44)], "a larger terminal shows the picture again")
    h = editor("", 24, 6)
    h.open("")
    t.assert_equal("c a r", h.row(10), "a narrow window cuts the wordmark")

    # The argument.
    h = editor("", 24, 80)
    h.open("src")
    t.assert_equal([true, "", ""], [h.assembly.start_screen.showing, h.buffer.path_text, h.message], "a directory shows the start screen over an empty buffer")
    h = editor("option.startscreen false\n", 24, 80)
    h.open("src")
    t.assert_equal([false, true], [h.assembly.start_screen.showing, h.message.include?("is a directory")], "with startscreen off a directory is refused as before")
    h = editor("", 24, 80)
    h.open("a.txt")
    t.assert_equal([false, "  1 one"], [h.assembly.start_screen.showing, h.row(0)], "a file shows no start screen")

    t.finish
  end
end

EditorStartScreenTest.main if __FILE__ == $0
