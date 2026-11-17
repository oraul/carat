module Carat
  module Domain
    # What a root word is, the one rule the configuration reader checks a
    # language.<name>.lsp.root line's root by and the trusted roots
    # (TrustedRoots.root_of) cover a directory by: ~, a path under ~, or
    # an absolute path, with no . or .. segment, so a root names one
    # directory however the working directory is reached.
    module RootWord
      # Whether the word is a root.
      #: (String) -> bool
      def self.root?(word)
        return false unless word == "~" || word.start_with?("~/") || word.start_with?("/")
        path = "#{word}/"
        !path.include?("/./") && !path.include?("/../")
      end
    end
  end
end
