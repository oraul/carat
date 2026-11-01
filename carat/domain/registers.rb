require_relative "register_entry"

module Carat
  module Domain
    # Vim's registers: the unnamed register, the named registers a to z
    # (an uppercase name appends to the lowercase one), the numbered
    # registers 0 to 9 (Array[untyped] of ten entries or nil, read through
    # numbered_at), the small delete register "-", and the read-only
    # registers "." (the text typed in the last insert session), ":" (the
    # last command line run), and "%" (the current file's name, which the
    # caller passes to read_with_file). The black hole "_" takes nothing,
    # and "/" waits for search and holds nothing.
    #
    # Writes are named by what made them, following Neovim's op_yank and
    # op_delete: a yank writes the named register, or "0 when none is
    # named; a delete or change writes the named register, shifts "1 to
    # "8 down and writes "1 when it is big (whole lines, more than one
    # line, or a motion Vim lists), and writes "- when it is small and no
    # register is named. Both write the unnamed register with the new
    # text. A Struct record.
    class Registers < Struct.new(:unnamed, :named, :numbered, :small, :inserted, :command_line)
      # @rbs @unnamed: RegisterEntry?
      # @rbs @named: Hash[String, RegisterEntry]
      # @rbs @numbered: Array[untyped]
      # @rbs @small: RegisterEntry?
      # @rbs @inserted: String
      # @rbs @command_line: String

      # Every register empty.
      #: () -> void
      def initialize
        super(nil, {})
        self.numbered = []
        i = 0
        while i < 10
          numbered << nil
          i += 1
        end
        self.small = nil
        self.inserted = ""
        self.command_line = ""
      end

      # A register name the grammar accepts after the quote key: the
      # unnamed register's own quote, a letter, a digit, or one of
      # - _ . : % /.
      #: (String) -> bool
      def self.valid_name?(name)
        name == "\"" || name.match?(/\A[A-Za-z0-9\-_.:%\/]\z/)
      end

      # Whether the name is a register a delete, change, or yank may not
      # write.
      #: (String) -> bool
      def self.read_only?(name)
        name == "." || name == ":" || name == "%" || name == "/"
      end

      # Whether the name stands for no register in particular.
      #: (String) -> bool
      def self.unnamed?(name)
        name.empty? || name == "\""
      end

      #: (Integer) -> RegisterEntry?
      def numbered_at(i)
        numbered[i]
      end

      # Stores a yank.
      #: (String, RegisterEntry) -> void
      def yank(name, entry)
        return if name == "_"
        if Registers.unnamed?(name)
          numbered[0] = entry
        else
          store(name, entry)
        end
        self.unnamed = entry
        nil
      end

      # Stores a delete or a change; big when it took whole lines, more
      # than one line, or used a motion Vim lists for register 1.
      #: (String, RegisterEntry, bool) -> void
      def delete(name, entry, big)
        return if name == "_"
        plain = Registers.unnamed?(name)
        store(name, entry) unless plain
        if big
          i = 9
          while i > 1
            numbered[i] = numbered[i - 1]
            i -= 1
          end
          numbered[1] = entry
        elsif plain
          self.small = entry
        end
        self.unnamed = entry
        nil
      end

      # The entry under name, or nil when it holds nothing. "%" holds
      # nothing here; read_with_file answers it.
      #: (String) -> RegisterEntry?
      def read(name)
        return unnamed if Registers.unnamed?(name)
        code = name.ord
        return numbered_at(code - 48) if code >= 48 && code <= 57
        return small if name == "-"
        return text_entry(inserted) if name == "."
        return text_entry(command_line) if name == ":"
        return nil if name == "_" || name == "/" || name == "%"
        named[name.downcase]
      end

      # The entry under name, with "%" holding the file name given.
      #: (String, String) -> RegisterEntry?
      def read_with_file(name, path)
        return text_entry(path) if name == "%"
        read(name)
      end

      private

      # Writes a register a command named: a letter (an uppercase one
      # appends), a digit, or "-".
      #: (String, RegisterEntry) -> void
      def store(name, entry)
        code = name.ord
        if code >= 48 && code <= 57
          numbered[code - 48] = entry
          return
        end
        if name == "-"
          self.small = entry
          return
        end
        key = name.downcase
        if key == name
          named[key] = entry
        else
          existing = named[key]
          named[key] = existing.nil? ? entry : RegisterEntry.joined(existing, entry)
        end
        nil
      end

      # A charwise entry of text, nil for none.
      #: (String) -> RegisterEntry?
      def text_entry(text)
        text.empty? ? nil : RegisterEntry.charwise(text)
      end
    end
  end
end
