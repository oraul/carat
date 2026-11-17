require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # :bd and :bd N: removes the current buffer, or the one numbered N,
    # from the list. A modified buffer is E89 without the bang. Under
    # option.gt buffers no window closes: every window showing it shows
    # the next listed file buffer, or the one before, or a new empty
    # buffer when none is left (BufferList#withdraw). Under option.gt
    # tabpages the order of Neovim's do_buffer holds: the current window
    # closes while it shows the buffer and another window exists, unless
    # no other listed file buffer exists, every other window showing it
    # closes, and a window still showing it shows that replacement; a
    # file window that is the last of its tab page beside side windows
    # never closes, so no tab page is left with only side windows. A
    # number of no listed file buffer, or a scratch buffer, deletes
    # nothing: E516 with the command as typed.
    class DeleteBuffer
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState, Integer, bool, String) -> Outcome
      def call(state, number, bang, typed)
        target = number == 0 ? state.buffer : @buffers.with_id(number)
        return Outcome.failure("E516: No buffers were deleted: #{typed}") if target.nil? || target.scratch?
        return Outcome.failure("E89: No write since last change for buffer #{target.id} (add ! to override)") if target.modified? && !bang
        other = @buffers.replacement_for(target)
        close_windows(target, other.nil?) unless state.options.gt_follows_buffers?
        if @tabs.windows_showing(target) > 0
          @buffers.withdraw(target, other.nil? ? Domain::Buffer.from_text("", nil) : other)
        else
          @buffers.remove(target)
        end
        Outcome.none
      end

      private

      # The window closing of option.gt tabpages: the current window
      # closes while it shows target, another window exists, and it is
      # not the last file window of its tab page beside side windows,
      # unless target is the last listed file buffer; then every other
      # window showing target closes.
      #: (Domain::Buffer, bool) -> void
      def close_windows(target, last)
        unless last
          while @tabs.window.buffer.equal?(target) && @tabs.total_windows > 1 && !@buffers.lone_file_window?(@tabs.tab)
            @buffers.close_window(@tabs.tab_index, @tabs.tab.current)
          end
        end
        @buffers.close_windows_of(target)
      end
    end
  end
end
