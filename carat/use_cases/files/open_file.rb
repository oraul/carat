require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../ports/file_port"
require_relative "../outcome"

module Carat
  module UseCases
    # Shows a file in the current window: the buffer already listed for
    # that path, which is not read again, the file read from disk, or an
    # empty buffer for a path that does not exist yet, with Vim's message
    # for each. The current buffer's own path is reloaded in place through
    # Buffer#reload, one change that leaves it unmodified, so every window
    # showing it sees the file's text; the closed transaction keeps their
    # cursors inside it. Any failure to read or load the file is E484, and
    # a file that is not valid UTF-8 opens with its bytes kept and Vim's
    # "[ILLEGAL BYTE in line N]" in the message.
    class OpenFile
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList

      #: (files: Ports::FilePort, buffers: Domain::BufferList) -> void
      def initialize(files:, buffers:)
        @files = files
        @buffers = buffers
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, path)
        listed = @buffers.for_path(path)
        if !listed.nil? && !listed.equal?(state.buffer)
          @buffers.load(listed)
          return Outcome.success("\"#{path}\" #{listed.line_count}L, #{listed.byte_count}B")
        end
        exists = @files.exist?(path)
        text = +""
        begin
          text = @files.read(path) if exists
          fresh = Domain::Buffer.from_text(text, path)
        rescue StandardError => e
          return Outcome.failure("E484: Can't open file #{path}: #{e.message}")
        end
        if listed.nil?
          @buffers.load(fresh)
        else
          listed.reload(fresh.lines)
          listed.line_ending = fresh.line_ending
          state.window.show(listed)
        end
        return Outcome.success("\"#{path}\" [New]") unless exists
        Outcome.success("\"#{path}\"#{illegal_byte(text, fresh)} #{fresh.line_count}L, #{text.bytesize}B")
      end

      private

      # Vim's flag for a file that is not valid UTF-8, naming the first
      # line that holds a byte outside a well-formed sequence; "" for a
      # valid file, which is the only cost a valid file pays.
      #: (String, Domain::Buffer) -> String
      def illegal_byte(text, buffer)
        return "" if text.valid_encoding?
        row = 0
        while row < buffer.line_count
          return " [ILLEGAL BYTE in line #{row + 1}]" unless buffer.line(row).valid_encoding?
          row += 1
        end
        ""
      end
    end
  end
end
