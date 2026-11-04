require_relative "options"
require_relative "search_pattern"
require_relative "vim_pattern"

module Carat
  module Domain
    # The last search, which n and N repeat, and what the screen
    # highlights for search: the pattern as typed, its direction, the
    # pattern compiled under the case options, whether its matches are
    # shown (false after :noh until the next search), and while the
    # search prompt previews (incsearch) the pattern being typed and its
    # first match. stamp grows whenever what is highlighted may have
    # changed, so the presenter repaints the rows it drew with an older
    # one. A Struct record: mutable, with a reader and a writer per
    # member.
    class LastSearch < Struct.new(:pattern, :forward, :compiled, :shown, :stamp, :preview, :preview_row, :preview_col, :preview_end, keyword_init: true)
      # @rbs @pattern: String
      # @rbs @forward: bool
      # @rbs @compiled: SearchPattern
      # @rbs @shown: bool
      # @rbs @stamp: Integer
      # @rbs @preview: SearchPattern
      # @rbs @preview_row: Integer
      # @rbs @preview_col: Integer
      # @rbs @preview_end: Integer

      #: () -> void
      def initialize
        super(pattern: "", forward: true, compiled: SearchPattern.none, shown: false, stamp: 1, preview: SearchPattern.none, preview_row: -1, preview_col: 0, preview_end: 0)
      end

      #: () -> bool
      def any?
        !pattern.empty?
      end

      # A search with this pattern happened: it is the last one and its
      # matches are shown.
      #: (SearchPattern, bool) -> void
      def remember(compiled_pattern, direction)
        self.pattern = compiled_pattern.source
        self.compiled = compiled_pattern
        self.forward = direction
        self.shown = true
        touch
      end

      # :noh: the matches are hidden until the next search.
      #: () -> void
      def hide
        self.shown = false
        touch
      end

      # The matches are shown again, as a repeated search or :set
      # hlsearch does.
      #: () -> void
      def show
        return if shown
        self.shown = true
        touch
      end

      # Compiles the last pattern again under changed case options.
      #: (Options) -> void
      def recompile(options)
        return if pattern.empty?
        self.compiled = VimPattern.compile(pattern, options.ignorecase, options.smartcase)
        touch
      end

      # The pattern being typed at the prompt and its first match, or no
      # match when row is -1.
      #: (SearchPattern, Integer, Integer, Integer) -> void
      def preview_at(typed, row, col, end_col)
        self.preview = typed
        self.preview_row = row
        self.preview_col = col
        self.preview_end = end_col
        touch
      end

      #: () -> void
      def end_preview
        return if preview_row < 0 && !preview.ok?
        self.preview = SearchPattern.none
        self.preview_row = -1
        touch
      end

      # The pattern whose matches the screen draws in the Search group:
      # while a preview is typed the typed pattern, else the last pattern
      # unless hidden; none without hlsearch.
      #: (Options) -> SearchPattern
      def highlighted(options)
        return SearchPattern.none unless options.hlsearch
        return preview if preview.ok?
        return compiled if shown && compiled.ok?
        SearchPattern.none
      end

      # The stamp of what the screen draws for search, 0 when it draws
      # nothing, so a frame without search compares one integer per row.
      #: (Options) -> Integer
      def drawn(options)
        return stamp if preview_row >= 0
        highlighted(options).ok? ? stamp : 0
      end

      #: () -> void
      def touch
        self.stamp = stamp + 1
      end
    end
  end
end
