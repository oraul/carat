require_relative "../plugin_api"
require_relative "../domain/editor_state"
require_relative "../domain/buffer_list"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/icons"

module Carat
  module Adapters
    # Paints the top row of buffer tabs: one tab per listed file buffer in
    # list order, a space, its file icon, a space, the last segment of its
    # path or [No Name], a space, the modified icon or a space, and a
    # space, the tab of the current window's buffer selected with its
    # icon in its file-icon group; scratch and unlisted buffers get none. From two tab
    # pages their numbers stand at the right end, " 1  2 ", the current
    # one selected, and the tabs use the columns before them. Tabs that do
    # not fit are counted, " <N " before the run shown and " N> " after
    # it; the run starts as early as keeping the current tab in it
    # allows. Names are written from the byte after the path's last slash
    # and every width is counted, so a row costs no object per frame.
    class TabBar
      NO_NAME = "[No Name]"

      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      # Paints row 0 of a frame cols wide.
      #: (Domain::Frame, Domain::EditorState, Integer) -> void
      def paint(frame, state, cols)
        frame.blank(0, 0, cols)
        frame.fill(0, 0, cols, Domain::Highlight::TAB_LINE_FILL)
        right = paint_pages(frame, state, cols)
        set = state.options.icons
        current = state.window.buffer
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
        if span_width(first, last, set) > right
          files = list.file_count
          room = right - 2 * (Domain::Frame.digits(files) + 3)
          anchor = list.index_of(current)
          anchor = first if anchor < 0 || current.tabless?
          while first < anchor && span_width(first, anchor, set) > room
            first = next_file(first)
          end
          last = anchor
          following = next_file(last)
          while following < count && span_width(first, following, set) <= room
            last = following
            following = next_file(last)
          end
        end
        x = 0
        hidden = files_between(0, first)
        if hidden > 0
          x = frame.put_within(0, x, " <", Domain::Highlight::TAB_LINE, right)
          x = put_number(frame, x, right, hidden)
          x = frame.put_within(0, x, " ", Domain::Highlight::TAB_LINE, right)
        end
        i = first
        while i <= last
          buffer = list.buffer_at(i)
          x = paint_tab(frame, x, right, buffer, buffer.equal?(current), set) unless buffer.tabless?
          i += 1
        end
        hidden = files_between(last + 1, count)
        return if hidden <= 0
        x = frame.put_within(0, x, " ", Domain::Highlight::TAB_LINE, right)
        x = put_number(frame, x, right, hidden)
        frame.put_within(0, x, "> ", Domain::Highlight::TAB_LINE, right)
      end

      private

      # The tab-page numbers at the right end from two tab pages; returns
      # the column where they start, cols without them.
      #: (Domain::Frame, Domain::EditorState, Integer) -> Integer
      def paint_pages(frame, state, cols)
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
        start = 0 if start < 0
        x = start
        t = 0
        while t < pages
          hl = t == tabs.tab_index ? Domain::Highlight::TAB_LINE_SELECTED : Domain::Highlight::TAB_LINE
          x = frame.put_within(0, x, " ", hl, cols)
          x = frame.put_digits(0, x, t + 1, hl) if x + Domain::Frame.digits(t + 1) <= cols
          x = frame.put_within(0, x, " ", hl, cols)
          t += 1
        end
        start
      end

      #: (Domain::Frame, Integer, Integer, Domain::Buffer, bool, String) -> Integer
      def paint_tab(frame, x, limit, buffer, selected, set)
        hl = selected ? Domain::Highlight::TAB_LINE_SELECTED : Domain::Highlight::TAB_LINE
        icon_hl = selected ? icon_group(buffer) : hl
        x = frame.put_within(0, x, " ", hl, limit)
        x = frame.put_within(0, x, Domain::Icons.glyph(buffer.icon, set), icon_hl, limit)
        x = frame.put_within(0, x, " ", hl, limit)
        path = buffer.path
        if path.nil?
          x = frame.put_within(0, x, NO_NAME, hl, limit)
        else
          x = frame.put_from(0, x, path, buffer.name_start, hl, limit)
        end
        x = frame.put_within(0, x, " ", hl, limit)
        x = frame.put_within(0, x, buffer.modified? ? Domain::Icons.glyph("modified", set) : " ", hl, limit)
        frame.put_within(0, x, " ", hl, limit)
      end

      # The file-icon group of the buffer's icon, the tab line's selected
      # group when the name has none.
      #: (Domain::Buffer) -> Integer
      def icon_group(buffer)
        id = Domain::Highlight.token_id(PluginApi::FileIcons.group_of(buffer.icon))
        id < 0 ? Domain::Highlight::TAB_LINE_SELECTED : id
      end

      # The cells of one tab.
      #: (Domain::Buffer, String) -> Integer
      def tab_width(buffer, set)
        path = buffer.path
        name = path.nil? ? NO_NAME.length : Domain::DisplayWidth.text_width(path, buffer.name_start)
        mark = buffer.modified? ? Domain::DisplayWidth.text_width(Domain::Icons.glyph("modified", set), 0) : 1
        Domain::DisplayWidth.text_width(Domain::Icons.glyph(buffer.icon, set), 0) + name + mark + 4
      end

      # The cells of the file tabs from list position from to position to.
      #: (Integer, Integer, String) -> Integer
      def span_width(from, to, set)
        list = @buffers
        total = 0
        i = from
        while i <= to && i < list.count
          buffer = list.buffer_at(i)
          total += tab_width(buffer, set) unless buffer.tabless?
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

      #: (Domain::Frame, Integer, Integer, Integer) -> Integer
      def put_number(frame, x, limit, number)
        return x if x + Domain::Frame.digits(number) > limit
        frame.put_digits(0, x, number, Domain::Highlight::TAB_LINE)
      end
    end
  end
end
