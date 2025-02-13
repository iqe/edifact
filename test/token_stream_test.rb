require 'test_helper'

class TokenStreamTest < Minitest::Test
  include TestHelper

  def test_nil_input
    error = assert_raises do
      Edifact::TokenStream.new(nil)
    end
    assert_match(/nil/, error.message)
  end

  def test_empty_input
    assert_raises_msg(/UNA/) { raw_input("") }
  end

  def test_una_header_parsing
    raw_input("UNA1234 6")

    assert_equal "1", @token_stream.component_separator
    assert_equal "2", @token_stream.element_separator
    assert_equal "4", @token_stream.escape_character
    assert_equal "6", @token_stream.segment_separator
  end

  def test_empty_element
    input("ABC++'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :element_separator], [15, :segment_separator], [16, :eof]], tokens
  end

  def test_empty_component
    input("ABC+:+'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :component_separator], [15, :element_separator], [16, :segment_separator], [17, :eof]], tokens
  end

  def test_escape_character
    input("ABC+?+'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "+"], [16, :segment_separator], [17, :eof]], tokens

    input("ABC+????'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "??"], [18, :segment_separator], [19, :eof]], tokens

    input("ABC+Hello?+'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "Hello+"], [21, :segment_separator], [22, :eof]], tokens

    input("ABC+Hello?+World'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "Hello+World"], [26, :segment_separator], [27, :eof]], tokens
  end

  def test_escape_character_at_eof
    assert_raises_msg(/Unexpected end of input .* 15/) { input("ABC+?") }
  end

  def test_binary_text_gets_passed_through
    input("ABC+\x01\x02\x03'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "\x01\x02\x03"], [17, :segment_separator], [18, :eof]], tokens
  end

  def test_partial_segment
    input("AB")
    assert_equal [[10, :text, "AB"], [12, :eof]], tokens

    input("+")
    assert_equal [[10, :element_separator], [11, :eof]], tokens

    input("ABC+'+")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :segment_separator], [15, :element_separator], [16, :eof]], tokens
  end

  private

  def input(edifact_msg)
    raw_input("UNA:+.? '#{edifact_msg}")
  end

  def raw_input(input)
    @token_stream = Edifact::TokenStream.new(StringIO.new(input))
    @tokens = @token_stream.read_remaining
  end

  def tokens
    @tokens.map {|t| t.type == :text ? [t.pos, t.type, t.value] : [t.pos, t.type]}
  end
end
