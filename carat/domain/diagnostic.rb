module Carat
  module Domain
    # One diagnostic a language server published for a file: its row and
    # column counted from 0 as the server sent them (the column in UTF-16
    # units), the severity (1 error, 2 warning, 3 information, 4 hint),
    # and the message, already stripped of control characters and capped.
    # A Data value.
    class Diagnostic < Data.define(:row, :col, :severity, :message)
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @severity: Integer
      # @rbs @message: String

      # Whether the diagnostic is an error.
      #: () -> bool
      def error?
        severity == 1
      end
    end
  end
end
