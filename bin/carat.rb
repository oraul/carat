# Carat entry point and composition root.
#
# The skeleton version opens a file, reports it, and quits. The editor loop,
# drivers and use cases arrive with the editor-foundation change; this file
# is where they will be constructed and injected.
require_relative "../carat"

if ARGV.length != 1
  STDERR.puts "usage: carat FILE"
  exit 1
end

path = ARGV[0]
config = Carat::Json.parse(Carat::Domain::DEFAULT_CONFIG_JSON)
lines = File.exist?(path) ? File.read(path).split("\n") : []
STDOUT.puts "carat #{Carat::VERSION}"
STDOUT.puts "#{path}: #{lines.length} lines"
STDOUT.puts "default bindings: #{config["keymaps"]["normal"].length} normal, #{config["keymaps"]["insert"].length} insert"
