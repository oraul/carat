# Key latency benchmark: the whole editor over the test doubles with a
# terminal that counts the bytes written and throws them away, at 60 rows
# and 200 columns. Each scenario opens a generated file, moves to its
# starting point, draws a frame, and then types its keys again and again,
# timing key handling (the input controller, as MainLoop pumps it) and
# rendering (EditorAssembly#render) of every key. One line per scenario:
#
#   name lines keys handle_us render_us total_us worst_us@key bytes_per_key gc_percent gc_runs retained open_us tokenized
#
# open_us is the time to open the file and draw the first frame, and
# tokenized the lines the syntax highlighter tokenized per typed key,
# both meaningful for the ruby scenarios, whose plugin is the ruby plugin
# on a generated Ruby file.
#
# retained, measured by the memory scenarios only (0 for the others), is
# the growth of the live heap over the typed keys, in bytes, read from
# Spinel's GC.stat after a collection before and after them: the memory
# the keys left behind, such as undo states. It is exact only when every
# collection is full (SPINEL_GC_MINOR=0), as bench/run.sh runs the
# memory scenarios; otherwise a minor collection leaves old garbage in
# the count.
#
# Usage: keys SCENARIO [KEYS [LINES]]. SCENARIO is one of the names in
# SCENARIOS below or "all"; KEYS overrides the number of keys typed and
# LINES the size of the file. bench/run.sh adds allocations per key with
# Spinel's SPINEL_ALLOC_REPORT and is what make bench runs.
require_relative "../carat/test_support"

# A terminal that keeps nothing: a scripted key queue and a byte count.
class NullTerminal < Carat::Ports::TerminalPort
  attr_reader :bytes #: Integer

  # @rbs @clock: Carat::Doubles::ManualClock
  # @rbs @rows: Integer
  # @rbs @cols: Integer
  # @rbs @queue: Array[String]

  #: (clock: Carat::Doubles::ManualClock, rows: Integer, cols: Integer) -> void
  def initialize(clock:, rows:, cols:)
    @clock = clock
    @rows = rows
    @cols = cols
    @queue = []
    @bytes = 0
  end

  #: (String) -> void
  def push(bytes)
    @queue << bytes
  end

  # @rbs skip
  def size
    [@rows, @cols]
  end

  # @rbs timeout: Float
  def read_key(timeout)
    if @queue.empty?
      @clock.advance(timeout)
      return nil
    end
    @queue.shift
  end

  #: (String) -> void
  def write(bytes)
    @bytes += bytes.bytesize
  end

  # @rbs skip
  def colors
    256
  end

  # @rbs skip
  def no_color?
    false
  end

  #: () -> void
  def enter
  end

  #: () -> void
  def leave
  end

  #: () -> void
  def reset
    @bytes = 0
  end
end

ROWS = 60
COLS = 200

# name, keys typed in a loop, default key count, default lines, setup keys
# (with N for the middle line number, H for a heredoc body line near the
# middle, S for the middle line of a multi-line string near it), text
# kind, plugins ("none", "explorer" opened in a side window, "ruby",
# the ruby plugin alone, "float", no plugin and a 60 by 15 bordered
# float over the middle of the window, or "finder", the finder alone over
# FINDER_FILES files, which every key typed into it filters)
SCENARIOS = [
  ["lh", "lh", 10_000, 10_000, "NG", "code", "none"],
  ["j", "j", 9_000, 10_000, "gg", "code", "none"],
  ["insert", "x<BS>", 10_000, 10_000, "NGA", "code", "none"],
  ["w", "w", 10_000, 10_000, "NG", "code", "none"],
  ["ddp", "ddP", 3_000, 100_000, "NG", "code", "none"],
  ["lh-utf8", "lh", 10_000, 10_000, "NG", "utf8", "none"],
  ["j-utf8", "j", 9_000, 10_000, "gg", "utf8", "none"],
  ["long-ascii", "hl", 2_000, 500, "NG$", "long-ascii", "none"],
  ["long-utf8", "hl", 2_000, 500, "NG$", "long-utf8", "none"],
  ["lh-explorer", "lh", 10_000, 10_000, "NG", "code", "explorer"],
  ["lh-float", "lh", 10_000, 10_000, "NG", "code", "float"],
  ["lh-winbar", "lh", 10_000, 10_000, "<C-w>vNG", "code", "none"],
  ["j-explorer", "j", 9_000, 10_000, "gg", "code", "explorer"],
  ["undo", "u<C-r>", 4_000, 100_000, "NGx", "code", "none"],
  ["undo-line", "u<C-r>", 4_000, 100_000, "NGdd", "code", "none"],
  ["r", "rx", 6_000, 10_000, "NG", "code", "none"],
  ["dot-r", ".", 3_000, 10_000, "NGrx", "code", "none"],
  ["dd", "dd", 3_000, 100_000, "NG", "code", "none"],
  ["dot-dd", ".", 1_500, 100_000, "NGdd", "code", "none"],
  ["ciw", "ciwfoo<Esc>", 7_000, 10_000, "NG", "code", "none"],
  ["dot-ciw", ".", 1_000, 10_000, "NGciwfoo<Esc>", "code", "none"],
  ["memory", "rxj", 3_000, 100_000, "gg", "code", "none"],
  ["memory-10k", "rxj", 3_000, 10_000, "gg", "code", "none"],
  ["lh-ruby", "lh", 10_000, 10_000, "NG", "ruby", "ruby"],
  ["j-ruby", "j", 9_000, 10_000, "gg", "ruby", "ruby"],
  ["insert-ruby", "x<BS>", 10_000, 10_000, "NGA", "ruby", "ruby"],
  ["heredoc-ruby", "x<BS>", 10_000, 10_000, "HGA", "ruby", "ruby"],
  ["string-ruby", "x<BS>", 10_000, 10_000, "SGA", "ruby", "ruby"],
  ["quote-ruby", "\"<BS>", 2_000, 10_000, "NG4jI", "ruby", "ruby"],
  ["open-plain", "l", 10, 100_000, "gg", "ruby", "none"],
  ["open-ruby", "l", 10, 100_000, "gg", "ruby", "ruby"],
  ["G-ruby", "Ggg", 300, 100_000, "gg", "ruby", "ruby"],
  ["n", "n", 3_000, 100_000, "gg/0 end<CR>", "code", "none"],
  ["finder", "f<BS>", 2_000, 1_000, " ffd", "code", "finder"]
]
FINDER_FILES = 10_000

