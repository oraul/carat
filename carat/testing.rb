module Carat
  # The test harness. Each test/*.rb program builds a Testing instance, runs
  # its checks, and calls finish, which prints a summary and exits non-zero on
  # failure. Output is deterministic so spin can diff it against the committed
  # .expected snapshot. No reflection, no autodiscovery.
  class Testing
    def initialize(name)
      @name = name
      @passed = 0
      @failed = 0
      @out = STDOUT
    end

    def assert_equal(expected, actual, label)
      if expected == actual
        pass(label)
      else
        fail(label, "expected #{expected.inspect}, got #{actual.inspect}")
      end
    end

    def assert_true(value, label)
      value ? pass(label) : fail(label, "expected true, got #{value.inspect}")
    end

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
    # input to an actual value.
    def table(rows)
      rows.each do |row|
        actual = yield(row[1])
        assert_equal(row[2], actual, row[0])
      end
    end

    def finish
      @out.puts "#{@name}: #{@passed} passed, #{@failed} failed"
      exit(@failed == 0 ? 0 : 1)
    end

    private

    def pass(label)
      @passed += 1
      @out.puts "ok   #{label}"
    end

    def fail(label, reason)
      @failed += 1
      @out.puts "FAIL #{label}: #{reason}"
    end
  end
end
