require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/buffer"
require_relative "../../domain/buffer_list"
require_relative "../../domain/markdown_text"
require_relative "../outcome"
require_relative "format_docs"

module Carat
  module UseCases
    # <leader>dr: in a window showing a Markdown file (a path ending in .md
    # or .markdown, in any case), shows the file as reading text in a
    # scratch buffer owned by OWNER and titled TITLE and the path: the
    # rows and styles FormatDocs gives with the reading caps, at the
    # window's width capped at MEASURE columns, loaded in the window as
    # PinHover loads its split, so the buffer list releases it when no
    # window shows it. At most MarkdownText::READING_RAW_LIMIT bytes of
    # the lines are gathered. Pressed in a reading view, it loads the file
    # its title names again, its cursor where it was left. Any other
    # buffer, or a file closed meanwhile, is refused with a message.
    class ToggleReading
      OWNER = "reading"
      TITLE = "[reading] "
      MEASURE = 80
      NOT_MARKDOWN = "Not a Markdown buffer"
      CLOSED = "The Markdown file is closed"
      private_constant :OWNER, :TITLE, :MEASURE, :NOT_MARKDOWN, :CLOSED

      attr_reader :buffers #: Domain::BufferList
      attr_reader :format_docs #: FormatDocs

      #: (buffers: Domain::BufferList, format_docs: FormatDocs) -> void
      def initialize(buffers:, format_docs:)
        @buffers = buffers
        @format_docs = format_docs
      end

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        window = state.window
        source = window.buffer
        return back(source) if source.owner == OWNER
        path = source.path_text
        return Outcome.failure(NOT_MARKDOWN) unless markdown?(path)
        width = window.width
        width = MEASURE if width > MEASURE
        width = 1 if width < 1
        docs = @format_docs.call(state, text_of(source), width, true)
        lines = docs.texts
        lines = [""] if lines.empty?
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = OWNER
        buffer.title = TITLE + path
        buffer.styles = docs.styles
        @buffers.load(buffer)
        Outcome.none
      end

      private

      # Loads the file a reading view's title names, refused when the list
      # no longer holds it.
      #: (Domain::Buffer) -> Outcome
      def back(view)
        title = view.title
        path = title.byteslice(TITLE.bytesize, title.bytesize - TITLE.bytesize).to_s
        file = @buffers.for_path(path)
        return Outcome.failure(CLOSED) if file.nil?
        @buffers.load(file)
        Outcome.none
      end

      # Whether the path names a Markdown file by its extension.
      #: (String) -> bool
      def markdown?(path)
        lower = path.downcase
        lower.end_with?(".md") || lower.end_with?(".markdown")
      end

      # The buffer's lines joined by newlines, gathered up to the reading
      # cap so a huge file costs no more than the reader reads.
      #: (Domain::Buffer) -> String
      def text_of(buffer)
        out = +""
        count = buffer.line_count
        row = 0
        while row < count && out.bytesize <= Domain::MarkdownText::READING_RAW_LIMIT
          out << "\n" if row > 0
          out << buffer.line(row)
          row += 1
        end
        out
      end
    end
  end
end
