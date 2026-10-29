require_relative "../../plugin_api"

module Carat
  module Plugins
    module Explorer
      # One visible line of the tree: the entry's absolute path, its name,
      # its depth below the root (0 for the root line), whether it is a
      # directory (following a symbolic link), and whether it is a symbolic
      # link. A Struct record, so a node read from the tree's list keeps
      # its methods.
      class Node < Struct.new(:path, :name, :depth, :directory, :symlink)
        # @rbs @path: String
        # @rbs @name: String
        # @rbs @depth: Integer
        # @rbs @directory: bool
        # @rbs @symlink: bool

        #: (String, String, Integer, bool, bool) -> void
        def initialize(path, name, depth, directory, symlink)
          super(path, name, depth, directory, symlink)
        end

        # Whether this is the root line.
        #: () -> bool
        def root?
          depth == 0
        end
      end
    end
  end
end
