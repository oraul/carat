# Generates carat/domain/default_config.rb from config/default.json and
# carat/plugins/registry.rb from config/plugins.json.
#
# The native binary cannot read the repository at run time, so the JSON text
# is embedded as a frozen string and parsed once at startup with Carat::Json.
# Embedding the text rather than a Ruby hash literal keeps the generated file
# trivial and avoids any question of how Spinel types a nested literal. The
# registry is explicit Ruby, one require and one constructor per plugin, so
# the compiler sees a fixed list; its text comes from RegistrySource, which
# the config_sync test renders again to catch a stale file.
require_relative "../carat/domain/json"
require_relative "../carat/domain/registry_source"

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

plugins_source = "config/plugins.json"
registry = "carat/plugins/registry.rb"
plugins_text = File.read(plugins_source)
registry_text = Carat::Domain::RegistrySource.render(Carat::Json.parse(plugins_text))
File.write(registry, registry_text)
STDOUT.puts "wrote #{registry} (#{Carat::Domain::RegistrySource.names(Carat::Json.parse(plugins_text)).length} plugins)"
