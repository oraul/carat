# Key latency benchmark: the whole editor over the test doubles with a
# terminal that counts the bytes written and throws them away, at 60 rows
# and 200 columns. Each scenario opens a generated file, moves to its
# starting point, draws a frame, and then types its keys again and again,
# timing key handling (the input controller, as MainLoop pumps it) and
# rendering (EditorAssembly#render) of every key. One line per scenario:
#
#   name lines keys handle_us render_us total_us worst_us@key bytes_per_key gc_percent gc_runs retained
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
# (with N for the middle line number), text kind, plugins
SCENARIOS = [
  ["lh", "lh", 10_000, 10_000, "NG", "code", false],
  ["j", "j", 9_000, 10_000, "gg", "code", false],
  ["insert", "x<BS>", 10_000, 10_000, "NGA", "code", false],
  ["w", "w", 10_000, 10_000, "NG", "code", false],
  ["ddp", "ddP", 3_000, 100_000, "NG", "code", false],
  ["lh-utf8", "lh", 10_000, 10_000, "NG", "utf8", false],
  ["j-utf8", "j", 9_000, 10_000, "gg", "utf8", false],
  ["long-ascii", "hl", 2_000, 500, "NG$", "long-ascii", false],
  ["long-utf8", "hl", 2_000, 500, "NG$", "long-utf8", false],
  ["lh-explorer", "lh", 10_000, 10_000, "NG", "code", true],
  ["j-explorer", "j", 9_000, 10_000, "gg", "code", true],
  ["undo", "u<C-r>", 4_000, 100_000, "NGx", "code", false],
  ["undo-line", "u<C-r>", 4_000, 100_000, "NGdd", "code", false],
  ["r", "rx", 6_000, 10_000, "NG", "code", false],
  ["dot-r", ".", 3_000, 10_000, "NGrx", "code", false],
  ["dd", "dd", 3_000, 100_000, "NG", "code", false],
  ["dot-dd", ".", 1_500, 100_000, "NGdd", "code", false],
  ["ciw", "ciwfoo<Esc>", 7_000, 10_000, "NG", "code", false],
  ["dot-ciw", ".", 1_000, 10_000, "NGciwfoo<Esc>", "code", false],
  ["memory", "rxj", 3_000, 100_000, "gg", "code", false],
  ["memory-10k", "rxj", 3_000, 10_000, "gg", "code", false]
]

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
  plugins = scenario[6] == true
  lines = size > 0 ? size : scenario[3].to_i
  total = count > 0 ? count : scenario[2].to_i

  files = Carat::Doubles::MemoryFiles.new
  files.put("a.rb", text_of(lines, kind))
  clock = Carat::Doubles::ManualClock.new
  terminal = NullTerminal.new(clock: clock, rows: ROWS, cols: COLS)
  list = plugins ? Carat::Plugins::Registry.all : []
  assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.defaults), plugin_list: list)
  assembly.screen_presenter.enter
  assembly.open("a.rb")
  assembly.render(ROWS, COLS)
  if plugins
    opening = encode(" e<C-w>l")
    i = 0
    while i < opening.length
      press(assembly, terminal, opening[i])
      assembly.render(ROWS, COLS)
      i += 1
    end
  end
  prelude = encode(setup.sub("N", (lines / 2 + 1).to_s))
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
  gc = (GC.total_time - gc_before) / 1_000_000_000.0
  runs = GC.stat("cycle") - runs_before
  retained = 0
  if measured
    GC.start
    retained = GC.stat("bytes") - live_before
  end
  us = 1_000_000.0
  printf("%-12s lines=%-7d keys=%-6d handle=%7.1fus render=%7.1fus total=%7.1fus worst=%8.1fus@%-5d bytes=%-7d gc=%5.2f%% gc_runs=%d retained=%d\n",
    name, lines, total, handle * us / total, render * us / total, (handle + render) * us / total,
    worst * us, worst_at, terminal.bytes / total, wall > 0.0 ? gc * 100.0 / wall : 0.0, runs, retained)
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
