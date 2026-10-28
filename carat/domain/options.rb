module Carat
  module Domain
    # Typed options with Vim names. Only the ones the foundation reads are
    # members; :set and local options arrive with the options change. A
    # Struct record: mutable, with a reader and a writer per member.
    class Options < Struct.new(:number, :relativenumber, :tabstop, :shiftwidth, :expandtab, :autoindent, :scrolloff)
      # @rbs @number: bool
      # @rbs @relativenumber: bool
      # @rbs @tabstop: Integer
      # @rbs @shiftwidth: Integer
      # @rbs @expandtab: bool
      # @rbs @autoindent: bool
      # @rbs @scrolloff: Integer

      # Vim's defaults.
      #: () -> void
      def initialize
        super(false, false, 8, 8, false, false, 0)
      end

      # Builds options from the "options" object of a config value. A value
      # of the wrong type keeps the default.
      #: (untyped) -> Options
      def self.from_config(hash)
        options = Options.new
        return options unless hash.is_a?(Hash)
        options.number = flag(hash, "number", options.number)
        options.relativenumber = flag(hash, "relativenumber", options.relativenumber)
        options.tabstop = count(hash, "tabstop", options.tabstop)
        options.shiftwidth = count(hash, "shiftwidth", options.shiftwidth)
        options.expandtab = flag(hash, "expandtab", options.expandtab)
        options.autoindent = flag(hash, "autoindent", options.autoindent)
        options.scrolloff = count(hash, "scrolloff", options.scrolloff)
        options
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
