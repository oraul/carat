require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/display_width"
require_relative "../outcome"

module Carat
  module UseCases
    # :ls, :buffers, and :files: Neovim's listing of the buffer list, one
    # line per listed file buffer in number order, and the unlisted buffers
    # (those a jump left and the plugins' scratch buffers) too with the
    # bang. A line is the buffer number right-aligned in three columns,
    # five flags (u for an unlisted or scratch buffer; % for the current window's buffer; a when a
    # window shows it, else h; = when read-only, else a blank; + when
    # modified), a space, the quoted name, spaces up to display column 40,
    # and "line N", the cursor line for the current buffer and the line a
    # window last left the others at. Each flag character of the argument keeps only the
    # buffers it names; those for states no buffer here has keep none.
    class ListBuffers
      NAME_END = 40
      NO_NAME = "[No Name]"
      UNMATCHED = "#-xRF?"
      private_constant :NAME_END, :NO_NAME, :UNMATCHED

      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState, String, bool) -> Outcome
      def call(state, flags, bang)
        text = ""
        buffer = next_after(0)
        until buffer.nil?
          if wanted?(state, buffer, flags, bang)
            line = line_of(state, buffer)
            text = text.empty? ? line : text + "\n" + line
          end
          buffer = next_after(buffer.id)
        end
        Outcome.success(text)
      end

      private

      # The buffer with the lowest number above id, or nil: Neovim lists
      # by number, and a jump may move a tab ahead of a lower number.
      #: (Integer) -> Domain::Buffer?
      def next_after(id)
        found = nil
        i = 0
        while i < @buffers.count
          candidate = @buffers.buffer_at(i)
          found = candidate if candidate.id > id && (found.nil? || candidate.id < found.id)
          i += 1
        end
        found
      end

      # Whether the buffer is listed with these flags and bang.
      #: (Domain::EditorState, Domain::Buffer, String, bool) -> bool
      def wanted?(state, buffer, flags, bang)
        scratch = buffer.scratch?
        tabless = buffer.tabless?
        unlisted = flags.include?("u")
        return false if tabless && !bang && !unlisted
        return false if unlisted && !tabless
        return false if flags.include?("+") && !(buffer.modified? && !scratch)
        shown = @buffers.tabs.shown?(buffer)
        return false if flags.include?("a") && !shown
        return false if flags.include?("h") && shown
        return false if flags.include?("%") && !buffer.equal?(state.buffer)
        return false if flags.include?("=") && !buffer.readonly
        i = 0
        while i < UNMATCHED.length
          return false if flags.include?(UNMATCHED[i, 1])
          i += 1
        end
        true
      end

      #: (Domain::EditorState, Domain::Buffer) -> String
      def line_of(state, buffer)
        current = buffer.equal?(state.buffer)
        number = buffer.id.to_s
        head = number.length < 3 ? " " * (3 - number.length) + number : number
        flags = (buffer.tabless? ? "u" : " ") + (current ? "%" : " ") + (@buffers.tabs.shown?(buffer) ? "a" : "h") + (buffer.readonly ? "=" : " ") + (buffer.modified? && !buffer.scratch? ? "+" : " ")
        out = head + flags + " \"" + name_of(buffer) + "\""
        pad = NAME_END - Domain::DisplayWidth.column(out, out.bytesize, 8)
        pad = 1 if pad < 1
        row = current ? state.cursor.row : buffer.last_cursor.row
        out + " " * pad + "line #{row + 1}"
      end

      # The path, a scratch buffer's title, or [No Name].
      #: (Domain::Buffer) -> String
      def name_of(buffer)
        path = buffer.path
        return path unless path.nil?
        buffer.title.empty? ? NO_NAME : buffer.title
      end
    end
  end
end
