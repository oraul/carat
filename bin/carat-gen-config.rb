# Generates carat/domain/default_config.rb from config/default.caratrc and
# carat/plugins/registry.rb from config/plugins.caratrc.
#
# The native binary cannot read the repository at run time, so the
# defaults' text is embedded as a frozen string and read at startup like
# any other configuration file. The registry is explicit Ruby, one require
# and one constructor per plugin, so the compiler sees a fixed list; its
# text comes from RegistrySource, which the config_sync test renders again
# to catch a stale file. A line of either file that does not read stops
# the generator before it writes anything.
require_relative "../carat/domain/config"
require_relative "../carat/domain/registry_source"

source = "config/default.caratrc"
target = "carat/domain/default_config.rb"
text = File.read(source)
plugins_source = "config/plugins.caratrc"
plugins_text = File.read(plugins_source)

defaults = Carat::Domain::Config.new
defaults.read(source, text, true)
plugins = Carat::Domain::Config.new
plugins.read(plugins_source, plugins_text, true)
problems = defaults.report + plugins.report
unless problems.empty?
  problems.each { |problem| STDERR.puts problem }
  exit 1
end

out = +""
out << "# Generated from config/default.caratrc by bin/carat-gen-config.rb.\n"
out << "# Do not edit. Change config/default.caratrc and run: spin run carat-gen-config\n"
out << "module Carat\n"
out << "  module Domain\n"
out << "    DEFAULT_CARATRC = <<~'CARATRC'.freeze\n"
text.each_line { |line| out << (line == "\n" ? line : "      " + line) }
out << "\n" unless text.end_with?("\n")
out << "    CARATRC\n"
out << "  end\n"
out << "end\n"

# A file is written only when its text changes, so its time stamp, which
# spin build and spin run compare with their outputs, moves only then.
if File.exist?(target) && File.read(target) == out
  STDOUT.puts "#{target} is current"
else
  File.write(target, out)
  STDOUT.puts "wrote #{target} (#{defaults.count} settings)"
end

registry = "carat/plugins/registry.rb"
registry_text = Carat::Domain::RegistrySource.render(plugins)
if File.exist?(registry) && File.read(registry) == registry_text
  STDOUT.puts "#{registry} is current"
else
  File.write(registry, registry_text)
  STDOUT.puts "wrote #{registry} (#{Carat::Domain::RegistrySource.names(plugins).length} plugins)"
end
