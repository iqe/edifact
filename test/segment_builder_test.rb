require 'test_helper'

class SegmentBuilderTest < Minitest::Test
  def setup
    @b = Edifact::SegmentBuilder.new
  end

  def test_to_edifact
    @b.segment("ABC")
    @b.element("1", "2", "3")
    @b.element("Hello")

    @b.segment("DEF")
    @b.element("4", "5")

    assert_equal "UNA:+.? 'ABC+1:2:3+Hello'DEF+4:5'", @b.to_edifact
  end

  def test_positions
    @b.segment("ABC")
    @b.element("1", "2", "3")
    @b.element("Hello")

    @b.segment("GHI")
    @b.element("4", "5")

    abc = @b.read
    assert_equal 10, abc.pos
    assert_equal "ABC", abc.name

    assert_equal 2, abc.elements.size
    assert_equal 13, abc.elements[0].pos
    assert_equal 14, abc.elements[0].components[0].pos
    assert_equal 16, abc.elements[0].components[1].pos
    assert_equal 18, abc.elements[0].components[2].pos

    assert_equal 19, abc.elements[1].pos
    assert_equal 20, abc.elements[1].components[0].pos

    ghi = @b.read
    assert_equal 26, ghi.pos
  end

  def test_roundtrip_with_segment_stream
    @b.segment("ABC")
    @b.element("1", "2", "3")
    @b.element("Hello")

    @b.segment("GHI")
    @b.element("4", "5")

    stream = Edifact::SegmentStream.new(Edifact::TokenStream.new(StringIO.new(@b.to_edifact)))

    assert_equal stream.read_remaining, @b.read_remaining
  end
end
