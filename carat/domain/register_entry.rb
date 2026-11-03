require_relative "text_lines"

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
        RegisterEntry.new(text: text, kind: :charwise)
      end

      #: (Array[String]) -> RegisterEntry
      def self.lines(lines)
        RegisterEntry.new(text: lines.join("\n"), kind: :linewise)
      end

      # A block of rows, as a blockwise visual yank stores it.
      #: (Array[String]) -> RegisterEntry
      def self.block(rows)
        RegisterEntry.new(text: rows.join("\n"), kind: :blockwise)
      end

      #: () -> bool
      def linewise?
        kind == :linewise
      end

      #: () -> bool
      def blockwise?
        kind == :blockwise
      end

      # The lines of the entry, or the rows of a block; an empty text is
      # one empty line.
      #: () -> Array[String]
      def lines
        text.empty? ? [""] : TextLines.split(text, false)
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
          RegisterEntry.new(text: first.text + "\n" + second.text, kind: :linewise)
        elsif first.kind == :blockwise || second.kind == :blockwise
          RegisterEntry.new(text: first.text + "\n" + second.text, kind: :blockwise)
        else
          RegisterEntry.new(text: first.text + second.text, kind: :charwise)
        end
      end
    end
  end
end
