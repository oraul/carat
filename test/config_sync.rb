# Fails when carat/domain/default_config.rb is out of date with
# config/default.json, or when the JSON does not match the schema's shape.
require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("config_sync")

file_text = File.read("config/default.json")
t.assert_equal(file_text, Carat::Domain::DEFAULT_CONFIG_JSON, "generated mirror matches config/default.json")

config = Carat::Json.parse(Carat::Domain::DEFAULT_CONFIG_JSON)
t.assert_true(config.is_a?(Hash), "config is an object")
["leader", "timeoutlen", "options", "keymaps", "languages", "plugins", "theme"].each do |key|
  t.assert_true(config.key?(key), "has #{key}")
end
modes = ["normal", "insert", "visual", "visual_line", "visual_block", "operator_pending", "cmdline"]
modes.each do |mode|
  t.assert_true(config["keymaps"][mode].is_a?(Hash), "keymaps.#{mode} is an object")
end
bad = []
config["keymaps"].each do |mode, map|
  map.each do |key, action|
    ok = action.nil? || (action.is_a?(String) && !action.empty?)
    bad << "#{mode}.#{key}" unless ok
  end
end
t.assert_equal([], bad, "every binding is an action name, a key sequence, or null")

t.finish
