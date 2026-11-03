module Carat
  module Domain
    # The filetype of a buffer, from its file name or, when the name says
    # nothing, from a shebang on its first line; "" for none. The table is
    # small and grows with the languages plugins tokenize.
    module Filetype
      # Extensions, after the last dot of the file name, and their type.
      EXTENSIONS = { "rb" => "ruby", "rake" => "ruby", "gemspec" => "ruby", "ru" => "ruby" }

      # Whole file names and their type.
      NAMES = { "Gemfile" => "ruby", "Rakefile" => "ruby", "config.ru" => "ruby" }

      # Programs a shebang may name, and their type.
      PROGRAMS = { "ruby" => "ruby" }

      #: (String?, String) -> String
      def self.detect(path, first_line)
        unless path.nil?
          found = from_name(path)
          return found unless found.empty?
        end
        from_shebang(first_line)
      end

      # The type of a path by its last segment: a whole name, then an
      # extension; "" for none.
      #: (String) -> String
      def self.from_name(path)
        slash = path.rindex("/")
        name = slash.nil? ? path : path[slash + 1, path.length - slash - 1]
        whole = NAMES[name]
        return whole unless whole.nil?
        dot = name.rindex(".")
        return "" if dot.nil? || dot == 0
        found = EXTENSIONS[name[dot + 1, name.length - dot - 1]]
        found.nil? ? "" : found
      end

      # The type a "#!" line names: its program, or the first word after
      # env and env's options, with a version after the name allowed
      # (ruby3.4); "" for none.
      #: (String) -> String
      def self.from_shebang(line)
        return "" unless line.start_with?("#!")
        words = line[2, line.length - 2].split(" ")
        return "" if words.empty?
        program = base(words[0])
        i = 1
        if program == "env"
          program = ""
          while i < words.length
            word = words[i]
            i += 1
            next if word.start_with?("-") || word.include?("=")
            program = base(word)
            break
          end
        end
        program_type(program)
      end

      # The last segment of a program path.
      #: (String) -> String
      def self.base(word)
        slash = word.rindex("/")
        slash.nil? ? word : word[slash + 1, word.length - slash - 1]
      end

      # The type of a program name, its version digits and dots ignored.
      #: (String) -> String
      def self.program_type(program)
        stop = program.length
        while stop > 0
          byte = program.getbyte(stop - 1).to_i
          break unless byte == 46 || (byte >= 48 && byte <= 57)
          stop -= 1
        end
        found = PROGRAMS[program[0, stop]]
        found.nil? ? "" : found
      end
    end
  end
end
