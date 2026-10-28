require_relative "../../domain/editor_state"
require_relative "../../ports/file_port"
require_relative "../outcome"

module Carat
  module UseCases
    # Loads a file into the state, or starts an empty buffer for a path that
    # does not exist yet, with Vim's message for each.
    class OpenFile
      # @rbs @files: Ports::FilePort

      #: (Ports::FilePort) -> void
      def initialize(files)
        @files = files
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, path)
        if @files.exist?(path)
          text = +""
          begin
            text = @files.read(path)
          rescue StandardError => e
            return Outcome.failure("E484: Can't open file #{path}: #{e.message}")
          end
          buffer = Domain::Buffer.from_text(text, path)
          state.load(buffer)
          Outcome.success("\"#{path}\" #{buffer.line_count}L, #{text.bytesize}B")
        else
          state.load(Domain::Buffer.from_text("", path))
          Outcome.success("\"#{path}\" [New]")
        end
      end
    end
  end
end
