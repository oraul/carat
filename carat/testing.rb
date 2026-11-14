module Carat
  # The test harness. Each test/*.rb program builds a Testing instance, runs
  # its checks, and calls finish, which prints a summary and exits non-zero on
  # failure. Output is deterministic so spin can diff it against the committed
  # .expected snapshot. No reflection, no autodiscovery.
  class Testing
    # @rbs @name: String
    # @rbs @passed: Integer
    # @rbs @failed: Integer
    # @rbs @out: IO

    #: (String) -> void
    def initialize(name)
      @name = name
      @passed = 0
      @failed = 0
      @out = STDOUT
    end

    #: (untyped, untyped, String) -> void
    def assert_equal(expected, actual, label)
      if expected == actual
        pass(label)
      else
        fail(label, "expected #{expected.inspect}, got #{actual.inspect}")
      end
    end

    #: (untyped, String) -> void
    def assert_true(value, label)
      value ? pass(label) : fail(label, "expected true, got #{value.inspect}")
    end

    #: (Class, String) -> void
    def assert_raises(error_class, label)
      begin
        yield
      rescue StandardError => e
        if e.is_a?(error_class)
          pass(label)
        else
          fail(label, "expected #{error_class}, got #{e.class}: #{e.message}")
        end
        return
      end
      fail(label, "expected #{error_class}, nothing raised")
    end

    # Runs a table: each row is [label, input, expected]; the block maps an
    # input to an actual value. The rows are read through the typed element
    # reader cell, since a `[]` on an untyped receiver costs a rebuild of
    # Spinel's position map per call from 2440954d1 on
    # (docs/spinel-notes.md).
    #: (Array[Array[untyped]]) -> void
    def table(rows)
      rows.each do |row|
        actual = yield(cell(row, 1))
        assert_equal(cell(row, 2), actual, cell(row, 0))
      end
    end

    # Runs a table whose every input is an array literal: as table, the block
    # getting the input typed as an array, so the block's `input[i]` reads are
    # on a typed receiver. The signature is trusted, so a table with any other
    # input uses table.
    #: (Array[Array[untyped]]) -> void
    def cases(rows)
      rows.each do |row|
        actual = yield(list(row, 1))
        assert_equal(cell(row, 2), actual, cell(row, 0))
      end
    end

    #: () -> void
    def finish
      @out.puts "#{@name}: #{@passed} passed, #{@failed} failed"
      exit(@failed == 0 ? 0 : 1)
    end

    private

    #: (Array[untyped], Integer) -> Array[untyped]
    def list(row, index)
      row[index]
    end

    #: (Array[untyped], Integer) -> untyped
    def cell(row, index)
      row[index]
    end

    #: (String) -> void
    def pass(label)
      @passed += 1
      @out.puts "ok   #{label}"
    end

    #: (String, String) -> void
    def fail(label, reason)
      @failed += 1
      @out.puts "FAIL #{label}: #{reason}"
    end
  end
end
