require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

require 'minitest/autorun'
require 'edifact'

module TestHelper
  def assert_raises_msg(message)
    error = assert_raises(Edifact::ParseError) do
      yield
    end

    if message.is_a?(Regexp)
      assert_match message, error.message
    else
      assert_equal message, error.message
    end
  end

  def pos(line, column)
    Edifact::Position.new(line, column)
  end
end

# Overwrite equality to allow comparing a Position with an Integer
# for the default case "line 1, column X". We use "'" as the segment
# separator in almost all tests. So there is only one line.
#
# This increases the reabability of tests.
module Edifact
  class Position
    alias_method :__original_equality, :==
    def ==(other)
      case other
      when Integer
        @line == 1 && @column == other
      else
        __original_equality(other)
      end
    end
  end
end

class Integer
  # Allow comparing an Integer with a Position
  alias_method :__original_equality, :==
  def ==(other)
    case other
    when Edifact::Position
      other.line == 1 && other.column == self
    else
      __original_equality(other)
    end
  end
end

raise unless 1 == Edifact::Position.new(1, 1)
raise unless Edifact::Position.new(1, 1) == 1
raise unless 1 != Edifact::Position.new(2, 1)
raise unless Edifact::Position.new(2, 1) != 1
