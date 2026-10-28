# Require graph for the carat library, innermost layer first.
# Every file is pulled in here once; bin/*.rb and test/*.rb require only this
# file (and test/*.rb also carat/testing.rb).
require_relative "carat/version"
require_relative "carat/domain/json"
require_relative "carat/domain/default_config"
