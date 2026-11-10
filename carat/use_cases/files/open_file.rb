require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/path_info"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "probe_path"

module Carat
  module UseCases
    # Shows a file in the current window: the buffer already listed for
    # that path, which is not read again, the file read from disk, or an
    # empty buffer for a path that does not exist yet, with Vim's message
    # for each. The current buffer's own path is reloaded in place through
    # Buffer#reload, one change that leaves it unmodified, so every window
    # showing it sees the file's text; the closed transaction keeps their
    # cursors inside it. A directory and anything else that is not a
    # regular file (a FIFO, a device, a socket) are refused with Vim's
    # messages and a file longer than PathInfo::BUFFER_LIMIT with E484,
    # as PathInfo#refusal gives them, and the read itself is bounded and
    # never waits, so no path can hang the editor or fill its memory. Any other failure to read or load the file is E484, and a
    # file that is not valid UTF-8 opens with its bytes kept and Vim's
    # "[ILLEGAL BYTE in line N]" in the message.
    class OpenFile
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList
      attr_reader :probe_path #: ProbePath

      #: (files: Ports::FilePort, buffers: Domain::BufferList, probe_path: ProbePath) -> void
      def initialize(files:, buffers:, probe_path:)
        @files = files
        @buffers = buffers
        @probe_path = probe_path
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, path)
        listed = @buffers.for_path(path)
        if !listed.nil? && !listed.equal?(state.buffer)
          @buffers.load(listed)
          return Outcome.success("\"#{path}\" #{listed.line_count}L, #{listed.byte_count}B")
        end
        exists = @files.exist?(path)
        if exists
          refused = @probe_path.call(path).refusal(path, Domain::PathInfo::BUFFER_LIMIT)
          return Outcome.failure(refused) unless refused.empty?
        end
        text = +""
        begin
          text = @files.read(path, Domain::PathInfo::BUFFER_LIMIT) if exists
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
