require_relative "config"
require_relative "root_word"

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
          return true if under?(words[i].to_s, cwd, home)
          i += 1
        end
        false
      end

      # Whether the directory is, or is under, a root word: the rule of
      # the trusted roots, which a language.<name>.lsp.root line's root
      # follows too. A word that is no root, or a directory that is not
      # absolute, is under nothing.
      #: (String, String, String) -> bool
      def self.under?(word, cwd, home)
        return false unless cwd.start_with?("/")
        root = root_of(word, home)
        return false if root.empty?
        root == "/" || cwd == root || cwd.start_with?("#{root}/")
      end

      # A root word as an absolute path without a trailing slash, "" when
      # it is not absolute, names no home, or holds a . or .. segment:
      # RootWord's rule, checked on the word with the home expanded.
      #: (String, String) -> String
      def self.root_of(word, home)
        path = word
        if word == "~" || word.start_with?("~/")
          return "" if home.empty?
          path = "#{home}#{word[1, word.length - 1]}"
        end
        return "" unless path.start_with?("/") && RootWord.root?(path)
        while path.length > 1 && path.end_with?("/")
          path = path[0, path.length - 1].to_s
        end
        path
      end
    end
  end
end
