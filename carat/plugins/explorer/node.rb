require_relative "../../plugin_api"

module Carat
  module Plugins
    module Explorer
      # One visible line of the tree: the entry's absolute path, its name,
      # its depth below the root (0 for the root line), whether it is a
      # directory (following a symbolic link), and whether it is a symbolic
      # link. A Struct record, so a node read from the tree's list keeps
      # its methods.
      class Node < Struct.new(:path, :name, :depth, :directory, :symlink, keyword_init: true)
        # @rbs @path: String
        # @rbs @name: String
        # @rbs @depth: Integer
        # @rbs @directory: bool
        # @rbs @symlink: bool

        #: (path: String, name: String, depth: Integer, directory: bool, symlink: bool) -> void
        def initialize(path:, name:, depth:, directory:, symlink:)
          super(path: path, name: name, depth: depth, directory: directory, symlink: symlink)
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
