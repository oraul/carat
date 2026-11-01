# Require graph for test and benchmark programs: the library and the test
# doubles, which the production graph in carat.rb leaves out so the
# shipped binary carries none of them. Only test/*.rb and benchmarks
# require this file; the lint test refuses a double required from bin/ or
# from carat/ outside carat/doubles/ and this file.
require_relative "../carat"

# Test doubles, at the edge beside the drivers
require_relative "doubles/manual_clock"
require_relative "doubles/fake_terminal"
require_relative "doubles/memory_files"
require_relative "doubles/fixed_config"
require_relative "doubles/manual_signals"
require_relative "doubles/editor_harness"
