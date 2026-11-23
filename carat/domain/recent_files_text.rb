module Carat
  module Domain
    # The text of the recent files' state file: one absolute path per line,
    # most recent first, each ending in a line feed, and where the file
    # lives. The file is read back from a home directory a project cannot
    # write, but its text is still untrusted: a line is kept only when it
    # is a usable path (see usable?), so a damaged or planted file yields
    # fewer paths, never a line the editor must not show.
    module RecentFilesText
      # The state file's place under the home directory: the directory
      # below it, then the file's name.
      DIRECTORY = ".local/state/carat"
      NAME = "recent_files"
      # The most bytes of the state file that are read.
      LIMIT = 1048576
      # The longest path kept, in bytes.
      MAX_PATH = 4096
      DELETE = 127
      C1_LEAD = 0xC2

      # The state file's path under home, "" when there is no home.
      #: (String) -> String
      def self.location(home)
        return "" if home.empty?
        "#{home}/#{DIRECTORY}/#{NAME}"
      end

      # Whether the line is a path the list may keep: absolute, at most
      # MAX_PATH bytes, valid UTF-8, and free of C0 controls, DEL, and the
      # C1 controls some terminals read as escape introducers.
      #: (String) -> bool
      def self.usable?(line)
        size = line.bytesize
        return false if size < 2 || size > MAX_PATH
        return false unless line.getbyte(0).to_i == 47 && line.valid_encoding?
        i = 0
        while i < size
          b = line.getbyte(i).to_i
          return false if b < 32 || b == DELETE
          return false if b == C1_LEAD && line.getbyte(i + 1).to_i < 0xA0
          i += 1
        end
        true
      end

      # The usable paths of the text, in order, each once, at most limit;
      # a carriage return ending a line is dropped.
      #: (String, Integer) -> Array[String]
      def self.parse(text, limit)
        paths = [""]
        paths.clear
        lines = text.split("\n")
        i = 0
        while i < lines.length && paths.length < limit
          line = lines[i].to_s.chomp("\r")
          paths << line if usable?(line) && !paths.include?(line)
          i += 1
        end
        paths
      end

      # The text of the usable paths, one line each, "" for none.
      #: (Array[String]) -> String
      def self.render(paths)
        text = +""
        paths.each do |path|
          text << path << "\n" if usable?(path)
        end
        text
      end
    end
  end
end
