module Carat
  module Domain
    # A search pattern compiled for the matching engine: the pattern as
    # typed, the regular expression it became, its size (the states of the
    # compiled form, which every scan is charged by), and the error that
    # refused it, "" when it compiled. A refused pattern holds an empty
    # regular expression that is never run, so the member is never nil.
    # A Data value.
    class SearchPattern < Data.define(:source, :regexp, :size, :error)
      # @rbs @source: String
      # @rbs @size: Integer
      # @rbs @error: String

      #: () -> bool
      def ok?
        error.empty?
      end

      # A refused pattern with the error to show.
      #: (String, String) -> SearchPattern
      def self.refused(source, error)
        SearchPattern.new(source: source, regexp: EMPTY, size: 1, error: error)
      end

      # No pattern: nothing to match or highlight.
      #: () -> SearchPattern
      def self.none
        NONE
      end

      EMPTY = Regexp.new("")
      NONE = SearchPattern.new(source: "", regexp: EMPTY, size: 1, error: "no pattern")
    end
  end
end
