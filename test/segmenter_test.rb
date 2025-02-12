require 'test_helper'

class SegmenterTest < Minitest::Test
  def test_basic_segment
    input("ABC+Hel:lo+World++'")
    assert_equal [[10, "ABC", [14, [14, "Hel"], [18, "lo"]], [21, [21, "World"]], [27, [27, ""]], [28, [28, ""]]]], segments
  end

  def test_multiple_segments
    input("ABC+Hel:lo'DEF+World'")
    assert_equal [[10, "ABC", [14, [14, "Hel"], [18, "lo"]]], [21, "DEF", [25, [25, "World"]]]], segments
  end

  def test_minimal_segment
    input("ABC'")
    assert_equal [[10, "ABC"]], segments

    input("ABC+'")
    assert_equal [[10, "ABC", [14, [14, ""]]]], segments

    input("AAA+:'")
    assert_equal [[10, "AAA", [14, [14, ""], [15, ""]]]], segments

    input("AAA+::'")
    assert_equal [[10, "AAA", [14, [14, ""], [15, ""], [16, ""]]]], segments

    input("ABC++'")
    assert_equal [[10, "ABC", [14, [14, ""]], [15, [15, ""]]]], segments

    input("ABC+x'")
    assert_equal [[10, "ABC", [14, [14, "x"]]]], segments

    input("ABC+x:y'")
    assert_equal [[10, "ABC", [14, [14, "x"], [16, "y"]]]], segments

    input("ABC+x::y'")
    assert_equal [[10, "ABC", [14, [14, "x"], [16, ""], [17, "y"]]]], segments

    input("ABC++y'")
    assert_equal [[10, "ABC", [14, [14, ""]], [15, [15, "y"]]]], segments
  end

  def test_unexpected_eof
    assert_raises_msg(/Unexpected end of file/) { input("AAA+") }
    assert_raises_msg(/Unexpected end of file/) { input("AAA+x") }
    assert_raises_msg(/Unexpected end of file/) { input("AAA+x:") }
    assert_raises_msg(/Unexpected end of file/) { input("AAA+x:y") }
  end

  def test_unexpected_component_separator
    assert_raises_msg(/Unexpected ":" .* 10/) { input(":AAA+x'") }
    assert_raises_msg(/Unexpected ":" .* 13/) { input("AAA:'") }
    assert_raises_msg(/Unexpected ":" .* 16/) { input("AAA+x':") }
  end

  def test_unexpected_element_separator
    assert_raises_msg(/Unexpected "\+" .* 10/) { input("+AAA+x'") }
    assert_raises_msg(/Unexpected "\+" .* 16/) { input("AAA+x'+") }
  end

  def test_unexpected_segment_separator
    assert_raises_msg(/Unexpected "'" .* 10/) { input("'AAA+x'") }
    assert_raises_msg(/Unexpected "'" .* 16/) { input("AAA+x''") }
  end

  private

  def assert_raises_msg(message)
    error = assert_raises do
      yield
    end
    assert_match message, error.message
  end

  def input(s)
    input = "UNA:+.? '" + s
    @parser = Edifact::Segmenter.new
    @segments = @parser.parse(StringIO.new(input))
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
