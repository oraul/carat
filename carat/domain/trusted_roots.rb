require_relative "config"

module Carat
  module Domain
    # Whether the editor's working directory is trusted to have programs
    # run for it: it is a root of the last language.trusted_roots line,
    # or below one. A language server starts on its own (the language
    # gateway) and a plugin's program runs (the plugin host's
    # run_program) only there, since either runs what a project names.
    # A root word is an absolute path or one under ~, a trailing slash
    # ignored; a word that names no home or holds a . or .. segment
    # trusts nothing, and "/" trusts every absolute directory. No line,
    # or a working directory that is not absolute, trusts nothing.
    module TrustedRoots
      # Whether a root of the configuration covers the directory.
      #: (Config, String, String) -> bool
      def self.cover?(config, cwd, home)
        line = config.last(Config::TRUSTED_ROOTS)
        return false if line.nil? || !cwd.start_with?("/")
        words = line.words
        i = 0
        while i < words.length
          root = root_of(words[i].to_s, home)
          i += 1
          next if root.empty?
          return true if root == "/" || cwd == root || cwd.start_with?("#{root}/")
        end
        false
      end

      # A root word as an absolute path without a trailing slash, "" when
      # it is not absolute, names no home, or holds a . or .. segment.
      #: (String, String) -> String
      def self.root_of(word, home)
        path = word
        if word == "~" || word.start_with?("~/")
          return "" if home.empty?
          path = "#{home}#{word[1, word.length - 1]}"
        end
        return "" unless path.start_with?("/")
        return "" if "#{path}/".include?("/./") || "#{path}/".include?("/../")
        while path.length > 1 && path.end_with?("/")
          path = path[0, path.length - 1].to_s
        end
        path
      end
    end
  end
end
