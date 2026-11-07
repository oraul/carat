module Carat
  module Ports
    # Where completion candidates come from, as the core sees it. It never
    # waits: a source answers what it holds now, and a source that asks a
    # server answers its last response and asks again in the background.
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
    end
  end
end
