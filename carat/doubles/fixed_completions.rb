require_relative "../ports/completion_port"
require_relative "../domain/completion_list"
require_relative "../domain/completion_item"
require_relative "../domain/completion_request"

module Carat
  module Doubles
    # A completion source with a fixed list a test fills: ready once it
    # holds a candidate, the same candidates for every word, and a count
    # of the times it was asked, documentation a test sets per candidate,
    # and a request no service fills. Its strings are kept as given,
    # untrusted, for the menu to clean.
    class FixedCompletions < Ports::CompletionPort
      # @rbs @list: Domain::CompletionList
      # @rbs @asked: Integer
      # @rbs @request: Domain::CompletionRequest
      # @rbs @documents: Array[String]

      attr_reader :asked #: Integer

      #: () -> void
      def initialize
        @list = Domain::CompletionList.new
        @asked = 0
        @request = Domain::CompletionRequest.new
        @documents = [""]
        @documents.clear
      end

      # Adds a candidate as a source would give it.
      #: (String, String, String, String) -> void
      def add(label, kind, detail, text)
        @list.add(Domain::CompletionItem.new(label: label, kind: kind, detail: detail, text: text))
        nil
      end

      # Sets the documentation of the candidate at index, the rest none.
      #: (Integer, String) -> void
      def document(index, text)
        @documents << "" while @documents.length <= index
        @documents[index] = text
        nil
      end

      # Answers whether a candidate was added.
      # @rbs buffer: Domain::Buffer
      def ready?(buffer)
        @list.count > 0
      end

      # Answers every candidate added, and counts the ask.
      # @rbs buffer: Domain::Buffer
      # @rbs row: Integer
      # @rbs col: Integer
      def candidates(buffer, row, col)
        @asked += 1
        @list
      end

      # Answers the documentation set for the candidate, "" for none.
      # @rbs list: Domain::CompletionList
      # @rbs index: Integer
      def documentation(list, index)
        return "" if index < 0 || index >= @documents.length
        @documents[index]
      end

      # Answers a request nobody fills: the double answers at once.
      # @rbs skip
      def request
        @request
      end
    end
  end
end
