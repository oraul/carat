require_relative "themes"
require_relative "icons"
require_relative "config"
require_relative "rc_value"
require_relative "utf8"
require_relative "display_width"

module Carat
  module Domain
    # Typed options with Vim names, plus icons, Carat's own: the icon set
    # plugins draw with, "nerd", "unicode", or "ascii". timeoutlen is the
    # milliseconds the keymap waits for the rest of an ambiguous binding.
    # scroll is the lines <C-d> and <C-u> scroll, half the window when 0.
    # Only the ones the editor reads are members; :set and local options
    # arrive with the options change. undolevels is how many undo states a
    # buffer keeps. theme names the palette, background says whether the
    # terminal ("terminal") or the palette ("theme") paints the
    # background, and syntax_on is the switch of :syntax on and :syntax
    # off, on from the start as in Neovim. keyhints_delay is the
    # milliseconds a waiting prefix waits before its key hints show, 0
    # for none. layout_left_width, layout_right_width, and
    # layout_panel_height size the slots of every tab page, 0 keeping the
    # size the view asks for. startscreen shows the start
    # screen when the editor starts without a file, and reducedmotion
    # shows its last frame without the animation. cursorline draws the
    # cursor's line in the current window over the CursorLine background.
    # breadcrumbs says when file windows show a winbar: "auto" with two
    # or more file windows, "always", or "never". indentguides draws a
    # guide at each shiftwidth level of file windows' indentation, in
    # indentguides_char, one character one column wide.
    # All but syntax_on come from option lines of the configuration. A Struct
    # record: mutable, with a reader and a writer per member.
    class Options < Struct.new(:number, :relativenumber, :tabstop, :shiftwidth, :expandtab, :autoindent, :scroll, :scrolloff, :icons, :timeoutlen, :undolevels, :theme, :background, :syntax_on, :ignorecase, :smartcase, :hlsearch, :incsearch, :startscreen, :reducedmotion, :cursorline, :keyhints_delay, :layout_left_width, :layout_right_width, :layout_panel_height, :breadcrumbs, :indentguides, :indentguides_char, keyword_init: true)
      # @rbs @number: bool
      # @rbs @relativenumber: bool
      # @rbs @tabstop: Integer
      # @rbs @shiftwidth: Integer
      # @rbs @expandtab: bool
      # @rbs @autoindent: bool
      # @rbs @scroll: Integer
      # @rbs @scrolloff: Integer
      # @rbs @icons: String
      # @rbs @timeoutlen: Integer
      # @rbs @undolevels: Integer
      # @rbs @theme: String
      # @rbs @background: String
      # @rbs @syntax_on: bool
      # @rbs @ignorecase: bool
      # @rbs @smartcase: bool
      # @rbs @hlsearch: bool
      # @rbs @incsearch: bool
      # @rbs @startscreen: bool
      # @rbs @reducedmotion: bool
      # @rbs @cursorline: bool
      # @rbs @keyhints_delay: Integer
      # @rbs @layout_left_width: Integer
      # @rbs @layout_right_width: Integer
      # @rbs @layout_panel_height: Integer
      # @rbs @breadcrumbs: String
      # @rbs @indentguides: bool
      # @rbs @indentguides_char: String

      # Vim's defaults, the nerd icon set, the default theme on the
      # terminal's background, syntax highlighting on, and Neovim's search
      # defaults: hlsearch and incsearch on, ignorecase and smartcase off;
      # the start screen on, with its animation; cursorline and the
      # indent guides off, as in Neovim, which draws none.
      #: () -> void
      def initialize
        super(number: false, relativenumber: false, tabstop: 8, shiftwidth: 8, expandtab: false, autoindent: false, scroll: 0, scrolloff: 0, icons: "nerd", timeoutlen: 1000, undolevels: 1000, theme: Themes::DEFAULT, background: "terminal", syntax_on: true, ignorecase: false, smartcase: false, hlsearch: true, incsearch: true, startscreen: true, reducedmotion: false, cursorline: false, keyhints_delay: 300, layout_left_width: 0, layout_right_width: 0, layout_panel_height: 0, breadcrumbs: "auto", indentguides: false, indentguides_char: GUIDE_CHAR)
      end

      # The options a configuration line may set, by name, with the kind
      # of value each takes. Those that are not members are checked and
      # kept for the changes that read them.
      KINDS = {
        "number" => "bool", "relativenumber" => "bool", "expandtab" => "bool", "autoindent" => "bool",
        "ignorecase" => "bool", "smartcase" => "bool", "hlsearch" => "bool", "incsearch" => "bool", "wrap" => "bool",
        "startscreen" => "bool", "reducedmotion" => "bool", "cursorline" => "bool", "indentguides" => "bool",
        "tabstop" => "integer", "shiftwidth" => "integer", "scroll" => "integer", "scrolloff" => "integer", "timeoutlen" => "integer", "undolevels" => "integer", "keyhints.delay" => "integer",
        "layout.left_width" => "integer", "layout.right_width" => "integer", "layout.panel_height" => "integer",
        "clipboard" => "string", "icons" => "string", "theme" => "string", "background" => "string", "breadcrumbs" => "string", "indentguides.char" => "string"
      }

      # The key hints' default wait in milliseconds and the longest one; 0
      # turns the hints off.
      KEYHINTS_DELAY = 300
      KEYHINTS_DELAY_MAX = 10_000

      # The modes of breadcrumbs: the winbar shows with two or more file
      # windows, on every file window, or never.
      BREADCRUMBS = ["auto", "always", "never"]

      # The indent guides' default character and the one drawn in its
      # place with the ascii icon set.
      GUIDE_CHAR = "┊"
      GUIDE_ASCII = 124

      # The largest slot size, in columns or rows.
      SLOT_SIZE_MAX = 500

      # The largest tabstop or shiftwidth, Vim's limit for tabstop: a
      # larger one would make one Tab or >> build a string of that many
      # spaces.
      WIDTH_MAX = 9999

      # The width a tab takes for display and block columns: tabstop, or 8
      # when tabstop is not positive.
      #: () -> Integer
      def tab_width
        tabstop > 0 ? tabstop : 8
      end

      # The code point indent guides are drawn with: the guide character,
      # or | in its place when the icon set is ascii and the character is
      # not.
      #: () -> Integer
      def guide_code
        text = indentguides_char
        code = Utf8.code_at(text, 0, Utf8.size_at(text, 0, text.bytesize))
        return GUIDE_ASCII if code > 127 && icons == "ascii"
        code
      end

      # Whether a word can be the guide character: one character, one
      # display column wide, not a control.
      #: (String) -> bool
      def self.guide_char?(word)
        n = word.bytesize
        return false if n == 0
        size = Utf8.size_at(word, 0, n)
        return false if size != n
        code = Utf8.code_at(word, 0, size)
        return false if code < 32 || DisplayWidth.control?(code)
        DisplayWidth.of(code) == 1
      end

      # Builds options from the option lines of a configuration, applied
      # in order so a later line wins. An unknown option, a value of the
      # wrong kind, an unknown icon set, theme, or background is noted on
      # the configuration and keeps the value before it.
      #: (Config) -> Options
      def self.from_config(config)
        options = Options.new
        i = 0
        n = config.count
        while i < n
          line = config.line_at(i)
          options.apply(config, line) if line.scope == "option"
          i += 1
        end
        options
      end

      # Why a width option's value cannot be set, "" when it lies from low
      # to WIDTH_MAX.
      #: (String, Integer, Integer) -> String
      def self.width_problem(key, value, low)
        return "" if value >= low && value <= WIDTH_MAX
        "#{key} takes a number from #{low} to #{WIDTH_MAX}"
      end

      # Why a number option's value cannot be set, "" when it lies from 0
      # to max.
      #: (String, Integer, Integer) -> String
      def self.range_problem(key, value, max)
        return "" if value >= 0 && value <= max
        "#{key} takes a number from 0 to #{max}"
      end

      # The size option of a slot's side (:left, :right, or :bottom).
      #: (Symbol) -> Integer
      def slot_size(side)
        return layout_left_width if side == :left
        return layout_right_width if side == :right
        layout_panel_height
      end

      # Applies one option line, noting its problem on the configuration.
      #: (Config, RcLine) -> void
      def apply(config, line)
        name = line.name
        kind = KINDS[name]
        if kind.nil?
          config.note(line, "unknown option #{name}")
          return
        end
        words = line.words
        unless RcValue.valid?(words, kind)
          config.note(line, "#{line.key} #{RcValue.expectation(kind)}")
          return
        end
        word = words[0].to_s
        case name
        when "number" then self.number = word == "true"
        when "relativenumber" then self.relativenumber = word == "true"
        when "expandtab" then self.expandtab = word == "true"
        when "autoindent" then self.autoindent = word == "true"
        when "ignorecase" then self.ignorecase = word == "true"
        when "smartcase" then self.smartcase = word == "true"
        when "hlsearch" then self.hlsearch = word == "true"
        when "incsearch" then self.incsearch = word == "true"
        when "startscreen" then self.startscreen = word == "true"
        when "reducedmotion" then self.reducedmotion = word == "true"
        when "cursorline" then self.cursorline = word == "true"
        when "indentguides" then self.indentguides = word == "true"
        when "indentguides.char"
          if Options.guide_char?(word)
            self.indentguides_char = word
          else
            config.note(line, "#{line.key} takes one character one column wide")
          end
        when "tabstop"
          problem = Options.width_problem(line.key, word.to_i, 1)
          if problem.empty?
            self.tabstop = word.to_i
          else
            config.note(line, problem)
          end
        when "shiftwidth"
          problem = Options.width_problem(line.key, word.to_i, 0)
          if problem.empty?
            self.shiftwidth = word.to_i
          else
            config.note(line, problem)
          end
        when "scroll" then self.scroll = word.to_i
        when "scrolloff" then self.scrolloff = word.to_i
        when "timeoutlen" then self.timeoutlen = word.to_i
        when "keyhints.delay"
          problem = Options.range_problem(line.key, word.to_i, KEYHINTS_DELAY_MAX)
          if problem.empty?
            self.keyhints_delay = word.to_i
          else
            config.note(line, problem)
          end
        when "layout.left_width", "layout.right_width", "layout.panel_height"
          problem = Options.range_problem(line.key, word.to_i, SLOT_SIZE_MAX)
          if problem.empty?
            set_slot_size(name, word.to_i)
          else
            config.note(line, problem)
          end
        when "undolevels" then self.undolevels = word.to_i
        when "icons"
          if Icons.set?(word)
            self.icons = word
          else
            config.note(line, "unknown icon set #{word}")
          end
        when "theme"
          if Themes.known?(word)
            self.theme = word
          else
            config.note(line, "unknown theme #{word}")
          end
        when "background"
          if Themes.background?(word)
            self.background = word
          else
            config.note(line, "unknown background #{word}")
          end
        when "breadcrumbs"
          if BREADCRUMBS.include?(word)
            self.breadcrumbs = word
          else
            config.note(line, "unknown breadcrumbs mode #{word}")
          end
        end
      end

      private

      #: (String, Integer) -> void
      def set_slot_size(name, size)
        if name == "layout.left_width"
          self.layout_left_width = size
        elsif name == "layout.right_width"
          self.layout_right_width = size
        else
          self.layout_panel_height = size
        end
      end
    end
  end
end
