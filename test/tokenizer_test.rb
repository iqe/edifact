require 'test_helper'

class TokenizerTest < Minitest::Test
  def test_nil_input
    error = assert_raises do
      Edifact::Tokenizer.new(nil)
    end
    assert_match(/nil/, error.message)
  end

  def test_empty_input
    error = assert_raises do
      raw_msg("")
    end
    assert_match(/UNA/, error.message)
  end

  def test_una_header_parsing
    raw_msg("UNA1234 6")

    assert_equal "1", @tokenizer.component_separator
    assert_equal "2", @tokenizer.element_separator
    assert_equal "4", @tokenizer.escape_character
    assert_equal "6", @tokenizer.segment_separator
  end

  def test_empty_element
    msg("ABC++'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :element_separator], [15, :segment_separator], [16, :eof]], tokens
  end

  def test_empty_component
    msg("ABC+:+'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :component_separator], [15, :element_separator], [16, :segment_separator], [17, :eof]], tokens
  end

  def test_escape_character
    msg("ABC+?+'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "+"], [16, :segment_separator], [17, :eof]], tokens

    msg("ABC+????'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "??"], [18, :segment_separator], [19, :eof]], tokens

    msg("ABC+Hello?+'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "Hello+"], [21, :segment_separator], [22, :eof]], tokens

    msg("ABC+Hello?+World'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "Hello+World"], [26, :segment_separator], [27, :eof]], tokens
  end

  def test_escape_character_at_eof
    error = assert_raises do
      msg("ABC+?")
      tokens # trigger tokenization
    end
    assert_match(/end of input.*escape character/, error.message)
  end

  def test_binary_text_gets_passed_through
    msg("ABC+\x01\x02\x03'")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :text, "\x01\x02\x03"], [17, :segment_separator], [18, :eof]], tokens
  end

  def test_partial_segment
    msg("AB")
    assert_equal [[10, :text, "AB"], [12, :eof]], tokens

    msg("+")
    assert_equal [[10, :element_separator], [11, :eof]], tokens

    msg("ABC+'+")
    assert_equal [[10, :text, "ABC"], [13, :element_separator], [14, :segment_separator], [15, :element_separator], [16, :eof]], tokens
  end

  private

  def raw_msg(input)
    @tokenizer = Edifact::Tokenizer.new(StringIO.new(input))
  end

  def msg(edifact_msg)
    raw_msg("UNA:+.? '#{edifact_msg}")
  end

  def tokens
    @tokenizer.to_a.map {|t| t.type == :text ? [t.pos, t.type, t.value] : [t.pos, t.type]}
  end
end
