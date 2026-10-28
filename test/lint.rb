# Checks the rules the Spinel compiler does not enforce by itself:
# the layer dependency rule, forbidden constructs, and hard-coded bindings.
# Prints every violation; the snapshot is the empty report.
require_relative "../carat/testing"

t = Carat::Testing.new("lint")

LAYER_RANK = {
  "domain" => 0,
  "ports" => 1,
  "use_cases" => 1,
  "adapters" => 2,
  "drivers" => 3,
  "doubles" => 2,
  "plugins" => 9
}

FORBIDDEN = [
  ["eval(", "eval is not compiled by Spinel"],
  ["instance_eval", "instance_eval is not compiled by Spinel"],
  ["class_eval", "class_eval is not compiled by Spinel"],
  ["method_missing", "method_missing is not compiled by Spinel"],
  ["define_method", "define_method under a runtime condition is refused by Spinel"],
  ["instance_variable_get", "computed ivar access is not compiled by Spinel"],
  ["instance_variable_set", "computed ivar access is not compiled by Spinel"],
  ["const_get", "runtime constant lookup is not compiled by Spinel"],
  ["IO.popen", "IO.popen is refused by Spinel; use Process.spawn with IO.pipe"],
  ["require \"json\"", "use Carat::Json, Spinel bundles no json library"],
  ["require 'json'", "use Carat::Json, Spinel bundles no json library"],
  ["Ractor", "Ractor is not available in Spinel"]
]

def layer_of(path)
  parts = path.split("/")
  return nil unless parts[0] == "carat" && parts.length > 2
  parts[1]
end

def source_files
  files = []
  files.concat(Dir.glob("carat.rb"))
  files.concat(Dir.glob("carat/**/*.rb"))
  files.concat(Dir.glob("bin/*.rb"))
  files.sort
end

violations = []

source_files.each do |path|
  text = File.read(path)
  next if path == "carat/domain/default_config.rb" # generated, data only
  from_layer = layer_of(path)

  text.each_line.with_index(1) do |line, number|
    stripped = line.strip
    next if stripped.start_with?("#")
    FORBIDDEN.each do |pattern, reason|
      violations << "#{path}:#{number}: #{reason}" if stripped.include?(pattern)
    end
    if stripped.include?(".send(") && !stripped.include?(".send(:")
      violations << "#{path}:#{number}: send with a computed name is not compiled by Spinel"
    end
    if stripped.start_with?("require_relative ") && from_layer
      target = stripped.sub("require_relative ", "").delete("\"'")
      full = File.expand_path(target, File.dirname(path)).sub(Dir.pwd + "/", "") + ".rb"
      to_layer = layer_of(full)
      if from_layer == "plugins"
        unless full == "carat/plugin_api.rb" || full.start_with?("carat/plugins/")
          violations << "#{path}:#{number}: a plugin may require only carat/plugin_api.rb"
        end
      elsif to_layer && LAYER_RANK.key?(to_layer) && LAYER_RANK.key?(from_layer)
        if LAYER_RANK[to_layer] > LAYER_RANK[from_layer]
          violations << "#{path}:#{number}: #{from_layer} may not require #{to_layer} (outer layer)"
        end
      end
    end
  end
end

violations.each { |v| STDOUT.puts v }
t.assert_equal(0, violations.length, "no lint violations")
t.finish
