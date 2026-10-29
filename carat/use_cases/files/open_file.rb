require_relative "../../domain/editor_state"
require_relative "../../ports/file_port"
require_relative "../outcome"

module Carat
  module UseCases
    # Shows a file in the current window: the buffer already listed for
    # that path, which is not read again, the file read from disk, or an
    # empty buffer for a path that does not exist yet, with Vim's message
    # for each. The current buffer's own path is reloaded in place so every
    # window showing it sees the file's text.
    class OpenFile
      # @rbs @files: Ports::FilePort

      #: (Ports::FilePort) -> void
      def initialize(files)
        @files = files
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, path)
        listed = state.buffer_for(path)
        if !listed.nil? && !listed.equal?(state.buffer)
          state.load(listed)
          return Outcome.success("\"#{path}\" #{listed.line_count}L, #{listed.byte_count}B")
        end
        text = +""
        if @files.exist?(path)
          begin
            text = @files.read(path)
          rescue StandardError => e
            return Outcome.failure("E484: Can't open file #{path}: #{e.message}")
          end
        end
        fresh = Domain::Buffer.from_text(text, path)
        if listed.nil?
          state.load(fresh)
        else
          listed.lines = fresh.lines
          listed.line_ending = fresh.line_ending
          listed.modified = false
          state.window.show(listed)
          state.clamp_cursors(listed)
        end
        return Outcome.success("\"#{path}\" [New]") unless @files.exist?(path)
        Outcome.success("\"#{path}\" #{fresh.line_count}L, #{text.bytesize}B")
      end
    end
  end
end
