require_relative "themes"
require_relative "icons"
require_relative "config"
require_relative "rc_value"

module Carat
  module Domain
    # Typed options with Vim names, plus icons, Carat's own: the icon set
    # plugins draw with, "nerd", "unicode", or "ascii". timeoutlen is the
    # milliseconds the keymap waits for the rest of an ambiguous binding.
    # Only the ones the editor reads are members; :set and local options
    # arrive with the options change. undolevels is how many undo states a
    # buffer keeps. theme names the theme, and syntax_on is the switch of
    # :syntax on and :syntax off, on from the start as in Neovim. All but
    # syntax_on come from option lines of the configuration. A Struct
    # record: mutable, with a reader and a writer per member.
    class Options < Struct.new(:number, :relativenumber, :tabstop, :shiftwidth, :expandtab, :autoindent, :scrolloff, :icons, :timeoutlen, :undolevels, :theme, :syntax_on, keyword_init: true)
      # @rbs @number: bool
      # @rbs @relativenumber: bool
      # @rbs @tabstop: Integer
      # @rbs @shiftwidth: Integer
      # @rbs @expandtab: bool
      # @rbs @autoindent: bool
      # @rbs @scrolloff: Integer
      # @rbs @icons: String
      # @rbs @timeoutlen: Integer
      # @rbs @undolevels: Integer
      # @rbs @theme: String
      # @rbs @syntax_on: bool

      # Vim's defaults, the nerd icon set, the default theme, and syntax
      # highlighting on.
      #: () -> void
      def initialize
        super(number: false, relativenumber: false, tabstop: 8, shiftwidth: 8, expandtab: false, autoindent: false, scrolloff: 0, icons: "nerd", timeoutlen: 1000, undolevels: 1000, theme: Themes::DEFAULT, syntax_on: true)
      end

      # The options a configuration line may set, by name, with the kind
      # of value each takes. Those that are not members are checked and
      # kept for the changes that read them.
      KINDS = {
        "number" => "bool", "relativenumber" => "bool", "expandtab" => "bool", "autoindent" => "bool",
        "ignorecase" => "bool", "smartcase" => "bool", "hlsearch" => "bool", "incsearch" => "bool", "wrap" => "bool",
        "tabstop" => "integer", "shiftwidth" => "integer", "scrolloff" => "integer", "timeoutlen" => "integer", "undolevels" => "integer",
        "clipboard" => "string", "icons" => "string", "theme" => "string"
      }

      # Builds options from the option lines of a configuration, applied
      # in order so a later line wins. An unknown option, a value of the
      # wrong kind, an unknown icon set, or an unknown theme is noted on
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
        when "tabstop" then self.tabstop = word.to_i
        when "shiftwidth" then self.shiftwidth = word.to_i
        when "scrolloff" then self.scrolloff = word.to_i
        when "timeoutlen" then self.timeoutlen = word.to_i
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
        end
      end
    end
  end
end
