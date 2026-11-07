module Carat
  module Ports
    # The language services as the core sees them: polled when the editor
    # is idle, started by :LspStart, restarted by :LspRestart, and stopped
    # when the editor ends.
    # No JSON crosses it.
    class LanguageServicePort
      # Reads what the servers sent and tells them about the documents;
      # answers whether the state changed and the screen should be redrawn.
      # @rbs state: Domain::EditorState
      def poll(state)
        raise NotImplementedError, "LanguageServicePort#poll"
      end

      # Starts the current buffer's server if none runs for its language,
      # whether or not the directory is trusted; answers the message to
      # show, "" when a server starts or runs.
      # @rbs state: Domain::EditorState
      def start(state)
        raise NotImplementedError, "LanguageServicePort#start"
      end

      # Stops every server and starts the current buffer's again; answers
      # the message to show, "" when a server starts.
      # @rbs state: Domain::EditorState
      def restart(state)
        raise NotImplementedError, "LanguageServicePort#restart"
      end

      # Notes that a buffer was written, for the next poll to tell its
      # server.
      #: (Domain::Buffer) -> void
      def saved(buffer)
        raise NotImplementedError, "LanguageServicePort#saved"
      end

      # Asks every server to shut down and exit, without waiting.
      #: () -> void
      def stop
        raise NotImplementedError, "LanguageServicePort#stop"
      end
    end
  end
end
