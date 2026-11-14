require_relative "utf8"

module Carat
  module Domain
    # Splits text at its newlines by walking bytes, so text that is not
    # valid UTF-8 splits as any other: String#split and the regular
    # expressions raise on such text under Spinel, while byteindex and
    # byteslice keep every byte. The answer is the one split("\n", -1)
    # gives, an empty array for empty text.
    module TextLines
      # The pieces of text between its newlines, the piece after the last
      # newline included (empty when the text ends with one). With crlf
      # true a "\r" just before a newline is dropped, as reading a file
      # whose lines end in "\r\n" wants.
      #: (String, bool) -> Array[String]
      def self.split(text, crlf)
        out = Array.new(0, "")
        size = text.bytesize
        return out if size == 0
        start = 0
        while true
          found = text.byteindex("\n", Utf8.boundary(text, start))
          if found.nil?
            out << text.byteslice(start, size - start).to_s
            return out
          end
          stop = found
          stop -= 1 if crlf && stop > start && text.getbyte(stop - 1) == 13
          out << text.byteslice(start, stop - start).to_s
          start = found + 1
        end
        out
      end
    end
  end
end
