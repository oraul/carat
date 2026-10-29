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

      # Returns {"size" => bytes, "mtime" => seconds, "directory" => 0 or
      # 1, "symlink" => 0 or 1}; directory follows a link, symlink does not.
      # @rbs path: String
      def stat(path)
        raise NotImplementedError, "FilePort#stat"
      end

      # Creates one directory; raises when it exists or its parent does not.
      #: (String) -> void
      def mkdir(path)
        raise NotImplementedError, "FilePort#mkdir"
      end

      # Renames a file or a directory; raises when from is missing.
      #: (String, String) -> void
      def rename(from, to)
        raise NotImplementedError, "FilePort#rename"
      end

      # Deletes a file, a symbolic link, or an empty directory, never
      # recursively; raises for a directory with entries.
      #: (String) -> void
      def delete(path)
        raise NotImplementedError, "FilePort#delete"
      end

      # Returns the absolute path of the working directory.
      # @rbs skip
      def cwd
        raise NotImplementedError, "FilePort#cwd"
      end
    end
  end
end
