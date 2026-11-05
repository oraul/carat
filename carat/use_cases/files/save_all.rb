require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../outcome"
require_relative "save_file"

module Carat
  module UseCases
    # :wa, and the writes of :wqa and :xa: every modified buffer written to
    # its own path through SaveFile, in list order, reporting the last
    # write or the first failure: a modified buffer with no name reports
    # E141 with its buffer number, and the other buffers are still
    # written, as Neovim's do_wqall goes on after an error. A scratch
    # buffer is skipped.
    class SaveAll
      attr_reader :save_file #: SaveFile
      attr_reader :buffers #: Domain::BufferList

      #: (save_file: SaveFile, buffers: Domain::BufferList) -> void
      def initialize(save_file:, buffers:)
        @save_file = save_file
        @buffers = buffers
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        result = Outcome.none
        failed = false
        i = 0
        while i < @buffers.count
          buffer = @buffers.buffer_at(i)
          if buffer.modified? && !buffer.scratch?
            written = buffer.path.nil? ? Outcome.failure("E141: No file name for buffer #{buffer.id}") : @save_file.call(buffer, "")
            if !written.ok && !failed
              result = written
              failed = true
            elsif !failed
              result = written
            end
          end
          i += 1
        end
        result
      end
    end
  end
end
