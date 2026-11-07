module Carat
  module Ports
    # Where completion candidates come from, as the core sees it. It never
    # waits: a source answers what it holds now, and a source that asks a
    # server answers that server's answer for the word, or records the
    # word in its request for the services to send and answers nothing.
    # The strings it gives are untrusted; the menu cleans them.
    class CompletionPort
      # Answers whether the source can give candidates for the buffer;
      # false lets a typed key cost nothing more.
      # @rbs buffer: Domain::Buffer
      def ready?(buffer)
        raise NotImplementedError, "CompletionPort#ready?"
      end

      # Answers the Domain::CompletionList of candidates the source holds
      # for the word that starts at col on row of the buffer.
      # @rbs buffer: Domain::Buffer
      # @rbs row: Integer
      # @rbs col: Integer
      def candidates(buffer, row, col)
        raise NotImplementedError, "CompletionPort#candidates"
      end

      # Answers the Domain::CompletionRequest the source shares with the
      # language services, which send its wanted word and keep the answer;
      # a source that answers at once holds one nobody fills.
      # @rbs skip
      def request
        raise NotImplementedError, "CompletionPort#request"
      end
    end
  end
end
