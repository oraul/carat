# Carat entry point and composition root: the only place drivers are
# constructed and the only place the plugin registry is read. Argument
# checks and the terminal check happen before anything touches the
# terminal; signals are trapped before the loop starts; the raw block holds
# a single call; the screen is restored in an ensure.
require "io/console"
require_relative "../carat"

if ARGV.length != 1
  STDERR.puts "usage: carat FILE"
  exit 1
end

unless STDIN.tty?
  STDERR.puts "carat: standard input is not a terminal"
  exit 1
end

path = ARGV[0]
signals = Carat::Drivers::Signals.new
signals.install

terminal = Carat::Drivers::AnsiTerminal.new(input: STDIN, output: STDOUT)
clock = Carat::Drivers::MonotonicClock.new
files = Carat::Drivers::DiskFiles.new
config = Carat::Adapters::JsonConfigGateway.new
assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: config, plugin_list: Carat::Plugins::Registry.all)
main_loop = Carat::Drivers::MainLoop.new(assembly: assembly, terminal: terminal, signals: signals)

assembly.screen_presenter.enter
assembly.open(path)
begin
  STDIN.raw { |io| main_loop.run }
ensure
  assembly.screen_presenter.leave
end
