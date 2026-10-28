module Carat
  module Ports
    # The file system as the use cases see it. Errors raise StandardError
    # subclasses, which the use cases turn into Vim's messages.
    class FilePort
      # Returns the text of the file at path.
      # @rbs path: String
      def read(path)
        raise NotImplementedError, "FilePort#read"
      end

      #: (String, String) -> void
      def write(path, text)
        raise NotImplementedError, "FilePort#write"
      end

      # Returns whether a file or directory exists at path.
      # @rbs path: String
      def exist?(path)
        raise NotImplementedError, "FilePort#exist?"
      end

      # Returns the sorted names of the entries in the directory.
      # @rbs dir: String
      def list(dir)
        raise NotImplementedError, "FilePort#list"
      end

      # Returns {"size" => bytes, "mtime" => seconds, "directory" => 0 or 1}.
      # @rbs path: String
      def stat(path)
        raise NotImplementedError, "FilePort#stat"
      end
    end
  end
end
