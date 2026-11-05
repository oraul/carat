require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # :bd and :bd N: removes the current buffer, or the one numbered N,
    # from the list in the order of Neovim's do_buffer. A modified buffer
    # is E89 without the bang. When the current window shows it and no
    # other listed file buffer exists, the other windows showing it close
    # and the window shows a new empty buffer; otherwise the current
    # window closes while it shows the buffer and another window exists,
    # every other window showing it closes, and a last window still
    # showing it shows the next listed file buffer, or the one before. A
    # number of no listed file buffer, or a scratch buffer, deletes
    # nothing: E516 with the command as typed.
    class DeleteBuffer
      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState, Integer, bool, String) -> Outcome
      def call(state, number, bang, typed)
        target = number == 0 ? state.buffer : @buffers.with_id(number)
        return Outcome.failure("E516: No buffers were deleted: #{typed}") if target.nil? || target.scratch?
        return Outcome.failure("E89: No write since last change for buffer #{target.id} (add ! to override)") if target.modified? && !bang
        tabs = @buffers.tabs
        other = @buffers.replacement_for(target)
        if other.nil? && tabs.window.buffer.equal?(target)
          @buffers.close_windows_of(target)
          @buffers.load(Domain::Buffer.from_text("", nil))
        else
          while tabs.window.buffer.equal?(target) && tabs.total_windows > 1
            @buffers.close_window(tabs.tab_index, tabs.tab.current)
          end
          @buffers.close_windows_of(target)
          @buffers.load(other) if !other.nil? && tabs.window.buffer.equal?(target)
        end
        @buffers.remove(target)
        Outcome.none
      end
    end
  end
end
