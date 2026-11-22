require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorSetOptionsTest
  D = Carat::Domain

  # An editor on a.txt holding text, with the test configuration: the
  # shipped defaults and option.showtabline 1.
  #: (String) -> Carat::Doubles::EditorHarness
  def self.editor(text)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(""), rows: 10, cols: 40, plugins: [])
    h.open("a.txt")
    h
  end

  # The message after keys typed on a fresh editor of one line.
  def self.message_after(keys)
    h = editor("abcd\n")
    h.type(keys.to_s)
    h.message
  end

  # The rows of a number option: [full name, short name, its largest
  # value, its shipped value]. Every form is typed by the short name and
  # shown by the full one.
  NUMBERS = [
    ["tabstop", "ts", "9999", "2"],
    ["shiftwidth", "sw", "9999", "2"],
    ["scroll", "scr", "9999", "0"],
    ["scrolloff", "so", "9999", "5"],
    ["timeoutlen", "tm", "10000", "500"],
    ["undolevels", "ul", "10000", "1000"],
    ["showtabline", "stal", "2", "2"]
  ]

  # The flags :set takes beside the search options and cursorline, which
  # test/editor_search.rb covers: [full name, short name].
  FLAGS = [
    ["number", "nu"],
    ["relativenumber", "rnu"],
    ["expandtab", "et"],
    ["autoindent", "ai"],
    ["list", "list"],
    ["reducedmotion", "reducedmotion"],
    ["hidden", "hid"]
  ]

  # The word options: [full name, short name, a value its line takes, one
  # it refuses, its shipped value].
  WORDS = [
    ["winborder", "winborder", "single", "bold", "rounded"],
    ["icons", "icons", "ascii", "emoji", "unicode"],
    ["breadcrumbs", "breadcrumbs", "never", "sometimes", "auto"],
    ["listchars", "lcs", "tab:>-,trail:~", "eol:$", "tab:→ ,trail:·,nbsp:␣"],
    ["theme", "theme", "one_dark", "solarized", "carat-dark"],
    ["background", "bg", "terminal", "dark", "theme"]
  ]

  #: (Array[untyped], Integer) -> String
  def self.word_at(row, index)
    row[index].to_s
  end

  # The table rows of every number option's forms.
  #: () -> Array[Array[untyped]]
  def self.number_rows
    rows = []
    NUMBERS.each do |entry|
      full = word_at(entry, 0)
      short = word_at(entry, 1)
      past = (word_at(entry, 2).to_i + 1).to_s
      rows << ["Setting a number: #{short}=1", ":set #{short}=1<CR>:set #{short}?<CR>", "  #{full}=1"]
      rows << ["Adding, subtracting, and multiplying a number: #{short}+=1", ":set #{short}=1<CR>:set #{short}+=1<CR>:set #{short}?<CR>", "  #{full}=2"]
      rows << ["Adding, subtracting, and multiplying a number: #{short}-=1", ":set #{short}=2<CR>:set #{short}-=1<CR>:set #{full}?<CR>", "  #{full}=1"]
      rows << ["Adding, subtracting, and multiplying a number: #{short}^=2", ":set #{short}=1<CR>:set #{short}^=2<CR>:set #{short}<CR>", "  #{full}=2"]
      rows << ["A number out of range keeps the old value: #{short}=#{past}", ":set #{short}=1<CR>:set #{short}=#{past}<CR>", "E474: Invalid argument: #{short}=#{past}"]
      rows << ["A number out of range keeps the old value: #{full} after #{short}=#{past}", ":set #{short}=1<CR>:set #{short}=#{past}<CR>:set #{short}?<CR>", "  #{full}=1"]
      rows << ["A number out of range keeps the old value: #{short}-=2 below the least", ":set #{short}=1<CR>:set #{short}-=2<CR>", "E474: Invalid argument: #{short}-=2"]
      rows << ["A value that is not a number: #{short}=x", ":set #{short}=x<CR>", "E521: Number required after =: #{short}=x"]
      rows << ["Resetting an option: #{short}&", ":set #{short}=1<CR>:set #{short}&<CR>:set #{short}?<CR>", "  #{full}=#{word_at(entry, 3)}"]
      rows << ["A flag prefix on a number: no#{short}", ":set no#{short}<CR>", "E474: Invalid argument: no#{short}"]
    end
    rows
  end

  # The table rows of every flag's boolean forms.
  #: () -> Array[Array[untyped]]
  def self.flag_rows
    rows = []
    shipped = D::Options.shipped
    FLAGS.each do |entry|
      full = word_at(entry, 0)
      short = word_at(entry, 1)
      reset = shipped.value_of(full) == "true" ? "  #{full}" : "no#{full}"
      rows << ["Turning a flag on, off, and over: no#{short}", ":set no#{short}<CR>:set #{short}?<CR>", "no#{full}"]
      rows << ["Turning a flag on, off, and over: #{short}", ":set no#{short}<CR>:set #{short}<CR>:set #{short}?<CR>", "  #{full}"]
      rows << ["Turning a flag on, off, and over: inv#{short}", ":set no#{short}<CR>:set inv#{short}<CR>:set #{full}?<CR>", "  #{full}"]
      rows << ["Turning a flag on, off, and over: #{short}!", ":set #{short}<CR>:set #{short}!<CR>:set #{short}?<CR>", "no#{full}"]
      rows << ["A value for a flag: #{short}=1", ":set #{short}=1<CR>", "E474: Invalid argument: #{short}=1"]
      rows << ["Resetting an option: #{short}&", ":set inv#{short}<CR>:set #{short}&<CR>:set #{short}?<CR>", reset]
    end
    rows
  end

  # The table rows of every word option's forms.
  #: () -> Array[Array[untyped]]
  def self.word_rows
    rows = []
    WORDS.each do |entry|
      full = word_at(entry, 0)
      short = word_at(entry, 1)
      good = word_at(entry, 2)
      bad = word_at(entry, 3)
      rows << ["Setting a word: #{short}=#{good}", ":set #{short}=#{good}<CR>:set #{short}?<CR>", "  #{full}=#{good}"]
      rows << ["Setting a word: the bare #{short} shows it", ":set #{short}=#{good}<CR>:set #{short}<CR>", "  #{full}=#{good}"]
      rows << ["A word the configuration refuses: #{short}=#{bad}", ":set #{short}=#{bad}<CR>", "E474: Invalid argument: #{short}=#{bad}"]
      rows << ["A word the configuration refuses: #{full} kept", ":set #{short}=#{good}<CR>:set #{short}=#{bad}<CR>:set #{short}?<CR>", "  #{full}=#{good}"]
      rows << ["Resetting an option: #{short}&", ":set #{short}=#{good}<CR>:set #{short}&<CR>:set #{short}?<CR>", "  #{full}=#{word_at(entry, 4)}"]
      rows << ["A list form of a word is not implemented: #{short}+=x", ":set #{short}+=x<CR>", "Not implemented: :set #{short}+=x"]
      rows << ["A flag prefix on a word: no#{short}", ":set no#{short}<CR>", "E474: Invalid argument: no#{short}"]
    end
    rows
  end

  def self.main
    t = Carat::Testing.new("editor_set_options")

    # Scenarios "Setting a number", "Adding, subtracting, and multiplying a
    # number", "A number out of range keeps the old value", "A value that
    # is not a number", "Resetting an option", and "A flag prefix on a
    # number" (set-command), for each number option. Rows are [label, keys,
    # message].
    t.table(number_rows) { |keys| message_after(keys) }

    # Scenarios "Turning a flag on, off, and over", "A value for a flag",
    # and "Resetting an option" (set-command), for each flag.
    t.table(flag_rows) { |keys| message_after(keys) }

    # Scenarios "Setting a word", "A word the configuration refuses", and
    # "Resetting an option" (set-command), for each word option.
    t.table(word_rows) { |keys| message_after(keys) }

    # The forms around them. Rows are [label, keys, message].
    t.table([
      ["A blank kept by a backslash", ":set lcs=tab:>\\ ,trail:-<CR>:set lcs?<CR>", "  listchars=tab:> ,trail:-"],
      ["a backslash kept by a backslash", ":set lcs=tab:\\\\\\\\<CR>:set lcs?<CR>", "  listchars=tab:\\\\"],
      ["several arguments in one command", ":set ts=3 sw=0 nonu<CR>:set ts? sw? nu?<CR>", "  tabstop=3\n  shiftwidth=0\nnonumber"],
      ["a refused argument stops the command, the ones before it kept", ":set ts=3 sw=x ul=5<CR>:set ts? ul?<CR>", "  tabstop=3\n  undolevels=1000"],
      ["a trailing ! on a number is E474", ":set ts!<CR>", "E474: Invalid argument: ts!"],
      ["Not implemented: resetting every option", ":set all&<CR>", "Not implemented: :set all&"],
      ["an option outside :set's is unknown", ":set jumptab=keep<CR>", "E518: Unknown option: jumptab"],
      ["& on filetype is not implemented", ":set ft&<CR>", "Not implemented: :set ft&"],
      ["a flag prefix on filetype is E474", ":set noft<CR>", "E474: Invalid argument: noft"],
      # Scenario "startscreen is read only at startup" (set-command).
      ["startscreen is read only at startup", ":set nostartscreen<CR>", "Not implemented: :set startscreen live"],
      ["startscreen is read only at startup: the value kept", ":set nostartscreen<CR>:set startscreen?<CR>", "  startscreen"],
      ["startscreen is read only at startup: & too", ":set startscreen&<CR>", "Not implemented: :set startscreen live"],
      # Scenarios "Setting the theme and the background" and "A theme the
      # configuration refuses" (set-command).
      ["Setting the theme and the background", ":set theme=one_light bg=terminal<CR>:set theme? bg?<CR>", "  theme=one_light\n  background=terminal"],
      ["Setting the theme and the background: & gives back the shipped ones", ":set theme=one_light bg=terminal<CR>:set theme& bg&<CR>:set theme? bg?<CR>", "  theme=carat-dark\n  background=theme"],
      ["A theme the configuration refuses", ":set theme=solarized<CR>", "E474: Invalid argument: theme=solarized"],
      ["A theme the configuration refuses: the theme kept", ":set theme=solarized<CR>:set theme?<CR>", "  theme=carat-dark"],
      # Scenario "A bare set lists the changed options" (set-command): the
      # test configuration's showtabline 1 differs from the shipped 2.
      ["A bare set lists the changed options", ":set ts=4 nonu<CR>:set<CR>", "--- Options ---\nnonumber\n  showtabline=1\n  tabstop=4"],
      ["a bare set lists the filetype and syntax once set", ":set ft=ruby stal=2<CR>:set<CR>", "--- Options ---\n  filetype=ruby\n  syntax=ruby"]
    ]) { |keys| message_after(keys) }

    # Scenario "Set all lists every option" (set-command): the heading and
    # one line for each of the 28 options.
    h = editor("abcd\n")
    h.type(":set all<CR>")
    lines = h.message.split("\n")
    t.assert_equal(["--- Options ---", 29, true, true, true, true, true], [lines[0].to_s, lines.length, lines.include?("  tabstop=2"), lines.include?("  number"), lines.include?("  filetype="), lines.include?("  theme=carat-dark"), lines.include?("  background=theme")], "Set all lists every option")

    # Scenario "The number column follows set number" (set-command).
    h = editor("one\n")
    h.type(":set nonu<CR>")
    off = h.row(0).rstrip
    h.type(":set nu<CR>")
    t.assert_equal(["one", "  1 one"], [off, h.row(0).rstrip], "The number column follows set number")

    # Scenario "A tab is drawn at the new tabstop" (set-command).
    h = editor("a\tx\n")
    h.type(":set nonu<CR>")
    before = h.row(0).rstrip
    h.type(":set ts=4<CR>")
    t.assert_equal(["a x", "a   x"], [before, h.row(0).rstrip], "A tab is drawn at the new tabstop")

    # Scenario "Fewer undo levels" (set-command).
    h = editor("abcd\n")
    h.type(":set ul=1<CR>xxx")
    h.type("u")
    once = h.lines.join("|")
    h.type("u")
    t.assert_equal(["cd", "cd", "Already at oldest change"], [once, h.lines.join("|"), h.message], "Fewer undo levels")

    # The whitespace marks follow :set list and :set lcs at once.
    h = editor("a\tb \n")
    h.type(":set nonu list lcs=tab:>-,trail:~<CR>")
    t.assert_equal("a>b~", h.row(0).rstrip, ":set list and :set lcs draw the marks at once")

    t.finish
  end
end

EditorSetOptionsTest.main if __FILE__ == $0
