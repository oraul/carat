module Carat
  module Domain
    # Fuzzy matching of a typed word against a candidate, by bytes. The
    # pattern is cut at underscores into parts; each part's first letter
    # must start a part of the word (its first byte, a byte after a
    # non-word byte, or an uppercase letter after a lowercase one) after
    # the previous part's start, and its other letters follow in order
    # from there, so "fn_na" finds "file_name". ASCII letters match
    # ignoring case; word bytes are ASCII letters, digits, underscore, and
    # every byte of 0x80 or more.
    module FuzzyMatch
      PREFIX_BONUS = 1000
      RUN_BONUS = 2
      LENGTH_ROOM = 256

      # The score of the word for the pattern, -1 when it does not match:
      # PREFIX_BONUS when the word starts with the pattern, RUN_BONUS per
      # letter matched right after the one before, and LENGTH_ROOM less the
      # word's length (none past it), so a match never scores below 0.
      #: (String, String) -> Integer
      def self.score(pattern, word)
        plen = pattern.bytesize
        wlen = word.bytesize
        return -1 if plen == 0
        anchor = -1
        runs = 0
        i = 0
        while i < plen
          stop = i
          stop += 1 while stop < plen && pattern.getbyte(stop).to_i != 0x5F
          if stop > i
            anchor = anchor_of(pattern, i, word, anchor + 1, wlen)
            return -1 if anchor < 0
            matched = follow(pattern, i + 1, stop, word, anchor + 1, wlen)
            return -1 if matched < 0
            runs += matched
          end
          i = stop + 1
        end
        score = runs * RUN_BONUS + (wlen > LENGTH_ROOM ? 0 : LENGTH_ROOM - wlen)
        score += PREFIX_BONUS if prefix?(pattern, word)
        score
      end

      # The bytes of the word the pattern matched in the walk score makes,
      # ascending and each once; empty when it does not match.
      #: (String, String) -> Array[Integer]
      def self.positions(pattern, word)
        out = Array.new(0, 0)
        plen = pattern.bytesize
        wlen = word.bytesize
        return out if plen == 0
        anchor = -1
        i = 0
        while i < plen
          stop = i
          stop += 1 while stop < plen && pattern.getbyte(stop).to_i != 0x5F
          if stop > i
            anchor = anchor_of(pattern, i, word, anchor + 1, wlen)
            if anchor < 0
              out.clear
              return out
            end
            out << anchor
            j = anchor + 1
            k = i + 1
            while k < stop
              want = lower(pattern.getbyte(k).to_i)
              j += 1 while j < wlen && lower(word.getbyte(j).to_i) != want
              if j >= wlen
                out.clear
                return out
              end
              out << j
              j += 1
              k += 1
            end
          end
          i = stop + 1
        end
        out.sort.uniq
      end

      # Whether the word starts with the pattern, ignoring ASCII case.
      #: (String, String) -> bool
      def self.prefix?(pattern, word)
        n = pattern.bytesize
        return false if n > word.bytesize
        i = 0
        while i < n
          return false unless lower(pattern.getbyte(i).to_i) == lower(word.getbyte(i).to_i)
          i += 1
        end
        true
      end

      # The first part start of the word at or after from whose byte
      # matches the pattern's byte at i, -1 when there is none.
      #: (String, Integer, String, Integer, Integer) -> Integer
      def self.anchor_of(pattern, i, word, from, wlen)
        want = lower(pattern.getbyte(i).to_i)
        j = from
        while j < wlen
          return j if lower(word.getbyte(j).to_i) == want && part_start?(word, j)
          j += 1
        end
        -1
      end

      # Matches the pattern's bytes from i to stop in order in the word
      # from j; answers how many followed the byte before directly, -1
      # when one is missing.
      #: (String, Integer, Integer, String, Integer, Integer) -> Integer
      def self.follow(pattern, i, stop, word, j, wlen)
        runs = 0
        last = j - 1
        while i < stop
          want = lower(pattern.getbyte(i).to_i)
          j += 1 while j < wlen && lower(word.getbyte(j).to_i) != want
          return -1 if j >= wlen
          runs += 1 if j == last + 1
          last = j
          j += 1
          i += 1
        end
        runs
      end

      # Whether the byte at j starts a part of the word.
      #: (String, Integer) -> bool
      def self.part_start?(word, j)
        return true if j == 0
        before = word.getbyte(j - 1).to_i
        here = word.getbyte(j).to_i
        return false unless word_byte?(here)
        return true unless word_byte?(before) && before != 0x5F
        before >= 0x61 && before <= 0x7A && here >= 0x41 && here <= 0x5A
      end

      # The byte where the word that ends the text starts: the text's
      # length when it ends in no word byte.
      #: (String) -> Integer
      def self.word_start(text)
        i = text.bytesize
        i -= 1 while i > 0 && word_byte?(text.getbyte(i - 1).to_i)
        i
      end

      # The bytes of the word the text starts with.
      #: (String) -> Integer
      def self.word_length(text)
        n = text.bytesize
        i = 0
        i += 1 while i < n && word_byte?(text.getbyte(i).to_i)
        i
      end

      # Whether the byte belongs to a word: an ASCII letter or digit, an
      # underscore, or a byte of 0x80 or more.
      #: (Integer) -> bool
      def self.word_byte?(b)
        (b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A) || b == 0x5F || b >= 0x80
      end

      #: (Integer) -> Integer
      def self.lower(b)
        b >= 0x41 && b <= 0x5A ? b + 32 : b
      end
    end
  end
end
