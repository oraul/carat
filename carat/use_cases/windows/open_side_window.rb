require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/slot"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # Shows the buffer as a view in the current tab page's slot at side
    # (:left, :right, or :bottom), lists the buffer, and makes the slot's
    # window current. A slot with a window shows the buffer there, letting
    # go of the view it showed, and a hidden one is placed again first; an
    # empty slot gets a new window at its edge, size columns wide (rows for
    # the panel) unless the slot's size option is positive, its id from the
    # tab list, fixed along its edge. E36 when the layout cannot hold it.
    # This is how a plugin's scratch window opens.
    class OpenSideWindow
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState, Domain::Buffer, Integer, Symbol) -> Outcome
      def call(state, buffer, size, side)
        tab = state.tab
        slot = tab.slot(side)
        layout = tab.layout
        if slot.kept? && @buffers.index_of(slot.view_window.buffer) >= 0
          return Outcome.failure(Domain::Messages::E36) if layout.place_slot(slot.view_window, slot.size, side) < 0
          slot.hidden = false
        end
        return reuse(state, slot, buffer) if slot.shown?(layout)
        slot.clear
        window = Domain::Window.new(buffer: buffer)
        if slot.sidebar?
          window.fixed_width = true
        else
          window.fixed_height = true
        end
        configured = state.options.slot_size(side)
        amount = configured > 0 ? configured : size
        id = layout.place_slot(window, amount, side)
        return Outcome.failure(Domain::Messages::E36) if id < 0
        @tabs.adopt(window)
        @buffers.add(buffer)
        slot.attach(window, buffer.title, amount)
        tab.focus(id)
        Outcome.success("")
      end

      private

      # Shows the buffer in the slot's window, letting go of the buffer it
      # showed, and focuses it.
      #: (Domain::EditorState, Domain::Slot, Domain::Buffer) -> Outcome
      def reuse(state, slot, buffer)
        tab = state.tab
        window = slot.view_window
        old = window.buffer
        unless old.equal?(buffer)
          window.show(buffer)
          @buffers.release(old)
        end
        @buffers.add(buffer)
        slot.add_view(buffer.title)
        tab.focus(tab.layout.leaf_holding(window))
        Outcome.success("")
      end
    end
  end
end
