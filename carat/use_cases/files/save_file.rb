require_relative "../../domain/editor_state"
require_relative "../../ports/file_port"
require_relative "../outcome"

module Carat
  module UseCases
    # Writes a buffer to its path, or to the given path, with Vim's
    # messages: the written message, E32, and E212.
    class SaveFile
      # @rbs @files: Ports::FilePort

      #: (Ports::FilePort) -> void
      def initialize(files)
        @files = files
      end

      # Writes the current buffer. path_arg is the command argument; empty
      # means the buffer's own path.
      #: (Domain::EditorState, String) -> Outcome
      def call(state, path_arg)
        write(state.buffer, path_arg)
      end

      # Writes one buffer, which need not be the current one: :wa writes
      # every modified buffer in the list this way.
      #: (Domain::Buffer, String) -> Outcome
      def write(buffer, path_arg)
        own = buffer.path
        path = path_arg.empty? ? own : path_arg
        return Outcome.failure("E32: No file name") if path.nil?
        text = buffer.to_text
        begin
          @files.write(path, text)
        rescue StandardError => e
          return Outcome.failure("E212: Can't open file for writing: #{e.message}")
        end
        if own.nil?
          buffer.path = path
          own = path
        end
        buffer.modified = false if path == own
        Outcome.success("\"#{path}\" #{buffer.line_count}L, #{text.bytesize}B written")
      end
    end
  end
end
