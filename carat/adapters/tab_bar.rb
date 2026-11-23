require_relative "../domain/editor_state"
require_relative "../domain/buffer_list"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/icons"
require_relative "../domain/messages"

module Carat
  module Adapters
    # Paints the top row of buffer tabs: one tab per listed file buffer in
    # list order, two spaces, the last segment of its path or [No Name],
    # a space, and the modified icon or a space (one cell either way),
    # so two tabs stand two blank cells apart, with no file icon, the tab of the current window's buffer (the
    # file window's while a sidebar has focus) selected in TabLineSel,
    # bold on the editor's background, so the bold and the background
    # carry the selection and no glyph or accent fill separates two
    # tabs; scratch and unlisted buffers get none. While another listed
    # file has the same last segment, the folder holding the file and its
    # slash stand dim before the name ("a/x.rb" beside "b/x.rb").
    # The row starts at the editor's first column, after a left sidebar,
    # whose width above it holds the project and branch (paint_head).
    # From two tab pages their numbers stand at the right end, " 1  2 ",
    # the current one bold in TabLineName and the others in TabLine, and
    # the tabs use the columns before them. Under 16 colors and NO_COLOR
    # (bare=) the row has no fill: the selected tab and page number stay
    # bold and every other name is in Normal. Tabs that do not fit are
    # counted, " <N " before the run shown and " N> " after it; the run
    # starts as early as keeping the current tab in it allows. Names are written from the byte after the path's last slash
    # and every width is counted, so a row costs no object per frame.
    class TabBar
      MARK_CELLS = 1
      # The cells of a tab besides its name and mark: the two leading
      # spaces and the one after the name.
      FRAME_CELLS = 3
      HEAD_DOT = "·"
      HEAD_ASCII_DOT = "-"

      attr_reader :buffers #: Domain::BufferList
      attr_reader :bare #: bool

      # @rbs @bare: bool

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
        @bare = false
      end

      # Draws the row with no fill and Normal for every name but the
      # selected ones, as 16 colors and NO_COLOR ask.
      #: (bool) -> void
      def bare=(value)
        @bare = value
      end

      # Whether the row shows under showtabline with tab_count tab pages,
      # as BufferList#tab_row? says.
      #: (Integer, Integer) -> bool
      def showing?(tab_count, showtabline)
        @buffers.tab_row?(tab_count, showtabline)
      end

      # Paints row 0 of a frame cols wide from column start, the editor's
      # first column, leaving the cells before it to the caller.
      #: (Domain::Frame, Domain::EditorState, Integer, Integer) -> void
      def paint(frame, state, start, cols)
        start = cols if start > cols
        start = 0 if start < 0
        frame.blank(0, start, cols)
        frame.fill(0, start, cols, Domain::Highlight::TAB_LINE_FILL) unless @bare
        quiet = quiet_group
        right = paint_pages(frame, state, start, cols)
        room_width = right - start
        set = state.options.icons
        current = selected_buffer(state)
        list = @buffers
        count = list.count
        last = count - 1
        while last >= 0 && list.buffer_at(last).tabless?
          last -= 1
        end
        return if last < 0
        first = 0
        while list.buffer_at(first).tabless?
          first += 1
        end
        if span_width(first, last) > room_width
          files = list.file_count
          # Room for both counts, " <N " and " N> ", at the widest N
          # put_digits_within may write.
          room = room_width - 2 * (Domain::Frame.digits(files) + 3)
          anchor = list.index_of(current)
          anchor = first if anchor < 0 || current.tabless?
          while first < anchor && span_width(first, anchor) > room
            first = next_file(first)
          end
          last = anchor
          following = next_file(last)
          while following < count && span_width(first, following) <= room
            last = following
            following = next_file(last)
          end
        end
        x = start
        hidden = files_between(0, first)
        if hidden > 0
          x = frame.put_within(0, x, " <", quiet, right)
          x = frame.put_digits_within(0, x, hidden, quiet, right)
          x = frame.put_within(0, x, " ", quiet, right)
        end
        i = first
        while i <= last
          buffer = list.buffer_at(i)
          x = paint_tab(frame, x, right, buffer, buffer.equal?(current), set) unless buffer.tabless?
          i += 1
        end
        hidden = files_between(last + 1, count)
        return if hidden <= 0
        x = frame.put_within(0, x, " ", quiet, right)
        x = frame.put_digits_within(0, x, hidden, quiet, right)
        frame.put_within(0, x, "> ", quiet, right)
      end

      # Paints a sidebar's head on a row over the cells [from, to): a
      # space, the project (the last segment of the base directory,
      # bright), a dot (faint), and the branch (dim) when there is one,
      # in the sidebar's layer. set is the icon set: ascii draws a hyphen
      # for the dot.
      #: (Domain::Frame, Integer, Integer, Integer, String, String) -> void
      def paint_head(frame, row, from, to, branch, set)
        frame.blank(row, from, to)
        path = @buffers.base
        slash = path.byterindex("/")
        name = slash.nil? ? 0 : slash + 1
        name = 0 if name >= path.bytesize
        x = frame.put_from(row, from + 1, path, name, Domain::Highlight::NORMAL, to)
        unless branch.empty?
          if !path.empty?
            x = frame.put_within(row, x, " ", Domain::Highlight::NORMAL, to)
            x = frame.put_within(row, x, set == "ascii" ? HEAD_ASCII_DOT : HEAD_DOT, Domain::Highlight::NON_TEXT, to)
            x = frame.put_within(row, x, " ", Domain::Highlight::NORMAL, to)
          end
          frame.put_within(row, x, branch, Domain::Highlight::MESSAGE_DIM, to)
        end
        frame.lift(row, from, to, Domain::Highlight::SIDEBAR_LAYER)
      end

      private

      # The tab-page numbers at the right end from two tab pages, not
      # before column from; returns the column where they start, cols
      # without them.
      #: (Domain::Frame, Domain::EditorState, Integer, Integer) -> Integer
      def paint_pages(frame, state, from, cols)
        tabs = state.tabs
        pages = tabs.tab_count
        return cols if pages < 2
        width = 0
        t = 0
        while t < pages
          width += Domain::Frame.digits(t + 1) + 2
          t += 1
        end
        start = cols - width
        start = from if start < from
        x = start
        t = 0
        while t < pages
          hl = t == tabs.tab_index ? current_page_group : quiet_group
          x = frame.put_within(0, x, " ", hl, cols)
          x = frame.put_digits_within(0, x, t + 1, hl, cols)
          x = frame.put_within(0, x, " ", hl, cols)
          t += 1
        end
        start
      end

      #: (Domain::Frame, Integer, Integer, Domain::Buffer, bool, String) -> Integer
      def paint_tab(frame, x, limit, buffer, selected, set)
        hl = selected ? Domain::Highlight::TAB_LINE_SELECTED : quiet_group
        x = frame.put_within(0, x, "  ", hl, limit)
        path = buffer.path
        if path.nil?
          x = frame.put_within(0, x, Domain::Messages::NO_NAME, hl, limit)
        elsif shares_name?(buffer)
          x = paint_parent_and_name(frame, x, limit, buffer, path, hl, selected)
        else
          x = frame.put_from(0, x, path, buffer.name_start, hl, limit)
        end
        x = frame.put_within(0, x, " ", hl, limit)
        frame.put_within(0, x, buffer.modified? ? mark(set) : " ", hl, limit)
      end

      # Writes the folder holding the file, with its slash, dim, then the
      # name in hl; the folder is MsgDim on the selected tab's background
      # and TabLine on the others', hl itself when bare. Returns the
      # column after it.
      #: (Domain::Frame, Integer, Integer, Domain::Buffer, String, Integer, bool) -> Integer
      def paint_parent_and_name(frame, x, limit, buffer, path, hl, selected)
        dim = hl
        unless @bare
          dim = selected ? Domain::Highlight::MESSAGE_DIM : Domain::Highlight::TAB_LINE
        end
        from = buffer.parent_start
        named = x + Domain::DisplayWidth.text_width(path, from) - Domain::DisplayWidth.text_width(path, buffer.name_start)
        stop = frame.put_from(0, x, path, from, dim, limit)
        frame.fill(0, named, stop, hl)
        stop
      end

      # Whether another file tab has the last segment of this buffer's
      # path, so two tabs would read alike without their folders. Compared
      # by bytes, nothing allocated.
      #: (Domain::Buffer) -> bool
      def shares_name?(buffer)
        path = buffer.path
        return false if path.nil?
        start = buffer.name_start
        list = @buffers
        count = list.count
        i = 0
        while i < count
          other = list.buffer_at(i)
          i += 1
          next if other.tabless? || other.equal?(buffer)
          return true if same_name?(path, start, other)
        end
        false
      end

      # Whether the last segment of other's path is the bytes of path from
      # start on.
      #: (String, Integer, Domain::Buffer) -> bool
      def same_name?(path, start, other)
        theirs = other.path
        return false if theirs.nil?
        from = other.name_start
        size = path.bytesize - start
        return false if theirs.bytesize - from != size
        k = 0
        while k < size
          return false if path.getbyte(start + k) != theirs.getbyte(from + k)
          k += 1
        end
        true
      end

      # The modified mark of the set, the ascii set's when the set's glyph
      # is wider than the one cell a mark takes.
      #: (String) -> String
      def mark(set)
        glyph = Domain::Icons.glyph("modified", set)
        Domain::DisplayWidth.text_width(glyph, 0) == 1 ? glyph : Domain::Icons.glyph("modified", "ascii")
      end

      # The buffer whose tab is selected: the current window's, or, while
      # a sidebar has focus, the one of the window it opens files in, so
      # the file's tab stays marked; the sidebar's own buffer when no
      # such window exists, which has no tab. A focused float is the
      # current window. Nothing is allocated unless the sidebar's
      # previous window is lost.
      #: (Domain::EditorState) -> Domain::Buffer
      def selected_buffer(state)
        buffer = state.window.buffer
        return buffer unless buffer.tabless?
        page = state.tab
        return buffer if page.floats.focused? || !page.side_window?(page.current)
        leaf = page.editing_leaf
        leaf < 0 ? buffer : page.layout.window_at(leaf).buffer
      end

      # The group of an unselected name: TabLine, or Normal when bare.
      #: () -> Integer
      def quiet_group
        @bare ? Domain::Highlight::NORMAL : Domain::Highlight::TAB_LINE
      end

      # The group of the current tab page's number: bold TabLineName, or
      # TabLineSel, also bold, when bare.
      #: () -> Integer
      def current_page_group
        @bare ? Domain::Highlight::TAB_LINE_SELECTED : Domain::Highlight::TAB_LINE_NAME
      end

      # The cells of one tab, its mark one cell whether modified or not,
      # its folder included while another tab has its name.
      #: (Domain::Buffer) -> Integer
      def tab_width(buffer)
        path = buffer.path
        name = Domain::Messages::NO_NAME.length
        unless path.nil?
          from = shares_name?(buffer) ? buffer.parent_start : buffer.name_start
          name = Domain::DisplayWidth.text_width(path, from)
        end
        name + MARK_CELLS + FRAME_CELLS
      end

      # The cells of the file tabs from list position from to position to.
      #: (Integer, Integer) -> Integer
      def span_width(from, to)
        list = @buffers
        total = 0
        i = from
        while i <= to && i < list.count
          buffer = list.buffer_at(i)
          total += tab_width(buffer) unless buffer.tabless?
          i += 1
        end
        total
      end

      # The list position of the next file buffer after i, the list's
      # count when there is none.
      #: (Integer) -> Integer
      def next_file(i)
        list = @buffers
        j = i + 1
        while j < list.count && list.buffer_at(j).tabless?
          j += 1
        end
        j
      end

      # How many file buffers stand from list position from up to, not
      # including, position to.
      #: (Integer, Integer) -> Integer
      def files_between(from, to)
        list = @buffers
        total = 0
        i = from
        while i < to && i < list.count
          total += 1 unless list.buffer_at(i).tabless?
          i += 1
        end
        total
      end
    end
  end
end
