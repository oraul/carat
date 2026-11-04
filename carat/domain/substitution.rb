require_relative "search"
require_relative "search_pattern"
require_relative "search_budget"
require_relative "replacement"
require_relative "substituted_line"

module Carat
  module Domain
    # One line of a substitute, as a pure function: the first match of the
    # pattern, or every one, replaced by the expanded string, or only
    # counted. Matches are found as a search finds them, every scan paid
    # from the budget, and every character of replacement text is charged
    # OUTPUT_COST units more, so a command produces at most
    # SearchBudget::SEARCH / OUTPUT_COST characters however the string and
    # the matches multiply. An empty match at the end of the previous one
    # does not count, as in Vim, which also ends the loop.
    module Substitution
      OUTPUT_COST = 16

      # The line after the substitute; the line unchanged with count 0 when
      # nothing matched or the budget stopped.
      #: (SearchPattern, String, String, bool, bool, SearchBudget) -> SubstitutedLine
      def self.line(pattern, line, text, all, count_only, budget)
        searched = Search.searchable(line)
        length = searched.length
        out = +""
        copied = 0
        from = 0
        previous = -1
        count = 0
        while true
          found = Search.match_at(pattern, searched, length, from, budget)
          break if found.nil?
          start = found.begin(0).to_i
          stop = found.end(0).to_i
          if stop == from && from == previous
            break if from >= length
            from += 1
            next
          end
          count += 1
          unless count_only
            out << line[copied, start - copied].to_s
            piece = Replacement.expand(text, line, found)
            budget.charge(piece.bytesize * OUTPUT_COST)
            out << piece
            copied = stop
          end
          from = stop
          previous = stop
          break unless all
        end
        return SubstitutedLine.new(text: line, count: 0) if count == 0 || budget.stopped
        return SubstitutedLine.new(text: line, count: count) if count_only
        out << line[copied, length - copied].to_s
        SubstitutedLine.new(text: out, count: count)
      end
    end
  end
end
