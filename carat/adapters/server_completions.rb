require_relative "../ports/completion_port"
require_relative "../domain/completion_list"
require_relative "../domain/completion_request"

module Carat
  module Adapters
    # The editor's completion source: the language servers' completions,
    # through the Domain::CompletionRequest it shares with the language
    # gateway. Ready for a buffer whose file type's server runs and
    # completes. Asked for a word it answers the server's answer when the
    # request holds it, else it records the word as wanted, for the
    # gateway to send at an idle tick, and answers an empty list at once,
    # so no key waits; the arrival refreshes the popup. With no server a
    # typed key costs one include? on an empty array.
    class ServerCompletions < Ports::CompletionPort
      # @rbs @none: Domain::CompletionList
      # @rbs @request: Domain::CompletionRequest

      #: () -> void
      def initialize
        @none = Domain::CompletionList.new
        @request = Domain::CompletionRequest.new
      end

      # Answers whether a running server of the buffer's file type
      # completes.
      # @rbs buffer: Domain::Buffer
      def ready?(buffer)
        @request.completes?(buffer.filetype)
      end

      # Answers the server's answer for the word, or records the word and
      # answers an empty list.
      # @rbs buffer: Domain::Buffer
      # @rbs row: Integer
      # @rbs col: Integer
      def candidates(buffer, row, col)
        request = @request
        return request.list if request.answer_for?(buffer.id, row, col)
        request.ask(buffer.id, row, col)
        @none
      end

      # Answers the request shared with the language gateway.
      # @rbs skip
      def request
        @request
      end
    end
  end
end
