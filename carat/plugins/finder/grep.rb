require_relative "../../plugin_api"
require_relative "matcher"

module Carat
  module Plugins
    module Finder
      # The content index of the finder's grep picker: the text of the
      # listed files, read once when the picker opens, and the search
      # over it. Each file is read through the host's read_file, so only
      # its first FILE_ROWS lines are searched, and only when the file is
      # small enough for that request; a file that cannot be read or
      # holds a NUL byte is skipped, and a line is cut at MAX_BYTES.
      # Loading stops at MAX_LINES stored lines.
      #
      # The query is split at spaces into terms, and a line matches when
      # it holds every term as a substring, in any order, ASCII case
      # ignored. Lines rank by more terms found as a whole word
      # (Matcher.word_start? at the start, word_end? at the end), then
      # more hits of the terms, then a shorter file path, then listing
      # order. The rows take each file's best line, in that rank order,
      # then each file's second line, and so on, up to MAX_ROWS. A search
      # checks at most LINE_BUDGET lines from where it starts, and the
      # counts mark the lines it left unchecked. Line text is untrusted,
      # so a row shown goes through safe.
      class Grep
        MAX_ROWS = 200
        MAX_LINES = 400_000
        MAX_BYTES = 400
        FILE_ROWS = 1000
        HIT_ROOM = 255
        LINE_BUDGET = 30_000

        # @rbs @files: Array[String]
        # @rbs @file_of: Array[Integer]
        # @rbs @numbers: Array[Integer]
        # @rbs @texts: Array[String]
        # @rbs @found: Array[Integer]
        # @rbs @scanned: Integer
        # @rbs @matched_files: Integer
        # @rbs @hits: Array[Integer]
        # @rbs @terms: Array[String]
        # @rbs @capped: bool

        #: () -> void
        def initialize
          @files = Grep.no_strings
          @file_of = Grep.no_ints
          @numbers = Grep.no_ints
          @texts = Grep.no_strings
          @found = Grep.no_ints
          @scanned = 0
          @matched_files = 0
          @hits = Grep.no_ints
          @terms = Grep.no_strings
          @capped = false
        end

        # Reads every file of paths, relative to root, until a line does not
        # fit in MAX_LINES stored lines.
        #: (Carat::PluginApi::Host, String, Array[String]) -> void
        def load(host, root, paths)
          p = 0
          while p < paths.length && !@capped
            read = host.read_file(PluginApi::Paths.join(root, paths[p]), FILE_ROWS)
            add_file(paths[p], read.lines) if read.ok
            p += 1
          end
        end

        # Lists the matches of the query in at most MAX_ROWS rows, none
        # for a query with no term (empty, or only spaces). Checks at most
        # LINE_BUDGET lines from where the search starts: a query whose
        # every old term lies inside a new term holds only lines the last
        # search matched, so it checks those again and continues where
        # that search stopped, with the budget the kept matches leave; any
        # other query starts at the first stored line.
        #: (String) -> void
        def search(query)
          terms = split_terms(query)
          narrow = narrows?(terms)
          @terms = terms
          found = Grep.no_ints
          i = 0
          stop = 0
          unless terms.empty?
            budget = LINE_BUDGET
            if narrow
              last = @found
              k = 0
              while k < last.length
                index = Matcher.index_of(last[k])
                score = line_score(@texts[index])
                found << Matcher.key(score, @files[@file_of[index]].bytesize, index) if score >= 0
                k += 1
              end
              i = @scanned
              budget = LINE_BUDGET - found.length
            end
            stop = i + budget
            stop = @texts.length if stop > @texts.length
          end
          while i < stop
            score = line_score(@texts[i])
            found << Matcher.key(score, @files[@file_of[i]].bytesize, i) if score >= 0
            i += 1
          end
          @found = found
          @scanned = i
          rank
        end

        # Whether no search has run, or the query held no term.
        #: () -> bool
        def idle?
          @terms.empty?
        end

        # The rows kept by the last search.
        #: () -> Integer
        def count
          @hits.length
        end

        # The counts for the title: "F of M files, L of N lines", the
        # files the rows show, the files with a match, the matching lines,
        # and the stored lines; a "+" after M and L while the search left
        # lines unchecked, and after N when the store cap cut the tree.
        #: () -> String
        def counts
          more = !@terms.empty? && @scanned < @texts.length ? "+" : ""
          shown = @matched_files > MAX_ROWS ? MAX_ROWS : @matched_files
          stored = @capped ? "#{@texts.length}+" : @texts.length.to_s
          "#{shown} of #{@matched_files}#{more} files, #{@found.length}#{more} of #{stored} lines"
        end

        # The row as shown: path, line number, and the line's text, safe
        # for the terminal.
        #: (Integer) -> String
        def row_text(row)
          i = @hits[row]
          safe("#{@files[@file_of[i]]}:#{@numbers[i]}: #{@texts[i]}")
        end

        #: (Integer) -> String
        def path_at(row)
          @files[@file_of[@hits[row]]]
        end

        # The 1-based line number of the row in its file.
        #: (Integer) -> Integer
        def number_at(row)
          @numbers[@hits[row]]
        end

        # The 0-based column, in characters, of the first byte of the
        # first hit of the query's first term in the row, ASCII case
        # ignored.
        #: (Integer) -> Integer
        def column_at(row)
          return 0 if @terms.empty?
          text = @texts[@hits[row]]
          j = Matcher.find(@terms[0], text, 0)
          return 0 if j < 0
          text.byteslice(0, j).to_s.length
        end

        # An empty list the compiler types as strings.
        #: () -> Array[String]
        def self.no_strings
          out = [""]
          out.clear
          out
        end

        # An empty list the compiler types as integers.
        #: () -> Array[Integer]
        def self.no_ints
          out = [0]
          out.clear
          out
        end

        private

        # The text with each control character and each invisible format
        # or separator character shown as a space and each byte that forms
        # no valid UTF-8 sequence as "?", so the terminal gets no escape
        # sequence from a file, a row cannot reorder its text to show
        # another path or line, and a valid character beside an invalid
        # byte stays whole.
        #: (String) -> String
        def safe(text)
          out = +""
          n = text.bytesize
          i = 0
          while i < n
            b = text.getbyte(i).to_i
            size = utf8_size(b)
            if size == 1
              out << (b < 0x20 || b == 0x7F ? " " : b.chr)
              i += 1
            elsif size > 1 && i + size <= n && text.byteslice(i, size).to_s.valid_encoding?
              ch = text.byteslice(i, size).to_s
              code = ch.ord
              out << (code < 0xA0 || format_control?(code) ? " " : ch)
              i += size
            else
              out << "?"
              i += 1
            end
          end
          out
        end

        # Whether the code point is an invisible format or separator
        # character: a bidirectional embedding, override, isolate, or mark
        # (U+061C, U+200E, U+200F, U+202A to U+202E, U+2066 to U+2069), a
        # zero-width character (U+200B to U+200D, U+FEFF), or the line or
        # paragraph separator (U+2028, U+2029).
        #: (Integer) -> bool
        def format_control?(code)
          code == 0x061C || code == 0xFEFF || (code >= 0x200B && code <= 0x200F) ||
            (code >= 0x2028 && code <= 0x202E) || (code >= 0x2066 && code <= 0x2069)
        end

        # The length of the UTF-8 sequence a lead byte starts, 0 for a byte
        # that starts none.
        #: (Integer) -> Integer
        def utf8_size(b)
          return 1 if b < 0x80
          return 2 if b >= 0xC2 && b <= 0xDF
          return 3 if b >= 0xE0 && b <= 0xEF
          return 4 if b >= 0xF0 && b <= 0xF4
          0
        end

        # The query's terms: its runs of bytes between spaces.
        #: (String) -> Array[String]
        def split_terms(query)
          out = Grep.no_strings
          start = 0
          i = 0
          while i <= query.bytesize
            if i == query.bytesize || query.getbyte(i).to_i == 0x20
              out << query.byteslice(start, i - start).to_s if i > start
              start = i + 1
            end
            i += 1
          end
          out
        end

        # The score of the line for the terms, -1 when one is missing: 256
        # for each term with a whole-word hit, plus the hits of all the
        # terms, at most HIT_ROOM. Allocates nothing.
        #: (String) -> Integer
        def line_score(text)
          words = 0
          hits = 0
          t = 0
          while t < @terms.length
            term = @terms[t]
            j = Matcher.find(term, text, 0)
            return -1 if j < 0
            whole = false
            while j >= 0
              hits += 1
              whole = true if !whole && Matcher.word_start?(text, j) && Matcher.word_end?(text, j + term.bytesize)
              j = Matcher.find(term, text, j + term.bytesize)
            end
            words += 1 if whole
            t += 1
          end
          words * (HIT_ROOM + 1) + (hits > HIT_ROOM ? HIT_ROOM : hits)
        end

        # Whether a search for terms can only match lines the last search
        # matched: the last had a term and each of its terms lies inside
        # one of terms, ASCII case ignored.
        #: (Array[String]) -> bool
        def narrows?(terms)
          return false if @terms.empty? || terms.empty?
          t = 0
          while t < @terms.length
            return false unless inside?(@terms[t], terms)
            t += 1
          end
          true
        end

        # Whether the term lies inside one of terms, ASCII case ignored.
        #: (String, Array[String]) -> bool
        def inside?(term, terms)
          u = 0
          while u < terms.length
            return true if Matcher.find(term, terms[u], 0) >= 0
            u += 1
          end
          false
        end

        # Fills the rows from the matches round by round: round t takes
        # the t-th best line of every file holding that many, best key
        # first, until MAX_ROWS rows. The matches are in index order, so
        # each file's are contiguous; a file keeps its MAX_ROWS best,
        # since a line ranked past that in its file is never shown.
        #: () -> void
        def rank
          hits = Grep.no_ints
          @hits = hits
          found = @found
          sorted = Grep.no_ints
          ends = Grep.no_ints
          run = Grep.no_ints
          j = 0
          while j < found.length
            file = @file_of[Matcher.index_of(found[j])]
            run.clear
            while j < found.length && @file_of[Matcher.index_of(found[j])] == file
              run << found[j]
              j += 1
            end
            run.sort!
            k = run.length > MAX_ROWS ? run.length - MAX_ROWS : 0
            while k < run.length
              sorted << run[k]
              k += 1
            end
            ends << sorted.length
          end
          @matched_files = ends.length
          active = Grep.no_ints
          r = 0
          while r < ends.length
            active << r
            r += 1
          end
          round = Grep.no_ints
          tier = 0
          while hits.length < MAX_ROWS && !active.empty?
            round.clear
            left = Grep.no_ints
            a = 0
            while a < active.length
              r = active[a]
              first = r == 0 ? 0 : ends[r - 1]
              at = ends[r] - 1 - tier
              round << sorted[at]
              left << r if at > first
              a += 1
            end
            round.sort!
            k = round.length - 1
            while k >= 0 && hits.length < MAX_ROWS
              hits << Matcher.index_of(round[k])
              k -= 1
            end
            active = left
            tier += 1
          end
        end

        # The line's first MAX_BYTES bytes, ended before a character the
        # cut would split.
        #: (String) -> String
        def cut(line)
          return line if line.bytesize <= MAX_BYTES
          lead = MAX_BYTES
          back = 0
          while back < 3 && lead > 0 && (line.getbyte(lead).to_i & 0xC0) == 0x80
            lead -= 1
            back += 1
          end
          stop = MAX_BYTES
          stop = lead if lead < MAX_BYTES && lead + utf8_size(line.getbyte(lead).to_i) > MAX_BYTES
          line.byteslice(0, stop).to_s
        end

        #: (String, Array[String]) -> void
        def add_file(path, lines)
          return if binary?(lines)
          index = @files.length
          @files << path
          i = 0
          while i < lines.length
            line = lines[i]
            if line.bytesize > 0
              if @texts.length >= MAX_LINES
                @capped = true
                return
              end
              @file_of << index
              @numbers << i + 1
              @texts << cut(line)
            end
            i += 1
          end
        end

        #: (Array[String]) -> bool
        def binary?(lines)
          i = 0
          while i < lines.length
            return true if lines[i].include?("\0")
            i += 1
          end
          false
        end
      end
    end
  end
end
