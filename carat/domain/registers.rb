require_relative "register_entry"

module Carat
  module Domain
    # The unnamed register and the named registers a to z. Writing to a
    # named register also writes the unnamed one; an uppercase name appends
    # to the lowercase register. The numbered, black hole, and read-only
    # registers arrive with the undo change. A Struct record.
    class Registers < Struct.new(:unnamed, :named)
      # @rbs @unnamed: RegisterEntry?
      # @rbs @named: Hash[String, RegisterEntry]

      #: () -> void
      def initialize
        super(nil, {})
      end

      # A register name this change accepts: the unnamed register's own
      # quote, or a letter.
      #: (String) -> bool
      def self.valid_name?(name)
        name == "\"" || name.match?(/\A[A-Za-z]\z/)
      end

      #: (String, RegisterEntry) -> void
      def write(name, entry)
        self.unnamed = entry
        return if name.empty? || name == "\""
        key = name.downcase
        if key == name
          named[key] = entry
        else
          existing = named[key]
          named[key] = existing.nil? ? entry : RegisterEntry.joined(existing, entry)
        end
      end

      # The entry under name, or nil when it holds nothing.
      #: (String) -> RegisterEntry?
      def read(name)
        return unnamed if name.empty? || name == "\""
        named[name.downcase]
      end
    end
  end
end
