require 'test_helper'

class SegmentGroupTest < Minitest::Test
  include TestHelper

  def test_index_by_segment_name
    g = input("ABC+1:2:3+Hello'DEF+4:5'")
    assert_equal "DEF", g["DEF"].name

    g = input("ABC+1:2:3+Hello'DEF+4:5'ABC+6:7'")
    assert_equal Array, g["ABC"].class
    assert_equal 2, g["ABC"].size

    assert_nil g["GHI"]
  end

  def test_index_by_segment_name_and_content
    g = input("ABC+1:2:3+Hello'DEF+4:5'")
    assert_equal "DEF", g["DEF+4"].name

    g = input("ABC+61:2:3+Hello'DEF+4:5'ABC+62:7'")
    assert_equal Array, g["ABC+6"].class
    assert_equal 2, g["ABC+6"].size

    assert_equal "ABC+61:2:3+Hello'", g["ABC+61:2"].to_edifact
  end

  def test_index_by_regex
    g = input("ABC+1:2:3+Hello'DEF+4:5'ABC+6:7'")
    assert_equal "DEF", g[/^DEF/].name

    assert_equal Array, g[/^ABC/].class
    assert_equal 2, g[/^ABC/].size
  end

  def test_index_by_integer
    g = input("ABC+1:2:3+Hello'DEF+4:5'")

    assert_equal "ABC", g[0].name
    assert_equal "DEF", g[1].name
    assert_nil g[2]
  end

  def test_index_by_anything_else
    g = input("ABC+1:2:3+Hello'DEF+4:5'")
    assert_raises ArgumentError do
      g[:foo]
    end
  end

  private

  def input(s)
    stream = Edifact::SegmentStream.new(Edifact::TokenStream.new(StringIO.new("UNA:+.? '#{s}")))
    Edifact::Nodes::SegmentGroup.new("SG0", stream.read_remaining)
  end
end
