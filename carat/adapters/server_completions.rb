require_relative "../ports/completion_port"
require_relative "../domain/completion_list"

module Carat
  module Adapters
    # The editor's completion source: the language servers' completions.
    # It asks no server yet (queue item completion-request), so it is
    # never ready, a typed key costs one call, and no popup opens.
    class ServerCompletions < Ports::CompletionPort
      # @rbs @none: Domain::CompletionList

      #: () -> void
      def initialize
        @none = Domain::CompletionList.new
      end

      # Answers false: no server is asked yet.
      # @rbs buffer: Domain::Buffer
      def ready?(buffer)
        false
      end

      # Answers an empty list.
      # @rbs buffer: Domain::Buffer
      # @rbs row: Integer
      # @rbs col: Integer
      def candidates(buffer, row, col)
        @none
      end
    end
  end
end
