require_relative "../../plugin_api"

module Carat
  module Plugins
    module Finder
      # Matching of a typed query against a relative path, by bytes, ASCII
      # letters ignoring case, allocating nothing. A query is terms between
      # spaces, and the path must match every one, in any order; a term
      # matches in one of two tiers, and nothing else matches. Tier 1: the
      # term is a contiguous substring of the path, ranked by where it
      # lies: inside the file name (after the last "/") starting at a
      # segment or word (boundary?), else elsewhere in the name, else in
      # a directory starting at a segment or word, else elsewhere. Tier 2:
      # the term is a few contiguous runs, in order, each after the first
      # starting at a segment or word (initials and camel humps), at most
      # MAX_RUNS, fewer runs ranking higher. A path's score is its worst
      # term's score, then the sum of the terms'; every tier 1 score is
      # above every tier 2 one. key packs a score, the path's length, and
      # its listing index into one integer, so sorting the keys orders the
      # matches best first, a shorter path first among equal scores, then
      # by listing. find, word_start?, and word_end? serve the grep
      # picker's substring search (word_byte? and camel? are theirs, and
      # boundary?'s, to share).
      module Matcher
        NAME_BOUNDARY = 7
        IN_NAME = 6
        AT_BOUNDARY = 5
        ELSEWHERE = 4
        MAX_RUNS = 4
        SUM_ROOM = 256
        LENGTH_ROOM = 1023
        INDEX_BITS = 20
        INDEX_ROOM = 0xFFFFF

        # The score of the path for the query: -1 when it does not match,
        # 0 for a query with no term, never below 1 for a match otherwise.
        #: (String, String) -> Integer
        def self.score(query, path)
          size = query.bytesize
          worst = -1
          sum = 0
          i = 0
          while i < size
            if query.getbyte(i).to_i == 0x20
              i += 1
            else
              stop = i
              stop += 1 while stop < size && query.getbyte(stop).to_i != 0x20
              one = term_score(query, i, stop, path)
              return -1 if one < 0
              worst = one if worst < 0 || one < worst
              sum += one
              i = stop
            end
          end
          return 0 if worst < 0
          sum = SUM_ROOM - 1 if sum >= SUM_ROOM
          (worst * SUM_ROOM) + sum
        end

        # The sort key of a match: higher for a better score, then for a
        # shorter path, then for an earlier index.
        #: (Integer, Integer, Integer) -> Integer
        def self.key(score, length, index)
          room = length > LENGTH_ROOM ? 0 : LENGTH_ROOM - length
          (((score * (LENGTH_ROOM + 1)) + room) << INDEX_BITS) | (INDEX_ROOM - index)
        end

        # The listing index a key was made with.
        #: (Integer) -> Integer
        def self.index_of(key)
          INDEX_ROOM - (key & INDEX_ROOM)
        end

        # Whether the text holds no byte but spaces: no term to match.
        #: (String) -> bool
        def self.blank?(text)
          i = 0
          while i < text.bytesize
            return false if text.getbyte(i).to_i != 0x20
            i += 1
          end
          true
        end

        # The byte after the path's last "/", 0 when it has none.
        #: (String) -> Integer
        def self.name_start(path)
          i = path.bytesize
          i -= 1 while i > 0 && path.getbyte(i - 1).to_i != 0x2F
          i
        end

        # The score of the query's bytes from from to stop as one term, -1
        # when the path has no match of either tier.
        #: (String, Integer, Integer, String) -> Integer
        def self.term_score(query, from, stop, path)
          j = find_in(query, from, stop, path, name_start(path))
          if j >= 0
            while j >= 0
              return NAME_BOUNDARY if boundary?(path, j)
              j = find_in(query, from, stop, path, j + 1)
            end
            return IN_NAME
          end
          j = find_in(query, from, stop, path, 0)
          if j >= 0
            while j >= 0
              return AT_BOUNDARY if boundary?(path, j)
              j = find_in(query, from, stop, path, j + 1)
            end
            return ELSEWHERE
          end
          runs = 2
          while runs <= MAX_RUNS
            return MAX_RUNS + 1 - runs if runs_match?(query, from, stop, path, 0, runs, true)
            runs += 1
          end
          -1
        end

        # Whether the query's bytes from q to stop match as at most left
        # contiguous runs, in order, in the path from p on, each run
        # starting at a segment or word, the first one anywhere when
        # anywhere. Of the starts that match for one run length only the
        # earliest is tried, since it leaves the most path for the rest.
        #: (String, Integer, Integer, String, Integer, Integer, bool) -> bool
        def self.runs_match?(query, q, stop, path, p, left, anywhere)
          return true if q >= stop
          return false if left == 0
          size = path.bytesize
          want = stop - q
          covered = 0
          s = p
          while s < size && covered < want
            if (anywhere || boundary?(path, s)) && lower(path.getbyte(s).to_i) == lower(query.getbyte(q).to_i)
              reach = run_length(query, q, stop, path, s)
              while covered < reach
                covered += 1
                return true if runs_match?(query, q + covered, stop, path, s + covered, left - 1, false)
              end
            end
            s += 1
          end
          false
        end

        # How many bytes of the query from q to stop equal the path's from s.
        #: (String, Integer, Integer, String, Integer) -> Integer
        def self.run_length(query, q, stop, path, s)
          size = path.bytesize
          n = 0
          n += 1 while q + n < stop && s + n < size && lower(path.getbyte(s + n).to_i) == lower(query.getbyte(q + n).to_i)
          n
        end

        # Whether the byte at j starts a segment or a word: the path's
        # first byte, one after "/", "_", "-", ".", or a space, or an
        # uppercase letter after a lowercase one.
        #: (String, Integer) -> bool
        def self.boundary?(path, j)
          return true if j == 0
          before = path.getbyte(j - 1).to_i
          return true if before == 0x2F || before == 0x5F || before == 0x2D || before == 0x2E || before == 0x20
          camel?(before, path.getbyte(j).to_i)
        end

        # The byte index of the first place at or after from where the
        # term's bytes appear in the text, ASCII letters ignoring case,
        # -1 when they do not (or the term is empty). Allocates nothing.
        #: (String, String, Integer) -> Integer
        def self.find(term, text, from)
          find_in(term, 0, term.bytesize, text, from)
        end

        # find for the bytes of the query from from to stop.
        #: (String, Integer, Integer, String, Integer) -> Integer
        def self.find_in(query, from, stop, text, start)
          n = stop - from
          return -1 if n <= 0
          first = lower(query.getbyte(from).to_i)
          last = text.bytesize - n
          j = start
          while j <= last
            if lower(text.getbyte(j).to_i) == first
              k = 1
              k += 1 while k < n && lower(text.getbyte(j + k).to_i) == lower(query.getbyte(from + k).to_i)
              return j if k >= n
            end
            j += 1
          end
          -1
        end

        # Whether a word starts at j: the text's first byte, a previous byte
        # that is not a letter, digit, or byte of a multi-byte character, or
        # an uppercase letter after a lowercase one. It holds wherever
        # boundary? does, and after a quote or bracket as well.
        #: (String, Integer) -> bool
        def self.word_start?(text, j)
          return true if j == 0
          before = text.getbyte(j - 1).to_i
          return true if camel?(before, text.getbyte(j).to_i)
          !word_byte?(before)
        end

        # Whether a word ends at e, the index just past its last byte:
        # the text's end, or a next byte that is not a letter, digit, or
        # byte of a multi-byte character, or an uppercase letter after a
        # lowercase one (the end that boundary? sees as a word start).
        #: (String, Integer) -> bool
        def self.word_end?(text, e)
          return true if e >= text.bytesize
          here = text.getbyte(e).to_i
          return true unless word_byte?(here)
          camel?(text.getbyte(e - 1).to_i, here)
        end

        # Whether b is part of a word: an ASCII letter or digit, or a byte of
        # 0x80 or more (a multi-byte character).
        #: (Integer) -> bool
        def self.word_byte?(b)
          return true if b >= 0x80
          lowered = lower(b)
          (lowered >= 0x61 && lowered <= 0x7A) || (b >= 0x30 && b <= 0x39)
        end

        # Whether an uppercase letter here follows a lowercase one: the
        # camel-case change that starts a word.
        #: (Integer, Integer) -> bool
        def self.camel?(before, here)
          before >= 0x61 && before <= 0x7A && here >= 0x41 && here <= 0x5A
        end

        #: (Integer) -> Integer
        def self.lower(b)
          b >= 0x41 && b <= 0x5A ? b + 32 : b
        end
      end
    end
  end
end
