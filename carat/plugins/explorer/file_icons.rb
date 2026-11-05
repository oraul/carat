require_relative "../../plugin_api"

module Carat
  module Plugins
    module Explorer
      # Chooses the icon name of a tree line from the host's icon table:
      # a folder closed or open for a directory, symlink for a link, and
      # for a file the icon of its type from the plugin API's file-icon
      # table, which the buffer tabs share. GROUPS names the file-icon
      # highlight group each icon is drawn in.
      module FileIcons
        GROUPS = Carat::PluginApi::FileIcons::GROUPS

        #: (String, bool, bool, bool) -> String
        def self.name_for(name, directory, expanded, symlink)
          return "symlink" if symlink
          return expanded ? "folder_open" : "folder_closed" if directory
          Carat::PluginApi::FileIcons.file_type(name)
        end
      end
    end
  end
end
