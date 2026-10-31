module Carat
  module Domain
    # What a register holds: text and its kind, :charwise, :linewise, or
    # :blockwise. Linewise text is its lines joined with "\n" and no
    # trailing newline; blockwise text is the rows of the block joined the
    # same way. A Data value.
    class RegisterEntry < Data.define(:text, :kind)
      # @rbs @text: String
      # @rbs @kind: Symbol

      #: (String) -> RegisterEntry
      def self.charwise(text)
        RegisterEntry.new(text, :charwise)
      end

      #: (Array[String]) -> RegisterEntry
      def self.lines(lines)
        RegisterEntry.new(lines.join("\n"), :linewise)
      end

      # A block of rows, as a blockwise visual yank stores it.
      #: (Array[String]) -> RegisterEntry
      def self.block(rows)
        RegisterEntry.new(rows.join("\n"), :blockwise)
      end

      #: () -> bool
      def linewise
        kind == :linewise
      end

      #: () -> bool
      def blockwise
        kind == :blockwise
      end

      # The lines of the entry, or the rows of a block; an empty text is
      # one empty line.
      #: () -> Array[String]
      def lines
        text.empty? ? [""] : text.split("\n", -1)
      end

      # first with second added after it: charwise onto charwise joins the
      # text; when either is linewise the result is linewise with the parts
      # as lines, and otherwise when either is blockwise it is a block with
      # the rows of both. A class method with typed parameters, because a
      # value read from the named-register hash is untyped and a method of
      # a Data instance cannot be reached by dynamic dispatch.
      #: (RegisterEntry, RegisterEntry) -> RegisterEntry
      def self.joined(first, second)
        if first.kind == :linewise || second.kind == :linewise
          RegisterEntry.new(first.text + "\n" + second.text, :linewise)
        elsif first.kind == :blockwise || second.kind == :blockwise
          RegisterEntry.new(first.text + "\n" + second.text, :blockwise)
        else
          RegisterEntry.new(first.text + second.text, :charwise)
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
