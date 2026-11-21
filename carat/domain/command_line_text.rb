require_relative "motions"

module Carat
  module Domain
    # Where the words of a command line begin and end, for the word keys of
    # the prompts (docs/compatibility.md, Command-line mode): the blank
    # separated words of <S-Left> and <S-Right>, and the runs <C-w> removes,
    # as Neovim reads them. A position is a character index, 0 to the text's
    # length; a blank is a space or a tab.
    module CommandLineText
      # The start of the blank-separated word before the cursor: the blanks
      # before the cursor are skipped, then the word.
      #: (String, Integer) -> Integer
      def self.word_back(text, cursor)
        i = skip_blanks_back(text, cursor)
        while i > 0 && !blank?(text, i - 1)
          i -= 1
        end
        i
      end

      # The start of the next blank-separated word after the cursor, or the
      # end of the text: the rest of the word under the cursor is skipped,
      # then the blanks.
      #: (String, Integer) -> Integer
      def self.word_forward(text, cursor)
        i = cursor
        n = text.length
        while i < n && !blank?(text, i)
          i += 1
        end
        while i < n && blank?(text, i)
          i += 1
        end
        i
      end

      # Where <C-w> starts removing: the blanks before the cursor are
      # skipped, then one run of word characters, or one run of other
      # non-blank characters when the character there is not a word one.
      #: (String, Integer) -> Integer
      def self.removal_start(text, cursor)
        i = skip_blanks_back(text, cursor)
        return i if i == 0
        keyword = keyword?(text, i - 1)
        while i > 0 && !blank?(text, i - 1) && keyword?(text, i - 1) == keyword
          i -= 1
        end
        i
      end

      #: (String, Integer) -> Integer
      def self.skip_blanks_back(text, cursor)
        i = cursor
        while i > 0 && blank?(text, i - 1)
          i -= 1
        end
        i
      end

      #: (String, Integer) -> bool
      def self.blank?(text, index)
        ch = text[index].to_s
        ch == " " || ch == "\t"
      end

      #: (String, Integer) -> bool
      def self.keyword?(text, index)
        Motions.code_class(text[index].to_s.ord, false) == 2
      end
    end
  end
end