# One block of the generated Ruby source, BLOCK lines with the block
# number for {n}: a comment with a Todo, a module, a class, a constant in
# hexadecimal, a method with interpolation, a squiggly heredoc with
# interpolation, a multi-line string, %w[], a regular expression, a
# symbol, instance and global variables, and a float.
RUBY_BLOCK = [
  "# Section {n}: helpers for the report. TODO: split",
  "module Report{n}",
  "  class Row{n} < Base",
  "    LIMIT = 0x1F_FF",
  "    def render(arg, other = nil)",
  "      name = \"row \#{arg} of \#{other.inspect}\"",
  "      sql = <<~SQL",
  "        SELECT * FROM rows_{n} WHERE id = \#{arg}",
  "        AND kind = 'plain'",
  "      SQL",
  "      note = \"first line of a note",
  "        continued \#{name} here",
  "        and ends here\"",
  "      list = %w[alpha beta gamma]",
  "      return :done if sql =~ /select\\s+\\*/i",
  "      @count += 1.5e3 / 2",
  "      $stderr.puts 'single quoted \\' text'",
  "    end",
  "  end",
  "end"
]
BLOCK = 20
HEREDOC_ROW = 8
STRING_ROW = 11

#: () -> Float
def now
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

# The text of the file: lines of code, the same with accented letters
# and Japanese comments, or short lines with one line of 10,000
# characters in the middle, ASCII or starting with one accented letter.
#: (Integer, String) -> String
def text_of(lines, kind)
  out = []
  i = 0
  while i < lines
    if kind == "long-ascii" || kind == "long-utf8"
      if i == lines / 2
        out << (kind == "long-utf8" ? "é" : "a") + "a" * 9_999
      else
        out << "short line #{i}"
      end
    elsif kind == "ruby"
      out << RUBY_BLOCK[i % BLOCK].gsub("{n}", (i / BLOCK).to_s)
    elsif kind == "utf8"
      out << "    def méthode_#{i}(arg, other) # 日本語のコメント #{i} end"
    else
      out << "    def method_#{i}(arg, other) # some comment text here #{i} end"
    end
    i += 1
  end
  out.join("\n") + "\n"
end

#: (String) -> Array[String]
def encode(notation)
  codes = Carat::Domain::KeyNotation.parse(notation, "").codes
  out = []
  i = 0
  while i < codes.length
    out << Carat::Adapters::KeyDecoder.encode(codes[i])
    i += 1
  end
  out
end

#: (Carat::Adapters::EditorAssembly, NullTerminal, String) -> void
def press(assembly, terminal, bytes)
  terminal.push(bytes)
  assembly.controller.pump(assembly.state)
  assembly.controller.pump(assembly.state) while assembly.controller.decoder.pending?
end

