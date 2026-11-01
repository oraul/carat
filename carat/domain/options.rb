module Carat
  module Domain
    # Typed options with Vim names, plus icons, Carat's own: the icon set
    # plugins draw with, "nerd", "unicode", or "ascii". timeoutlen is the
    # milliseconds the keymap waits for the rest of an ambiguous binding,
    # from the top level of the configuration. Only the ones the
    # editor reads are members; :set and local options arrive with the
    # options change. undolevels is how many undo states a buffer keeps. A
    # Struct record: mutable, with a reader and a writer per member.
    class Options < Struct.new(:number, :relativenumber, :tabstop, :shiftwidth, :expandtab, :autoindent, :scrolloff, :icons, :timeoutlen, :undolevels)
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

      # Vim's defaults, and the nerd icon set.
      #: () -> void
      def initialize
        super(false, false, 8, 8, false, false, 0, "nerd", 1000, 1000)
      end

      # Builds options from a configuration value: the members of its
      # "options" object and its top-level "timeoutlen". A value that is
      # missing or of the wrong type keeps Vim's default.
      #: (untyped) -> Options
      def self.from_config(config)
        options = Options.new
        return options unless config.is_a?(Hash)
        options.timeoutlen = count(config, "timeoutlen", options.timeoutlen)
        hash = config["options"]
        return options unless hash.is_a?(Hash)
        options.number = flag(hash, "number", options.number)
        options.relativenumber = flag(hash, "relativenumber", options.relativenumber)
        options.tabstop = count(hash, "tabstop", options.tabstop)
        options.shiftwidth = count(hash, "shiftwidth", options.shiftwidth)
        options.expandtab = flag(hash, "expandtab", options.expandtab)
        options.autoindent = flag(hash, "autoindent", options.autoindent)
        options.scrolloff = count(hash, "scrolloff", options.scrolloff)
        options.icons = icon_set(hash, "icons", options.icons)
        options.undolevels = count(hash, "undolevels", options.undolevels)
        options
      end

      #: (untyped, String, String) -> String
      def self.icon_set(hash, key, default)
        value = hash[key]
        return value if value.is_a?(String) && Icons.set?(value)
        default
      end

      #: (untyped, String, bool) -> bool
      def self.flag(hash, key, default)
        value = hash[key]
        return true if value == true
        return false if value == false
        default
      end

      #: (untyped, String, Integer) -> Integer
      def self.count(hash, key, default)
        value = hash[key]
        return value if value.is_a?(Integer) && value >= 0
        default
      end
    end
  end
end
