require 'test_helper'

class SegmentStreamTest < Minitest::Test
  include TestHelper

  def test_basic_segment
    input("ABC+Hel:lo+World++'")
    assert_equal [[10, "ABC", [13, [14, "Hel"], [18, "lo"]], [20, [21, "World"]], [26, [27, ""]], [27, [28, ""]]]], segments
  end

  def test_multiple_segments
    input("ABC+Hel:lo'DEF+World'")
    assert_equal [[10, "ABC", [13, [14, "Hel"], [18, "lo"]]], [21, "DEF", [24, [25, "World"]]]], segments
  end

  def test_minimal_segment
    input("ABC'")
    assert_equal [[10, "ABC"]], segments

    input("ABC+'")
    assert_equal [[10, "ABC", [13, [14, ""]]]], segments

    input("AAA+:'")
    assert_equal [[10, "AAA", [13, [14, ""], [15, ""]]]], segments

    input("AAA+::'")
    assert_equal [[10, "AAA", [13, [14, ""], [15, ""], [16, ""]]]], segments

    input("ABC++'")
    assert_equal [[10, "ABC", [13, [14, ""]], [14, [15, ""]]]], segments

    input("ABC+x'")
    assert_equal [[10, "ABC", [13, [14, "x"]]]], segments

    input("ABC+x:y'")
    assert_equal [[10, "ABC", [13, [14, "x"], [16, "y"]]]], segments

    input("ABC+x::y'")
    assert_equal [[10, "ABC", [13, [14, "x"], [16, ""], [17, "y"]]]], segments

    input("ABC++y'")
    assert_equal [[10, "ABC", [13, [14, ""]], [14, [15, "y"]]]], segments
  end

  def test_unexpected_eof
    assert_raises_msg(/Unexpected end of input .* 1:13/) { input("AAA") }
    assert_raises_msg(/Unexpected end of input .* 1:14/) { input("AAA+") }
    assert_raises_msg(/Unexpected end of input .* 1:15/) { input("AAA+x") }
    assert_raises_msg(/Unexpected end of input .* 1:16/) { input("AAA+x:") }
    assert_raises_msg(/Unexpected end of input .* 1:17/) { input("AAA+x:y") }
  end

  def test_unexpected_component_separator
    assert_raises_msg(/Unexpected ":" .* 1:10/) { input(":AAA+x'") }
    assert_raises_msg(/Unexpected ":" .* 1:13/) { input("AAA:'") }
    assert_raises_msg(/Unexpected ":" .* 1:16/) { input("AAA+x':") }
  end

  def test_unexpected_element_separator
    assert_raises_msg(/Unexpected "\+" .* 1:10/) { input("+AAA+x'") }
    assert_raises_msg(/Unexpected "\+" .* 1:16/) { input("AAA+x'+") }
  end

  def test_unexpected_segment_separator
    assert_raises_msg(/Unexpected "'" .* 1:10/) { input("'AAA+x'") }
    assert_raises_msg(/Unexpected "'" .* 1:16/) { input("AAA+x''") }
  end

  private

  def input(s)
    stream = Edifact::SegmentStream.new(Edifact::TokenStream.new(StringIO.new("UNA:+.? '#{s}")))
    @segments = stream.read_remaining
  end

  def segments
    @segments.map do |segment|
      [segment.pos, segment.name, *segment.elements.map do |element|
        [element.pos, *element.components.map do |component|
          [component.pos, component.text]
        end]
      end]
    end
  end
end
