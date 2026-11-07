require_relative "diagnostic"

module Carat
  module Domain
    # The diagnostics a language server published for one file, in its
    # order: built once per publish by the gateway, then shared unchanged
    # by the server's record, the file's buffers, and the status slots'
    # counts, with a typed reader so no caller casts an element.
    class DiagnosticList
      # @rbs @items: Array[untyped]

      #: () -> void
      def initialize
        @items = []
      end

      #: (Diagnostic) -> void
      def add(diagnostic)
        @items << diagnostic
        nil
      end

      #: (Integer) -> Diagnostic
      def at(i)
        @items[i]
      end

      #: () -> Integer
      def count
        @items.length
      end

      #: () -> bool
      def empty?
        @items.empty?
      end
    end
  end
end
