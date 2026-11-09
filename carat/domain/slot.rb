module Carat
  module Domain
    # One slot of a tab page at an edge of its layout: side is :left or
    # :right for a sidebar, :bottom for the panel. A slot shows one view
    # at a time, a plugin's scratch buffer, in one window of the layout,
    # and lists the titles of the views opened in it since that window
    # was placed, in order, for its header row. Hiding the slot takes the
    # window out of the layout and keeps it here, hidden, so showing it
    # again restores the view where it was; size is the window's width,
    # or the panel's rows, when it was placed or hidden. The slot is shown
    # while its window is a leaf of the layout and shows a scratch buffer:
    # a window closed by any path, or one that took a file, ends it. A
    # Struct record: mutable, with a reader and a writer per member.
    class Slot < Struct.new(:side, :views, :window, :hidden, :size, keyword_init: true)
      # @rbs @side: Symbol
      # @rbs @views: Array[String]
      # @rbs @window: Window?
      # @rbs @hidden: bool
      # @rbs @size: Integer

      # The empty list is stored through the writer, not passed to super,
      # so its element type is the pinned one.
      #: (side: Symbol) -> void
      def initialize(side:)
        super()
        self.side = side
        self.views = []
        self.window = nil
        self.hidden = false
        self.size = 0
      end

      # Whether the slot has a window, shown or hidden.
      #: () -> bool
      def occupied?
        !window.nil?
      end

      # The slot's window; callers check occupied? first.
      #: () -> Window
      def view_window
        current = window
        current.nil? ? Window.new(buffer: Buffer.from_text("", nil)) : current
      end

      # Whether the slot's window is a leaf of the layout showing a scratch
      # buffer.
      #: (Layout) -> bool
      def shown?(layout)
        return false if hidden || !occupied?
        current = view_window
        current.buffer.scratch? && layout.leaf_holding(current) >= 0
      end

      # Whether the slot keeps a hidden window.
      #: () -> bool
      def kept?
        hidden && occupied?
      end

      # Whether the slot keeps a hidden window over the buffer.
      #: (Buffer) -> bool
      def keeps?(target)
        kept? && view_window.buffer.equal?(target)
      end

      # Whether the slot is a sidebar rather than the panel.
      #: () -> bool
      def sidebar?
        side != :bottom
      end

      # Takes a newly placed window showing the view titled title.
      #: (Window, String, Integer) -> void
      def attach(target, title, amount)
        clear
        self.window = target
        self.size = amount
        add_view(title)
      end

      # Lists a view's title after the others unless it is listed.
      #: (String) -> void
      def add_view(title)
        i = 0
        while i < views.length
          return if views[i] == title
          i += 1
        end
        views << title
      end

      # Hides the window, which the layout no longer holds, at its size.
      #: (Integer) -> void
      def hide(amount)
        self.hidden = true
        self.size = amount
      end

      # Forgets the window and the views.
      #: () -> void
      def clear
        self.window = nil
        self.hidden = false
        self.views = []
        self.size = 0
      end
    end
  end
end
