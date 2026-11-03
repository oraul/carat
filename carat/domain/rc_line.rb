module Carat
  module Domain
    # One setting of a configuration file: the label of the file it came
    # from (config/default.caratrc, ~/.config/carat/caratrc, or .caratrc),
    # the file's ordinal in load order, the line number from 1, the dotted
    # key with its scope (the first segment) and name (the rest), and the
    # value's words. A Data value.
    class RcLine < Data.define(:source, :file, :number, :key, :scope, :name, :words)
      # @rbs @source: String
      # @rbs @file: Integer
      # @rbs @number: Integer
      # @rbs @key: String
      # @rbs @scope: String
      # @rbs @name: String
      # @rbs @words: Array[String]

      # Lines of one file sort before the next file's: the order of a
      # problem is the file's ordinal times this plus the line number.
      FILE_SPAN = 4_294_967_296

      # The line of a parse that read a key, splitting the key at its
      # first dot.
      #: (String, Integer, Integer, RcParse) -> RcLine
      def self.from_parse(source, file, number, parsed)
        key = parsed.key
        size = key.bytesize
        dot = 0
        dot += 1 while dot < size && key.getbyte(dot).to_i != 46
        RcLine.new(source: source, file: file, number: number, key: key, scope: key.byteslice(0, dot).to_s, name: key.byteslice(dot + 1, size - dot - 1).to_s, words: parsed.words)
      end

      # The problem as it is reported: "file:line: message".
      #: (String) -> String
      def problem(message)
        "#{source}:#{number}: #{message}"
      end

      # Where the line sorts among every file's lines.
      #: () -> Integer
      def order
        file * FILE_SPAN + number
      end
    end
  end
end
