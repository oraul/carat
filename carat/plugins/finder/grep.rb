require_relative "../../plugin_api"
require_relative "matcher"

module Carat
  module Plugins
    module Finder
      # The content index of the finder's grep picker: the text of the
      # listed files, read once when the picker opens, and the search over
      # it. Each file is read through the host's read_file, so only its
      # first FILE_ROWS lines are searched, and only when the file is
      # small enough for that request; a file that cannot be read or holds
      # a NUL byte is skipped, and a line is cut at MAX_BYTES. Loading
      # stops at MAX_LINES stored lines. A search keeps the MAX_ROWS best
      # lines, scored by Matcher over the line's bytes from its start, with no
      # file-name bonus (every query byte in order, ASCII case ignored), ranked by score,
      # then a shorter file path, then listing order. Line text is
      # untrusted, so a row shown goes through safe.
      class Grep
        MAX_ROWS = 200
        MAX_LINES = 100_000
        MAX_BYTES = 400
        FILE_ROWS = 1000

        # @rbs @files: Array[String]
        # @rbs @file_of: Array[Integer]
        # @rbs @numbers: Array[Integer]
        # @rbs @texts: Array[String]
        # @rbs @hits: Array[Integer]
        # @rbs @query: String
        # @rbs @capped: bool
        # @rbs @more: bool

        #: () -> void
        def initialize
          @files = Grep.no_strings
          @file_of = Grep.no_ints
          @numbers = Grep.no_ints
          @texts = Grep.no_strings
          @hits = Grep.no_ints
          @query = ""
          @capped = false
          @more = false
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

        # Keeps the best MAX_ROWS lines for the query; none for an empty
        # one.
        #: (String) -> void
        def search(query)
          @query = query
          hits = Grep.no_ints
          @hits = hits
          @more = false
          return if query.empty?
          keys = Grep.no_ints
          matched = 0
          floor = -1
          i = 0
          while i < @texts.length
            score = Matcher.span_score(query, @texts[i], 0, @texts[i].bytesize)
            if score >= 0
              matched += 1
              key = Matcher.key(score, @files[@file_of[i]].bytesize, i)
              if key > floor
                keys << key
                if keys.length >= MAX_ROWS * 4
                  keys = best(keys)
                  floor = keys[0]
                end
              end
            end
            i += 1
          end
          keys.sort!
          @more = matched > MAX_ROWS
          k = keys.length - 1
          while k >= 0 && hits.length < MAX_ROWS
            hits << Matcher.index_of(keys[k])
            k -= 1
          end
        end

        # Whether no search has run, or the query was empty.
        #: () -> bool
        def idle?
          @query.empty?
        end

        # The rows kept by the last search.
        #: () -> Integer
        def count
          @hits.length
        end

        # The "kept/stored" counts for the title, a "+" after a count that
        # a cap cut short.
        #: () -> String
        def counts
          kept = @more ? "#{@hits.length}+" : @hits.length.to_s
          stored = @capped ? "#{@texts.length}+" : @texts.length.to_s
          "#{kept}/#{stored}"
        end

        # The row as shown: path, line number, and the line's text, safe
        # for the terminal.
        #: (Integer) -> String
        def row_text(row)
          i = @hits[row]
          Grep.safe("#{@files[@file_of[i]]}:#{@numbers[i]}: #{@texts[i]}")
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

        # The 0-based column, in characters, of the first byte of the row
        # that is the query's first byte, ASCII case ignored.
        #: (Integer) -> Integer
        def column_at(row)
          text = @texts[@hits[row]]
          return 0 if @query.empty?
          first = Matcher.lower(@query.getbyte(0).to_i)
          j = 0
          j += 1 while j < text.bytesize && Matcher.lower(text.getbyte(j).to_i) != first
          return 0 if j >= text.bytesize
          text.byteslice(0, j).to_s.length
        end

        # The text with each control character shown as a space and each
        # byte that forms no valid UTF-8 sequence as "?", so the terminal
        # gets no escape sequence from a file and a valid character beside
        # an invalid byte stays whole.
        #: (String) -> String
        def self.safe(text)
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
              out << (ch.ord < 0xA0 ? " " : ch)
              i += size
            else
              out << "?"
              i += 1
            end
          end
          out
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

        # The length of the UTF-8 sequence a lead byte starts, 0 for a byte
        # that starts none.
        #: (Integer) -> Integer
        def self.utf8_size(b)
          return 1 if b < 0x80
          return 2 if b >= 0xC2 && b <= 0xDF
          return 3 if b >= 0xE0 && b <= 0xEF
          return 4 if b >= 0xF0 && b <= 0xF4
          0
        end

        private

        # The MAX_ROWS largest keys, so a search keeps a bounded list.
        #: (Array[Integer]) -> Array[Integer]
        def best(keys)
          keys.sort!
          kept = Grep.no_ints
          k = keys.length - MAX_ROWS
          while k < keys.length
            kept << keys[k]
            k += 1
          end
          kept
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
          stop = lead if lead < MAX_BYTES && lead + Grep.utf8_size(line.getbyte(lead).to_i) > MAX_BYTES
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
