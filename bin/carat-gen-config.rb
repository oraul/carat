# Generates carat/domain/default_config.rb from config/default.json.
#
# The native binary cannot read the repository at run time, so the JSON text
# is embedded as a frozen string and parsed once at startup with Carat::Json.
# Embedding the text rather than a Ruby hash literal keeps the generated file
# trivial and avoids any question of how Spinel types a nested literal.
require_relative "../carat/domain/json"

source = "config/default.json"
target = "carat/domain/default_config.rb"

text = File.read(source)
Carat::Json.parse(text) # fail loudly on invalid JSON before writing anything

out = +""
out << "# Generated from config/default.json by bin/carat-gen-config.rb.\n"
out << "# Do not edit. Change config/default.json and run: spin run carat-gen-config\n"
out << "module Carat\n"
out << "  module Domain\n"
out << "    DEFAULT_CONFIG_JSON = <<~'JSON'.freeze\n"
text.each_line { |line| out << "      " << line }
out << "\n" unless text.end_with?("\n")
out << "    JSON\n"
out << "  end\n"
out << "end\n"

File.write(target, out)
STDOUT.puts "wrote #{target} (#{text.bytesize} bytes of JSON)"
