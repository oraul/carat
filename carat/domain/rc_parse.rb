module Carat
  module Domain
    # What RcParser read from one line of a configuration file: the key
    # ("" for a blank or comment line), the value's words, and the error
    # ("" for a line that reads). A Data value.
    class RcParse < Data.define(:key, :words, :error)
      # @rbs @key: String
      # @rbs @words: Array[String]
      # @rbs @error: String

      # Whether the line read.
      #: () -> bool
      def ok?
        error.empty?
      end

      # Whether the line read and holds no setting: blank or a comment.
      #: () -> bool
      def blank?
        error.empty? && key.empty?
      end
    end
  end
end
