require_relative "groups"

module Carat
  module Plugins
    module Ruby
      # The words the tokenizer gives a group of their own: Ruby's
      # keywords by kind, the methods that read as keywords (require,
      # attr_reader, private, raise, ...), and the words of a comment that
      # are Todo. A word is looked up by a 48-bit polynomial of its bytes
      # in an open-addressing table of SLOTS integer slots, and confirmed
      # byte by byte, so no substring is made for it.
      class Keywords
        LONGEST = 16
        SLOTS = 256

        WORDS = [
          "def", "undef", "alias",
          "class", "module",
          "if", "elsif", "else", "unless", "case", "when", "then",
          "while", "until", "for",
          "return", "break", "next", "redo", "retry", "yield",
          "begin", "rescue", "ensure", "raise", "fail",
          "true", "false",
          "nil", "self", "__FILE__", "__LINE__", "__dir__", "__method__", "__ENCODING__", "__callee__",
          "and", "or", "not",
          "require", "require_relative", "load", "include", "extend", "prepend", "using",
          "attr_reader", "attr_writer", "attr_accessor", "private", "public", "protected", "module_function", "private_constant", "public_constant",
          "do", "end", "in", "super", "defined?", "BEGIN", "END",
          "TODO", "FIXME", "XXX", "NOTE", "HACK", "OPTIMIZE", "REVIEW"
        ]

        KINDS = [
          Groups::DEFINE, Groups::DEFINE, Groups::DEFINE,
          Groups::STRUCTURE, Groups::STRUCTURE,
          Groups::CONDITIONAL, Groups::CONDITIONAL, Groups::CONDITIONAL, Groups::CONDITIONAL, Groups::CONDITIONAL, Groups::CONDITIONAL, Groups::CONDITIONAL,
          Groups::REPEAT, Groups::REPEAT, Groups::REPEAT,
          Groups::STATEMENT, Groups::STATEMENT, Groups::STATEMENT, Groups::STATEMENT, Groups::STATEMENT, Groups::STATEMENT,
          Groups::EXCEPTION, Groups::EXCEPTION, Groups::EXCEPTION, Groups::EXCEPTION, Groups::EXCEPTION,
          Groups::BOOLEAN, Groups::BOOLEAN,
          Groups::CONSTANT, Groups::CONSTANT, Groups::CONSTANT, Groups::CONSTANT, Groups::CONSTANT, Groups::CONSTANT, Groups::CONSTANT, Groups::CONSTANT,
          Groups::OPERATOR, Groups::OPERATOR, Groups::OPERATOR,
          Groups::INCLUDE, Groups::INCLUDE, Groups::INCLUDE, Groups::INCLUDE, Groups::INCLUDE, Groups::INCLUDE, Groups::INCLUDE,
          Groups::MACRO, Groups::MACRO, Groups::MACRO, Groups::MACRO, Groups::MACRO, Groups::MACRO, Groups::MACRO, Groups::MACRO, Groups::MACRO,
          Groups::KEYWORD, Groups::KEYWORD, Groups::KEYWORD, Groups::KEYWORD, Groups::KEYWORD, Groups::KEYWORD, Groups::KEYWORD,
          Groups::TODO, Groups::TODO, Groups::TODO, Groups::TODO, Groups::TODO, Groups::TODO, Groups::TODO
        ]

        # The keywords after which a value has been read, so a slash that
        # follows divides.
        VALUES = ["end", "self", "nil", "true", "false", "__FILE__", "__LINE__", "__dir__", "__method__", "__ENCODING__", "__callee__", "redo", "retry"]

        # @rbs @hashes: Array[Integer]
        # @rbs @slots: Array[Integer]
        # @rbs @values: Array[Integer]

        #: () -> void
        def initialize
          @hashes = Array.new(SLOTS, -1)
          @slots = Array.new(SLOTS, -1)
          @values = []
          i = 0
          while i < WORDS.length
            word = WORDS[i]
            h = Keywords.hash_of(word, 0, word.bytesize)
            slot = h % SLOTS
            slot = (slot + 1) % SLOTS while @slots[slot] >= 0
            @hashes[slot] = h
            @slots[slot] = i
            @values << (VALUES.include?(word) ? 1 : 0)
            i += 1
          end
        end

        # The position in WORDS of the word text holds in [from, to), or -1.
        #: (String, Integer, Integer) -> Integer
        def find(text, from, to)
          return -1 if to - from > LONGEST || to <= from
          at = lookup(Keywords.hash_of(text, from, to))
          return -1 if at < 0
          word = WORDS[at]
          return -1 unless word.bytesize == to - from
          i = 0
          while i < to - from
            return -1 unless word.getbyte(i) == text.getbyte(from + i)
            i += 1
          end
          at
        end

        # The position in WORDS of the word with a hash, or -1.
        #: (Integer) -> Integer
        def lookup(key)
          slot = key % SLOTS
          while @slots[slot] >= 0
            return @slots[slot] if @hashes[slot] == key
            slot = (slot + 1) % SLOTS
          end
          -1
        end

        # The group of the word at a position in WORDS.
        #: (Integer) -> Integer
        def kind(at)
          KINDS[at]
        end

        # Whether the word at a position in WORDS is a value, after which a
        # slash divides.
        #: (Integer) -> bool
        def value?(at)
          @values[at] == 1
        end

        # The 48-bit polynomial of the bytes [from, to) of text.
        #: (String, Integer, Integer) -> Integer
        def self.hash_of(text, from, to)
          h = 0
          i = from
          while i < to
            h = (h * 131 + text.getbyte(i).to_i) & 0xFFFFFFFFFFFF
            i += 1
          end
          h
        end
      end
    end
  end
end
