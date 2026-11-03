# Fails when carat/domain/default_config.rb is out of date with
# config/default.caratrc, when carat/plugins/registry.rb is out of date with
# config/plugins.caratrc, or when the defaults do not read cleanly.
require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module ConfigSyncTest
  MODES = ["normal", "insert", "visual", "visual_line", "visual_block", "operator_pending", "cmdline"]

  def self.main
    t = Carat::Testing.new("config_sync")

    file_text = File.read("config/default.caratrc")
    t.assert_equal(file_text, Carat::Domain::DEFAULT_CARATRC, "generated mirror matches config/default.caratrc")

    config = Carat::Domain::Config.new
    config.read_defaults("config/default.caratrc", Carat::Domain::DEFAULT_CARATRC)
    t.assert_equal([], config.report, "every line of the defaults reads, in a known scope")
    options = Carat::Domain::Options.from_config(config)
    t.assert_equal([], config.report, "every option line names an option with a value of its kind")
    t.assert_true(Carat::Domain::Icons.set?(options.icons), "the icons option names a set")
    t.assert_equal("<Space>", Carat::Domain::Keymap.leader_from(config), "the defaults set the leader")
    bound = {}
    MODES.each { |mode| bound[mode] = 0 }
    i = 0
    while i < config.count
      line = config.line_at(i)
      bound[line.name] = bound[line.name].to_i + 1 if line.scope == "keymap" && bound.key?(line.name)
      i += 1
    end
    MODES.each { |mode| t.assert_true(bound[mode].to_i > 0, "the defaults bind keys in #{mode}") }

    # The plugin registry mirrors config/plugins.caratrc.
    plugins = Carat::Domain::Config.new
    plugins.read("config/plugins.caratrc", File.read("config/plugins.caratrc"), true)
    t.assert_equal([], plugins.report, "every line of config/plugins.caratrc reads")
    names = Carat::Domain::RegistrySource.names(plugins)
    t.assert_true(names.length > 0, "config/plugins.caratrc lists at least one plugin")
    t.assert_equal(names.length, plugins.count, "every plugins.caratrc line has a name, a path, and a class")
    t.assert_equal(Carat::Domain::RegistrySource.render(plugins), File.read("carat/plugins/registry.rb"), "generated registry matches config/plugins.caratrc")
    t.assert_equal(names, Carat::Plugins::Registry::NAMES, "the compiled registry names the same plugins")
    t.assert_equal(names.length, Carat::Plugins::Registry.all.length, "the compiled registry constructs one plugin per entry")
    stale = []
    i = 0
    while i < config.count
      line = config.line_at(i)
      if line.scope == "plugin"
        name = line.name.split(".")[0].to_s
        stale << line.key unless names.include?(name)
      end
      i += 1
    end
    t.assert_equal([], stale, "every plugin line of config/default.caratrc names a listed plugin")

    t.finish
  end
end

ConfigSyncTest.main if __FILE__ == $0