#: (Array[untyped], Integer, Integer) -> void
def run(scenario, count, size)
  name = scenario[0].to_s
  keys = scenario[1].to_s
  setup = scenario[4].to_s
  kind = scenario[5].to_s
  plugins = scenario[6].to_s
  lines = size > 0 ? size : scenario[3].to_i
  total = count > 0 ? count : scenario[2].to_i

  files = Carat::Doubles::MemoryFiles.new
  files.put("a.rb", text_of(lines, kind))
  clock = Carat::Doubles::ManualClock.new
  terminal = NullTerminal.new(clock: clock, rows: ROWS, cols: COLS)
  list = []
  list = Carat::Plugins::Registry.all if plugins == "explorer"
  list << Carat::Plugins::Ruby::Plugin.new if plugins == "ruby"
  list << Carat::Plugins::Finder::Plugin.new if plugins == "finder"
  if plugins == "finder"
    f = 0
    while f < FINDER_FILES
      files.put("d#{f / 100}/f#{f}.rb", "x = #{f}\n")
      f += 1
    end
  end
  assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.defaults), processes: Carat::Doubles::FakeProcesses.new, messages: Carat::Doubles::MemoryQueue.new, completions: Carat::Adapters::ServerCompletions.new, plugin_list: list)
  assembly.screen_presenter.enter
  opened = now
  assembly.open("a.rb")
  assembly.render(ROWS, COLS)
  open_time = now - opened
  if plugins == "explorer"
    opening = encode(" e<C-w>l")
    i = 0
    while i < opening.length
      press(assembly, terminal, opening[i])
      assembly.render(ROWS, COLS)
      i += 1
    end
  end
  if plugins == "float"
    rows = []
    r = 0
    while r < 15
      rows << "float row #{r} " + "x" * 40
      r += 1
    end
    spec = Carat::Domain::FloatSpec.new(anchor: "editor", row: 20, col: 70, height: 15, width: 60, border: true, title: "bench", z: 50)
    float = Carat::Domain::FloatWindow.new(window: Carat::Domain::Window.new(buffer: Carat::Domain::Buffer.new(lines: rows, path: nil, line_ending: "\n")), spec: spec)
    assembly.open_float.call(assembly.state, float, false)
    assembly.render(ROWS, COLS)
  end
  middle = lines / 2 / BLOCK * BLOCK
  prelude = encode(setup.sub("N", (lines / 2 + 1).to_s).sub("H", (middle + HEREDOC_ROW + 1).to_s).sub("S", (middle + STRING_ROW + 1).to_s))
  i = 0
  while i < prelude.length
    press(assembly, terminal, prelude[i])
    assembly.render(ROWS, COLS)
    i += 1
  end
  terminal.reset

  typed = encode(keys)
  measured = name.start_with?("memory")
  live_before = 0
  if measured
    GC.start
    live_before = GC.stat("bytes")
  end
  tokenized_before = assembly.highlight_view.tokenized
  handle = 0.0
  render = 0.0
  worst = 0.0
  worst_at = 0
  gc_before = GC.total_time
  runs_before = GC.stat("cycle")
  started = now
  done = 0
  while done < total
    a = now
    press(assembly, terminal, typed[done % typed.length])
    b = now
    assembly.render(ROWS, COLS)
    c = now
    handle += b - a
    render += c - b
    if c - a > worst
      worst = c - a
      worst_at = done
    end
    done += 1
  end
  wall = now - started
  tokenized = assembly.highlight_view.tokenized - tokenized_before
  gc = (GC.total_time - gc_before) / 1_000_000_000.0
  runs = GC.stat("cycle") - runs_before
  retained = 0
  if measured
    GC.start
    retained = GC.stat("bytes") - live_before
  end
  us = 1_000_000.0
  printf("%-12s lines=%-7d keys=%-6d handle=%7.1fus render=%7.1fus total=%7.1fus worst=%8.1fus@%-5d bytes=%-7d gc=%5.2f%% gc_runs=%d retained=%d open=%.1fus tokenized=%.2f\n",
    name, lines, total, handle * us / total, render * us / total, (handle + render) * us / total,
    worst * us, worst_at, terminal.bytes / total, wall > 0.0 ? gc * 100.0 / wall : 0.0, runs, retained,
    open_time * us, tokenized * 1.0 / total)
end

which = ARGV.length > 0 ? ARGV[0] : "all"
count = ARGV.length > 1 ? ARGV[1].to_i : 0
size = ARGV.length > 2 ? ARGV[2].to_i : 0
found = false
i = 0
while i < SCENARIOS.length
  scenario = SCENARIOS[i]
  if which == "all" || which == scenario[0].to_s
    run(scenario, count, size)
    found = true
  end
  i += 1
end
unless found
  STDERR.puts "unknown scenario #{which}"
  exit 2
end
