require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorColorschemeTest
  D = Carat::Domain
  C256 = D::ColorDepth::COLORS_256

  # An editor on a Ruby file at the double's 256 colors, its palette named
  # by a configuration line.
  #: (String) -> Carat::Doubles::EditorHarness
  def self.editor(theme)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", "def go = \"hi\" # note\nx = 1\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("option.theme #{theme}\n"), rows: 12, cols: 60, plugins: [Carat::Plugins::Ruby::Plugin.new])
    h.open("a.rb")
    h
  end

  # Whether the last write drew the frame in full in the palette and the
  # background the options name: the screen cleared, and every cell's
  # group written in that palette's 256-color sequence.
  #: (Carat::Doubles::EditorHarness) -> bool
  def self.repainted?(h)
    out = h.terminal.last_write
    return false unless out.include?("\e[2J")
    options = h.state.options
    table = Carat::Adapters::SgrTable.from_theme(D::Themes.find(options.theme, options.background), C256)
    frame = h.frame
    row = 0
    while row < frame.rows
      col = 0
      while col < frame.cols
        return false unless out.include?(table.at(frame.hl_at(row, col)))
        col += 1
      end
      row += 1
    end
    true
  end

  # What keys typed on an editor started in a palette leave: the message,
  # whether that frame was drawn in full in the palette the options name
  # then, and the theme option.
  #: (String, String) -> String
  def self.outcome(start, keys)
    h = editor(start)
    h.type(keys)
    "#{h.message}|#{repainted?(h)}|#{h.state.options.theme}"
  end

  # Rows are [label, [starting palette, keys], "message|repainted|theme"]:
  # each shipped palette from another one, then the other forms.
  #: () -> Array[Array[untyped]]
  def self.rows
    rows = []
    D::Themes::NAMES.each do |name|
      start = name == "one_dark" ? "carat-dark" : "one_dark"
      rows << ["Switching to each shipped palette: #{name}", [start, ":colorscheme #{name}<CR>"], "|true|#{name}"]
    end
    rows << ["Switching to each shipped palette: by the abbreviation", ["carat-dark", ":colo one_light<CR>"], "|true|one_light"]
    rows << ["Switching to each shipped palette: the current one repaints nothing", ["carat-dark", ":colorscheme carat-dark<CR>"], "|false|carat-dark"]
    rows << ["Switching to each shipped palette: blanks around the name", ["carat-dark", ":colorscheme  dark_plus <CR>"], "|true|dark_plus"]
    rows << ["An unknown palette", ["carat-dark", ":colorscheme solarized<CR>"], "E185: Cannot find color scheme 'solarized'|false|carat-dark"]
    rows << ["An unknown palette: two words are one name", ["carat-dark", ":colorscheme one dark<CR>"], "E185: Cannot find color scheme 'one dark'|false|carat-dark"]
    rows << ["No name shows the current palette", ["carat-dark", ":colorscheme<CR>"], "carat-dark|false|carat-dark"]
    rows << ["No name shows the current palette: after a switch", ["carat-dark", ":colo light_plus<CR>:colo<CR>"], "light_plus|false|light_plus"]
    rows << ["Set theme repaints", ["carat-dark", ":set theme=one_dark<CR>"], "|true|one_dark"]
    rows << ["Set theme repaints: & gives back the shipped palette", ["one_light", ":set theme&<CR>"], "|true|carat-dark"]
    rows << ["Set background repaints", ["carat-dark", ":set bg=terminal<CR>"], "|true|carat-dark"]
    rows << ["Set background repaints: back to the palette's", ["carat-dark", ":set bg=terminal<CR>:set background=theme<CR>"], "|true|carat-dark"]
    rows << ["Set theme repaints: a refused name repaints nothing", ["carat-dark", ":set theme=solarized<CR>"], "E474: Invalid argument: theme=solarized|false|carat-dark"]
    rows
  end

  #: (Array[untyped], Integer) -> String
  def self.part(input, index)
    input[index].to_s
  end

  def self.main
    t = Carat::Testing.new("editor_colorscheme")

    # Scenarios "Switching to each shipped palette", "Set theme repaints",
    # and "Set background repaints" (color-themes), "An unknown palette"
    # and "No name shows the current palette" (color-themes).
    t.table(rows) { |input| outcome(part(input, 0), part(input, 1)) }

    # Set background repaints: with the terminal's background the screen
    # is cleared in the terminal's own colors.
    h = editor("carat-dark")
    h.type(":set bg=terminal<CR>")
    t.assert_equal([true, false], [h.terminal.last_write.include?("\e[?25l\e[2J"), h.terminal.last_write.include?("\e[0;38;5;252;48;5;234m")], "Set background repaints: the screen cleared in the terminal's colors, nothing in carat-dark's painted Normal")

    t.finish
  end
end

EditorColorschemeTest.main if __FILE__ == $0
