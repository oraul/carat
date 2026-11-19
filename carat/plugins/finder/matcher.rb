require_relative "../../plugin_api"

module Carat
  module Plugins
    module Finder
      # Fuzzy matching of a typed query against a relative path, by bytes,
      # ASCII letters ignoring case, allocating nothing. Every byte of the
      # query must appear in the path in order. The query is tried inside
      # the file name first (after the last "/"), which adds NAME_BONUS,
      # then across the whole path. Within the part tried, the leftmost
      # match is found and then tightened from its end backwards, so the
      # span is short; each matched byte scores MATCH, BOUNDARY more at the
      # start of a segment or word, and RUN more right after the matched
      # byte before it, and each byte of the span between matches costs
      # GAP. key packs a score, the path's length, and its listing index
      # into one integer, so sorting the keys orders the matches best
      # first, a shorter path first among equal scores, then by listing.
      # find, word_start?, and word_end? serve the grep picker's substring search
      # (word_byte? and camel? are theirs, and boundary?'s, to share).
      module Matcher
        MATCH = 16
        BOUNDARY = 24
        RUN = 16
        GAP = 2
        NAME_BONUS = 256
        LENGTH_ROOM = 1023
        INDEX_BITS = 20
        INDEX_ROOM = 0xFFFFF

        # The score of the path for the query: -1 when it does not match,
        # 0 for an empty query, never below 0 for a match.
        #: (String, String) -> Integer
        def self.score(query, path)
          return 0 if query.bytesize == 0
          size = path.bytesize
          inside_name = span_score(query, path, name_start(path), size)
          return inside_name + NAME_BONUS if inside_name >= 0
          span_score(query, path, 0, size)
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

        # The byte after the path's last "/", 0 when it has none.
        #: (String) -> Integer
        def self.name_start(path)
          i = path.bytesize
          i -= 1 while i > 0 && path.getbyte(i - 1).to_i != 0x2F
          i
        end

        # The score of the tightest leftmost match of the query in the
        # path's bytes from from to size, -1 when there is none; a match
        # whose gaps cost more than its points scores 0, still a match.
        #: (String, String, Integer, Integer) -> Integer
        def self.span_score(query, path, from, size)
          qlen = query.bytesize
          q = 0
          j = from
          while j < size && q < qlen
            q += 1 if lower(path.getbyte(j).to_i) == lower(query.getbyte(q).to_i)
            j += 1
          end
          return -1 if q < qlen
          stop = j - 1
          start = tighten(query, path, stop)
          points = rate(query, path, start, stop) - GAP * (stop - start + 1 - qlen)
          points < 0 ? 0 : points
        end

        # Walks back from stop, the last byte of a match, matching the
        # query from its end; answers where its first byte matched.
        #: (String, String, Integer) -> Integer
        def self.tighten(query, path, stop)
          q = query.bytesize - 1
          k = stop
          while q >= 0
            q -= 1 if lower(path.getbyte(k).to_i) == lower(query.getbyte(q).to_i)
            k -= 1 if q >= 0
          end
          k
        end

        # The points of the query matched greedily from start to stop.
        #: (String, String, Integer, Integer) -> Integer
        def self.rate(query, path, start, stop)
          qlen = query.bytesize
          points = 0
          q = 0
          last = -2
          j = start
          while j <= stop && q < qlen
            if lower(path.getbyte(j).to_i) == lower(query.getbyte(q).to_i)
              points += MATCH
              points += BOUNDARY if boundary?(path, j)
              points += RUN if j == last + 1
              last = j
              q += 1
            end
            j += 1
          end
          points
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
          n = term.bytesize
          return -1 if n == 0
          first = lower(term.getbyte(0).to_i)
          last = text.bytesize - n
          j = from
          while j <= last
            if lower(text.getbyte(j).to_i) == first
              k = 1
              k += 1 while k < n && lower(text.getbyte(j + k).to_i) == lower(term.getbyte(k).to_i)
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
