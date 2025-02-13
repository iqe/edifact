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
end
