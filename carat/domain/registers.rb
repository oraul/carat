module Carat
  module Domain
    # What a register holds: text and whether it is linewise. Linewise text
    # is its lines joined with "\n" and no trailing newline. A Data value.
    class RegisterEntry < Data.define(:text, :linewise)
      #: (String) -> RegisterEntry
      def self.charwise(text)
        RegisterEntry.new(text, false)
      end

      #: (Array[String]) -> RegisterEntry
      def self.lines(lines)
        RegisterEntry.new(lines.join("\n"), true)
      end

      # The lines of the entry; an empty text is one empty line.
      #: () -> Array[String]
      def lines
        text.empty? ? [""] : text.split("\n", -1)
      end

      # first with second added after it: charwise onto charwise joins the
      # text; when either is linewise the result is linewise with the parts
      # as lines. A class method with typed parameters, because a value
      # read from the named-register hash is untyped and a method of a Data
      # instance cannot be reached by dynamic dispatch.
      #: (RegisterEntry, RegisterEntry) -> RegisterEntry
      def self.joined(first, second)
        if first.linewise || second.linewise
          RegisterEntry.new(first.text + "\n" + second.text, true)
        else
          RegisterEntry.new(first.text + second.text, false)
        end
      end
    end

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
