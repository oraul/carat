module Carat
  module Domain
    # The result of looking up a key sequence: kind is :none (unbound and no
    # prefix), :prefix (more keys needed), :match (bound, nothing longer), or
    # :match_prefix (bound, and a longer binding exists). value is the bound
    # action name or remap sequence for :match and :match_prefix.
    # A Data value: equal by value and frozen.
    class KeymapMatch < Data.define(:kind, :value)
    end
  end
end
