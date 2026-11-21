require_relative "themes"
require_relative "icons"
require_relative "config"
require_relative "rc_value"
require_relative "utf8"
require_relative "display_width"
require_relative "border_style"

module Carat
  module Domain
    # Typed options with Vim names, plus icons, Carat's own: the icon set
    # plugins draw with, "unicode" (the default), "nerd", or "ascii".
    # timeoutlen is the milliseconds the keymap waits for the rest
    # of an ambiguous binding. scroll is the lines <C-d> and <C-u>
    # scroll, half the window when 0. Only the ones the editor
    # reads are members; :set and local options arrive with the
    # options change. undolevels is how many undo states a buffer
    # keeps. theme names the palette, background says whether the
    # terminal ("terminal") or the palette ("theme") paints the
    # background, and syntax_on is the switch of :syntax on and
    # :syntax off, on from the start as in Neovim. keyhints_delay
    # is the milliseconds a waiting prefix waits before its key
    # hints show, 0 for none. layout_left_width, layout_right_width,
    # and layout_panel_height size the slots of every tab page, 0
    # keeping the size the view asks for. startscreen shows the start
    # screen when the editor starts without a file, and reducedmotion
    # shows its last frame without the animation. cursorline draws the
    # cursor's line in the current window over the CursorLine background.
    # breadcrumbs says when file windows show a winbar: "auto" with two
    # or more file windows, "always", or "never". indentguides draws a
    # guide at each shiftwidth level of file windows' indentation, in
    # indentguides_char, one character one column wide, the cursor's block
    # in the solid SCOPE_GUIDE. winborder is the
    # border style of floats, Neovim's option (BorderStyle). jumptab is
    # "replace" when a jump takes the tab of the buffer it leaves, or
    # "keep", Vim's behavior. gt is "buffers" when gt and gT move between
    # the buffer tabs, or "tabpages", Vim's behavior. showtabline is 0
    # when the tab row never shows, 1 when it shows with two or more tab
    # pages or files, 2 when it always does, Neovim's option. list draws the marks
    # of listchars over the tabs, trailing spaces, and no-break spaces of
    # file windows, Neovim's options and default. All but syntax_on
    # come from option lines of the configuration. A Struct record:
    # mutable, with a reader and a writer per member.
    class Options < Struct.new(:number, :relativenumber, :tabstop, :shiftwidth, :expandtab, :autoindent, :scroll, :scrolloff, :icons, :timeoutlen, :undolevels, :theme, :background, :syntax_on, :ignorecase, :smartcase, :hlsearch, :incsearch, :startscreen, :reducedmotion, :cursorline, :keyhints_delay, :layout_left_width, :layout_right_width, :layout_panel_height, :breadcrumbs, :indentguides, :indentguides_char, :winborder, :jumptab, :gt, :showtabline, :list, :listchars, keyword_init: true)
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
      # @rbs @winborder: String
      # @rbs @jumptab: String
      # @rbs @gt: String
      # @rbs @showtabline: Integer
      # @rbs @list: bool
      # @rbs @listchars: String

      # Vim's defaults, the unicode icon set, the default theme painting its
      # own background, syntax highlighting on, and Neovim's search
      # defaults: hlsearch and incsearch on, ignorecase and smartcase off;
      # the start screen on, with its animation; cursorline and the
      # indent guides and the whitespace marks off, as in Neovim, which
      # draws no guides.
      #: () -> void
      def initialize
        super(number: false, relativenumber: false, tabstop: 8, shiftwidth: 8, expandtab: false, autoindent: false, scroll: 0, scrolloff: 0, icons: "unicode", timeoutlen: 1000, undolevels: 1000, theme: Themes::DEFAULT, background: "theme", syntax_on: true, ignorecase: false, smartcase: false, hlsearch: true, incsearch: true, startscreen: true, reducedmotion: false, cursorline: false, keyhints_delay: KEYHINTS_DELAY, layout_left_width: 0, layout_right_width: 0, layout_panel_height: 0, breadcrumbs: "auto", indentguides: false, indentguides_char: GUIDE_CHAR, winborder: BorderStyle::DEFAULT, jumptab: JUMPTAB_KEEP, gt: GT_TAB_PAGES, showtabline: SHOWTABLINE_ONLY, list: false, listchars: LISTCHARS)
      end

      # The options a configuration line may set, by name, with the kind
      # of value each takes. Those that are not members are checked and
      # kept for the changes that read them.
      KINDS = {
        "number" => "bool", "relativenumber" => "bool", "expandtab" => "bool", "autoindent" => "bool",
        "ignorecase" => "bool", "smartcase" => "bool", "hlsearch" => "bool", "incsearch" => "bool", "wrap" => "bool",
        "startscreen" => "bool", "reducedmotion" => "bool", "cursorline" => "bool", "indentguides" => "bool", "list" => "bool",
        "tabstop" => "integer", "shiftwidth" => "integer", "scroll" => "integer", "scrolloff" => "integer", "timeoutlen" => "integer", "undolevels" => "integer", "keyhints.delay" => "integer", "showtabline" => "integer",
        "layout.left_width" => "integer", "layout.right_width" => "integer", "layout.panel_height" => "integer",
        "clipboard" => "string", "icons" => "string", "theme" => "string", "background" => "string", "breadcrumbs" => "string", "indentguides.char" => "string", "winborder" => "string", "jumptab" => "string", "gt" => "string", "listchars" => "string"
      }

      # The key hints' default wait in milliseconds and the longest one; 0
      # turns the hints off.
      KEYHINTS_DELAY = 300
      KEYHINTS_DELAY_MAX = 10_000

      # The modes of breadcrumbs: the winbar shows with two or more file
      # windows, on every file window, or never.
      BREADCRUMBS = ["auto", "always", "never"]

      # The modes of jumptab: a jump to a buffer with no tab takes the tab
      # of the buffer it leaves, or keeps it beside the target, as Vim.
      JUMPTAB_REPLACE = "replace"
      JUMPTAB_KEEP = "keep"
      JUMPTABS = [JUMPTAB_REPLACE, JUMPTAB_KEEP]

      # The modes of gt: gt and gT move between the buffer tabs, or between
      # the tab pages, as Vim.
      GT_BUFFERS = "buffers"
      GT_TAB_PAGES = "tabpages"
      GTS = [GT_BUFFERS, GT_TAB_PAGES]

      # The values of showtabline, Neovim's option: the tab row never
      # shows, shows only with two or more tab pages or files, or always.
      # An Options built in code keeps the middle one, the rule before the
      # option; the shipped configuration says 2, as Neovim's tabline
      # plugins do.
      SHOWTABLINE_NEVER = 0
      SHOWTABLINE_ONLY = 1
      SHOWTABLINE_ALWAYS = 2

      # The indent guides' default character and the one drawn in its
      # place with the ascii icon set.
      GUIDE_CHAR = "┊"
      GUIDE_ASCII = 124
      # The code point of the solid guide of the cursor's block, │, drawn
      # as GUIDE_ASCII with the ascii icon set.
      SCOPE_GUIDE = 0x2502

      # Neovim's default listchars, and the marks drawn in place of one
      # outside ASCII with the ascii icon set, Neovim's default characters:
      # > and a blank for a tab (> for its last cell), - for a trailing
      # space, + for a no-break space.
      LISTCHARS = "tab:> ,trail:-,nbsp:+"
      TAB_ASCII = 62
      FILL_ASCII = 32
      TRAIL_ASCII = 45
      NBSP_ASCII = 43

      # The largest slot size, in columns or rows.
      SLOT_SIZE_MAX = 500

      # The largest tabstop or shiftwidth, Vim's limit for tabstop: a
      # larger one would make one Tab or >> build a string of that many
      # spaces.
      WIDTH_MAX = 9999

      # The largest scroll or scrolloff, in lines, the largest timeoutlen,
      # in milliseconds, and the most undo states a buffer keeps: far above
      # any useful value, so a project file cannot ask for a huge one.
      LINES_MAX = 9999
      TIMEOUTLEN_MAX = 10_000
      UNDOLEVELS_MAX = 10_000

      # The width a tab takes for display and block columns: tabstop, or 8
      # when tabstop is not positive.
      #: () -> Integer
      def tab_width
        tabstop > 0 ? tabstop : 8
      end

      # Whether a jump to a buffer with no tab takes the tab of the buffer
      # it leaves (jumptab replace), the one place the rule reads it.
      #: () -> bool
      def jump_takes_tab?
        jumptab == JUMPTAB_REPLACE
      end

      # Whether gt and gT move between the buffer tabs (gt buffers), the
      # one place the rule reads it.
      #: () -> bool
      def gt_follows_buffers?
        gt == GT_BUFFERS
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

      # The code point the guides of the cursor's block are drawn with: the
      # solid SCOPE_GUIDE, or | in its place when the icon set is ascii.
      #: () -> Integer
      def scope_guide_code
        return GUIDE_ASCII if icons == "ascii"
        SCOPE_GUIDE
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

      # The code point of mark slot (0, 1, or 2; a tab's first, middle, and
      # last) of a listchars key ("tab", "trail", or "nbsp"), the key's
      # last item winning, or 0 when the key or the slot is not given; one
      # outside ASCII is the key's ASCII mark with the ascii icon set.
      #: (String, Integer) -> Integer
      def listchar_code(key, slot)
        text = listchars
        n = text.bytesize
        at = listchar_value(text, key)
        return 0 if at < 0
        i = 0
        while at < n && text.getbyte(at) != 44
          size = Utf8.size_at(text, at, n)
          if i == slot
            code = Utf8.code_at(text, at, size)
            return code unless code > 127 && icons == "ascii"
            return TRAIL_ASCII if key == "trail"
            return NBSP_ASCII if key == "nbsp"
            return slot == 1 ? FILL_ASCII : TAB_ASCII
          end
          i += 1
          at += size
        end
        0
      end

      # Builds options from the option lines of a configuration, applied
      # in order so a later line wins. An unknown option, a value of the
      # wrong kind, a number out of its range, or an unknown icon set,
      # theme, background, or mode is noted on the configuration and keeps
      # the value before it.
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
        when "list" then self.list = word == "true"
        when "listchars"
          if listchars?(word)
            self.listchars = word
          else
            config.note(line, "#{line.key} takes tab:xy, trail:x, and nbsp:x, comma-separated, each one column wide")
          end
        when "indentguides.char"
          if Options.guide_char?(word)
            self.indentguides_char = word
          else
            config.note(line, "#{line.key} takes one character one column wide")
          end
        when "tabstop"
          value = bounded(config, line, word, 1, WIDTH_MAX)
          self.tabstop = value if value >= 0
        when "shiftwidth"
          value = bounded(config, line, word, 0, WIDTH_MAX)
          self.shiftwidth = value if value >= 0
        when "scroll"
          value = bounded(config, line, word, 0, LINES_MAX)
          self.scroll = value if value >= 0
        when "scrolloff"
          value = bounded(config, line, word, 0, LINES_MAX)
          self.scrolloff = value if value >= 0
        when "timeoutlen"
          value = bounded(config, line, word, 0, TIMEOUTLEN_MAX)
          self.timeoutlen = value if value >= 0
        when "undolevels"
          value = bounded(config, line, word, 0, UNDOLEVELS_MAX)
          self.undolevels = value if value >= 0
        when "keyhints.delay"
          value = bounded(config, line, word, 0, KEYHINTS_DELAY_MAX)
          self.keyhints_delay = value if value >= 0
        when "layout.left_width", "layout.right_width", "layout.panel_height"
          value = bounded(config, line, word, 0, SLOT_SIZE_MAX)
          set_slot_size(name, value) if value >= 0
        when "icons"
          value = named(config, line, word, Icons.set?(word), "icon set")
          self.icons = value unless value.empty?
        when "theme"
          value = named(config, line, word, Themes.known?(word), "theme")
          self.theme = value unless value.empty?
        when "background"
          value = named(config, line, word, Themes.background?(word), "background")
          self.background = value unless value.empty?
        when "breadcrumbs"
          value = named(config, line, word, BREADCRUMBS.include?(word), "breadcrumbs mode")
          self.breadcrumbs = value unless value.empty?
        when "jumptab"
          value = named(config, line, word, JUMPTABS.include?(word), "jumptab mode")
          self.jumptab = value unless value.empty?
        when "showtabline"
          value = bounded(config, line, word, SHOWTABLINE_NEVER, SHOWTABLINE_ALWAYS)
          self.showtabline = value if value >= 0
        when "gt"
          value = named(config, line, word, GTS.include?(word), "gt mode")
          self.gt = value unless value.empty?
        when "winborder"
          value = named(config, line, word, BorderStyle.style?(word), "border style")
          self.winborder = value unless value.empty?
        end
      end

      private

      # The word's number when it lies from low to high, else -1 with the
      # range noted on the configuration; every low is 0 or 1, so -1 is
      # never a value.
      #: (Config, RcLine, String, Integer, Integer) -> Integer
      def bounded(config, line, word, low, high)
        value = word.to_i
        return value if value >= low && value <= high
        config.note(line, "#{line.key} takes a number from #{low} to #{high}")
        -1
      end

      # The word when it is known, else "" with the word noted on the
      # configuration as an unknown what.
      #: (Config, RcLine, String, bool, String) -> String
      def named(config, line, word, known, what)
        return word if known
        config.note(line, "unknown #{what} #{word}")
        ""
      end

      # The byte index where the characters of key's last item start in a
      # listchars value, or -1 when no item names it.
      #: (String, String) -> Integer
      def listchar_value(text, key)
        n = text.bytesize
        found = -1
        start = 0
        while start < n
          stop = item_stop(text, start)
          colon = item_colon(text, start, stop)
          found = colon + 1 if colon < stop && text.byteslice(start, colon - start).to_s == key
          start = stop + 1
        end
        found
      end

      # Whether a word reads as listchars: comma-separated items of tab
      # with two or three characters, trail and nbsp with one, each
      # character one a guide could be (one column wide, not a control);
      # the empty word draws no mark.
      #: (String) -> bool
      def listchars?(word)
        n = word.bytesize
        start = 0
        while start < n
          stop = item_stop(word, start)
          colon = item_colon(word, start, stop)
          return false if colon >= stop
          key = word.byteslice(start, colon - start).to_s
          count = 0
          at = colon + 1
          while at < stop
            size = Utf8.size_at(word, at, stop)
            return false unless Options.guide_char?(word.byteslice(at, size).to_s)
            count += 1
            at += size
          end
          if key == "tab"
            return false if count < 2 || count > 3
          elsif key == "trail" || key == "nbsp"
            return false if count != 1
          else
            return false
          end
          start = stop + 1
        end
        true
      end

      # The byte index of the comma ending the listchars item that starts
      # at start, or the text's end for the last item.
      #: (String, Integer) -> Integer
      def item_stop(text, start)
        n = text.bytesize
        stop = start
        stop += 1 while stop < n && text.getbyte(stop) != 44
        stop
      end

      # The byte index of the colon of the listchars item from start up to
      # stop, or stop when the item has none.
      #: (String, Integer, Integer) -> Integer
      def item_colon(text, start, stop)
        colon = start
        colon += 1 while colon < stop && text.getbyte(colon) != 58
        colon
      end

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
