# Checks the rules the Spinel compiler does not enforce by itself:
# the layer dependency rule, the plugin rule (a plugin requires only
# carat/plugin_api.rb and its own directory; the generated registry may
# require any plugin), forbidden constructs, and hard-coded bindings.
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

# A buffer's line array changes only inside carat/domain/buffer.rb,
# through its primitives. Anywhere else, in the library, the executables,
# and the tests, assigning lines, assigning one of its elements, or calling
# a mutating method on it is a violation.
LINES_MUTATORS = ["<<", ".insert(", ".delete_at(", ".push(", ".append(", ".prepend(", ".pop", ".shift", ".unshift(", ".concat(", ".clear", ".replace(", ".slice!(", ".delete(", ".delete_if", ".keep_if", ".fill(", ".map!", ".collect!", ".select!", ".filter!", ".reject!", ".sort!", ".sort_by!", ".reverse!", ".compact!", ".flatten!", ".uniq!", ".rotate!", ".shuffle!"]

def assigns?(tail)
  tail.start_with?("=") && !tail.start_with?("==") && !tail.start_with?("=~")
end

def lines_mutation?(stripped)
  rest = stripped
  at = rest.index(".lines")
  until at.nil?
    rest = rest[(at + 6)..-1]
    unless rest.match?(/\A[A-Za-z0-9_?!]/)
      tail = rest.lstrip
      return true if assigns?(tail)
      if tail.start_with?("[")
        close = tail.index("]")
        return true if !close.nil? && assigns?(tail[(close + 1)..-1].lstrip)
      end
      LINES_MUTATORS.each { |m| return true if tail.start_with?(m) }
    end
    at = rest.index(".lines")
  end
  false
end

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
        own_dir = path == "carat/plugins/registry.rb" ? "carat/plugins/" : File.dirname(path) + "/"
        unless full == "carat/plugin_api.rb" || full.start_with?(own_dir)
          violations << "#{path}:#{number}: a plugin may require only carat/plugin_api.rb and files in its own directory"
        end
      elsif to_layer && LAYER_RANK.key?(to_layer) && LAYER_RANK.key?(from_layer)
        if LAYER_RANK[to_layer] > LAYER_RANK[from_layer]
          violations << "#{path}:#{number}: #{from_layer} may not require #{to_layer} (outer layer)"
        end
      end
    end
  end
end

edited = []
edited.concat(source_files)
edited.concat(Dir.glob("test/*.rb"))
edited.sort.each do |path|
  next if path == "carat/domain/buffer.rb"
  File.read(path).each_line.with_index(1) do |line, number|
    stripped = line.strip
    next if stripped.start_with?("#")
    violations << "#{path}:#{number}: only Buffer changes its lines; use the buffer primitives" if lines_mutation?(stripped)
  end
end

# Inline RBS: every method and attribute under carat/ carries a signature.
# A def is covered when the comment block directly above it (same indent,
# no blank line) contains a line starting with "#:" or "# @rbs".
# An attr_reader, attr_writer or attr_accessor needs a trailing "#:" type.
missing = []
Dir.glob("carat/**/*.rb").sort.each do |path|
  next if path == "carat/domain/default_config.rb"
  lines = File.read(path).lines
  lines.each_with_index do |line, i|
    stripped = line.strip
    if stripped.start_with?("def ") || stripped.start_with?("private def ") || stripped.start_with?("protected def ")
      indent = line[/\A */].length
      covered = false
      j = i - 1
      while j >= 0
        above = lines[j]
        break unless above[/\A */].length == indent && above.strip.start_with?("#")
        text = above.strip
        covered = true if text.start_with?("#:") || text.start_with?("# @rbs")
        j -= 1
      end
      missing << "#{path}:#{i + 1}: #{stripped[0, 40]} has no inline RBS signature" unless covered
    elsif stripped.start_with?("attr_reader ") || stripped.start_with?("attr_writer ") || stripped.start_with?("attr_accessor ")
      missing << "#{path}:#{i + 1}: #{stripped[0, 40]} has no trailing #: type" unless stripped.include?("#:")
    end
  end
end
missing.each { |m| STDOUT.puts m }

violations.each { |v| STDOUT.puts v }
t.assert_equal(0, violations.length, "no lint violations")
t.assert_equal(0, missing.length, "every method and attribute has an inline RBS signature")
t.finish
