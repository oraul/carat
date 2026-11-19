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
      # lines, scored by Matcher over the line's bytes as it scores a path
      # (every query byte in order, ASCII case ignored), ranked by score,
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
          @files = strings
          @file_of = ints
          @numbers = ints
          @texts = strings
          @hits = ints
          @query = ""
          @capped = false
          @more = false
        end

        # Reads every file of paths, relative to root, until MAX_LINES
        # lines are stored.
        #: (Carat::PluginApi::Host, String, Array[String]) -> void
        def load(host, root, paths)
          p = 0
          while p < paths.length
            if @texts.length >= MAX_LINES
              @capped = true
              return
            end
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
          hits = ints
          @hits = hits
          @more = false
          return if query.empty?
          keys = []
          i = 0
          while i < @texts.length
            score = Matcher.score(query, @texts[i])
            keys << Matcher.key(score, @files[@file_of[i]].bytesize, i) if score >= 0
            i += 1
          end
          keys.sort!
          @more = keys.length > MAX_ROWS
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

        # Whether more lines matched than rows were kept.
        #: () -> bool
        def more?
          @more
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

        # The text with each control byte or character shown as a space
        # and each byte of invalid UTF-8 as "?", so the terminal gets no
        # escape sequence from a file.
        #: (String) -> String
        def self.safe(text)
          out = +""
          unless text.valid_encoding?
            i = 0
            while i < text.bytesize
              b = text.getbyte(i).to_i
              out << (b >= 0x80 ? "?" : (b < 0x20 || b == 0x7F ? " " : b.chr))
              i += 1
            end
            return out
          end
          text.each_char do |ch|
            code = ch.ord
            out << (code < 0x20 || (code >= 0x7F && code < 0xA0) ? " " : ch)
          end
          out
        end

        private

        #: (String, Array[String]) -> void
        def add_file(path, lines)
          return if binary?(lines)
          index = @files.length
          @files << path
          i = 0
          while i < lines.length && @texts.length < MAX_LINES
            line = lines[i]
            if line.bytesize > 0
              @file_of << index
              @numbers << i + 1
              @texts << (line.bytesize > MAX_BYTES ? line.byteslice(0, MAX_BYTES).to_s : line)
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

        #: () -> Array[String]
        def strings
          out = [""]
          out.clear
          out
        end

        #: () -> Array[Integer]
        def ints
          out = [0]
          out.clear
          out
        end
      end
    end
  end
end
