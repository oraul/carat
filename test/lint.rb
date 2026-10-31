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

# A plugin names nothing of the editor's layers, even without requiring
# it: the namespaces of the entities, use cases, adapters, drivers, and
# doubles are refused outside comments.
PLUGIN_REFERENCES = ["Domain::", "UseCases::", "Adapters::", "Drivers::", "Doubles::"]

def plugin_reference?(stripped)
  return false if stripped.start_with?("#")
  PLUGIN_REFERENCES.each { |name| return true if stripped.include?(name) }
  false
end

# A concern (a module under carat/<layer>/concerns/) holds behavior only:
# no instance variables, no constructor, no extend, no included hook, and
# no define_method; the reason for a refused line, or "".
def concern_problem(stripped)
  return "" if stripped.start_with?("#")
  return "a concern has no instance variables" if stripped.match?(/(^|[^A-Za-z0-9_"])@[a-z_]/)
  return "a concern has no constructor" if stripped.start_with?("def initialize")
  return "a concern does not extend" if stripped.start_with?("extend ")
  return "a concern has no included hook" if stripped.include?("included do")
  return "a concern does not define methods at run time" if stripped.include?("define_method")
  ""
end

# The names of the methods a class body in text defines, from the line
# opening the class to the end of its indentation level.
def defs_of(text, opener)
  names = []
  inside = false
  indent = 0
  text.each_line do |line|
    if !inside && line.strip.start_with?(opener)
      inside = true
      indent = line[/\A */].length
      next
    end
    next unless inside
    break if line.strip == "end" && line[/\A */].length == indent
    stripped = line.strip
    if stripped.start_with?("def ") && line[/\A */].length == indent + 2
      names << stripped.sub("def ", "").split("(")[0].strip
    end
  end
  names
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

# The plugin link overrides every request of the plugin API's host.
host_methods = defs_of(File.read("carat/plugin_api.rb"), "class Host")
link_methods = defs_of(File.read("carat/use_cases/plugins/plugin_link.rb"), "class PluginLink")
host_methods.each do |name|
  violations << "carat/use_cases/plugins/plugin_link.rb: PluginLink does not override Host##{name}" unless link_methods.include?(name)
end

source_files.each do |path|
  text = File.read(path)
  next if path == "carat/domain/default_config.rb" # generated, data only
  from_layer = layer_of(path)

  concern = path.include?("/concerns/")
  if concern && !text.include?("Readers the including class provides:")
    violations << "#{path}: a concern lists the readers it depends on"
  end
  text.each_line.with_index(1) do |line, number|
    stripped = line.strip
    if concern && stripped.start_with?("#:")
      violations << "#{path}:#{number}: a concern's methods carry # @rbs skip, since a signature on a mixed-in method is not applied"
    end
    next if stripped.start_with?("#")
    if from_layer == "plugins" && plugin_reference?(stripped)
      violations << "#{path}:#{number}: a plugin names only the plugin API, never the editor's layers"
    end
    if concern
      problem = concern_problem(stripped)
      violations << "#{path}:#{number}: #{problem}" unless problem.empty?
    end
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

# The rules themselves, against a line each must refuse and one each must
# let through, so a broken rule fails here instead of passing silently.
t.assert_equal([true, true, false, false], [plugin_reference?("x = Carat::Domain::Buffer.new"), plugin_reference?("UseCases::PluginHost"), plugin_reference?("# Domain:: in a comment"), plugin_reference?("Carat::PluginApi::Paths.join(a, b)")], "the plugin reference rule")
t.assert_equal(["a concern has no instance variables", "a concern has no constructor", "a concern does not extend", "a concern has no included hook", "a concern does not define methods at run time", ""], [concern_problem("@count += 1"), concern_problem("def initialize"), concern_problem("extend Other"), concern_problem("included do"), concern_problem("define_method(:x) { }"), concern_problem("registry.enter(entry.name)")], "the concern rules")
t.assert_equal(true, host_methods.length >= 27 && host_methods.include?("open_in_split") && link_methods.include?("open_in_tab"), "the link coverage rule reads both classes")
t.assert_equal(["a", "b"], defs_of("class X\n  def a\n  end\n  def b(x)\n  end\nend\nclass Y\n  def c\n  end\nend\n", "class X"), "defs_of reads one class body")

violations.each { |v| STDOUT.puts v }
t.assert_equal(0, violations.length, "no lint violations")
t.assert_equal(0, missing.length, "every method and attribute has an inline RBS signature")
t.finish
