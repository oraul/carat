require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainFiletypeTest
  D = Carat::Domain

  # A table row's values are untyped, and an untyped argument would widen
  # the detector's parameters for the whole program, so the path is
  # converted here; nil stays nil, for a buffer without a name.
  #: (untyped) -> String?
  def self.path_of(value)
    return nil if value.nil?
    value.to_s
  end

  def self.main
    t = Carat::Testing.new("domain_filetype")

    # The table: extensions, whole names, then a shebang when the name says
    # nothing; "" for none.
    t.table([
      ["an .rb file", ["lib/a.rb", ""], "ruby"],
      ["a .rake file", ["tasks/build.rake", ""], "ruby"],
      ["a .gemspec file", ["carat.gemspec", ""], "ruby"],
      ["a .ru file", ["app.ru", ""], "ruby"],
      ["Gemfile", ["Gemfile", ""], "ruby"],
      ["Rakefile in a directory", ["/src/Rakefile", ""], "ruby"],
      ["config.ru", ["config.ru", ""], "ruby"],
      ["an unknown extension", ["notes.txt", ""], ""],
      ["a dot file", [".rb", ""], ""],
      ["no extension", ["README", ""], ""],
      ["the extension is case sensitive", ["A.RB", ""], ""],
      ["a ruby shebang", ["tool", "#!/usr/bin/ruby"], "ruby"],
      ["env ruby", ["tool", "#!/usr/bin/env ruby"], "ruby"],
      ["env with options", ["tool", "#!/usr/bin/env -S ruby -w"], "ruby"],
      ["env with a variable", ["tool", "#!/usr/bin/env RUBYOPT=-W ruby"], "ruby"],
      ["a versioned ruby", ["tool", "#! /opt/bin/ruby3.4"], "ruby"],
      ["another interpreter", ["tool", "#!/bin/sh"], ""],
      ["rubocop is not ruby", ["tool", "#!/usr/bin/env rubocop"], ""],
      ["a comment that is no shebang", ["tool", "# ruby"], ""],
      ["an unknown extension falls back to the shebang", ["a.txt", "#!/usr/bin/ruby"], "ruby"],
      ["a known name wins over the shebang", ["a.rb", "#!/bin/sh"], "ruby"],
      ["no path, a shebang", [nil, "#!/usr/bin/ruby"], "ruby"],
      ["no path, no shebang", [nil, ""], ""]
    ]) { |input| D::Filetype.detect(path_of(input[0]), input[1].to_s) }

    # A buffer detects its filetype when it is made and when it is renamed;
    # the syntax follows the filetype.
    b = D::Buffer.from_text("x = 1\n", "a.rb")
    t.assert_equal(["ruby", "ruby"], [b.filetype, b.syntax], "a buffer of a.rb is ruby")
    b.rename("a.txt")
    t.assert_equal(["", ""], [b.filetype, b.syntax], "renaming it to a.txt clears the filetype")
    s = D::Buffer.from_text("#!/usr/bin/env ruby\nputs 1\n", "tool")
    t.assert_equal("ruby", s.filetype, "a shebang names the filetype")
    s.assign_filetype("")
    t.assert_equal(["", ""], [s.filetype, s.syntax], "assign_filetype sets both")
    e = D::Buffer.from_text("", nil)
    t.assert_equal("", e.filetype, "an empty buffer has none")

    t.finish
  end
end

DomainFiletypeTest.main if __FILE__ == $0
