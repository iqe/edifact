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

  def test_to_edifact_with_custom_control_characters
    config = Edifact::Nodes::ToEdifactConfig.new(
      segment_separator: "|",
      element_separator: "*",
      component_separator: "#",
      release_character: "/"
    )

    @b = Edifact::SegmentBuilder.new(config)

    @b.segment("ABC")
    @b.element("1", "2", "3")
    @b.element("H|e*l#l/o")

    @b.segment("DEF")
    @b.element("4", "5")

    assert_equal "UNA#*./ |ABC*1#2#3*H/|e/*l/#l//o|DEF*4#5|", @b.to_edifact
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

  def test_positions_with_newline_in_component_text
    @b.segment("ABC")
    @b.element("Hello\n\nWorld", "x")

    @b.segment("GHI")
    @b.element("4", "5")

    abc = @b.read
    assert_equal pos(1,10), abc.pos

    assert_equal pos(1,13), abc.elements[0].pos
    assert_equal pos(1,14), abc.elements[0].components[0].pos

    assert_equal pos(3,7), abc.elements[0].components[1].pos

    ghi = @b.read
    assert_equal pos(3,9), ghi.pos
  end

  def test_positions_with_newline_as_segment_separator
    config = Edifact::Nodes::ToEdifactConfig.new(
      segment_separator: "\n",
    )

    @b = Edifact::SegmentBuilder.new(config)

    @b.segment("ABC")
    @b.element("x")

    @b.segment("GHI")
    @b.element("\ny")

    @b.segment("KLM")
    @b.element("z")

    abc = @b.read
    assert_equal pos(2, 1), abc.pos
    assert_equal pos(2, 4), abc.elements[0].pos

    ghi = @b.read
    assert_equal pos(3, 1), ghi.pos
    assert_equal pos(3, 4), ghi.elements[0].pos

    klm = @b.read
    assert_equal pos(5, 1), klm.pos
    assert_equal pos(5, 4), klm.elements[0].pos
  end

  def test_newline_is_not_allowed_for_other_control_characters
    assert_raises(ArgumentError) { Edifact::Nodes::ToEdifactConfig.new(element_separator: "\n") }
    assert_raises(ArgumentError) { Edifact::Nodes::ToEdifactConfig.new(component_separator: "\n") }
    assert_raises(ArgumentError) { Edifact::Nodes::ToEdifactConfig.new(release_character: "\n") }
  end

  def test_method_missing_dsl_for_segments_and_elements
    @b.ABC("1", "2", "3")
    @b.ABC(["Hello", "World"])
    @b.GHI("4", ["5", "6"])
    @b.KLM

    assert_equal "UNA:+.? 'ABC+1+2+3'ABC+Hello:World'GHI+4+5:6'KLM'", @b.to_edifact

    assert_raises(ArgumentError) { @b.ABC(1) }

    assert_raises(NoMethodError) { @b.abc }
    assert_raises(NoMethodError) { @b.AB }
    assert_raises(NoMethodError) { @b.ABCD }
  end

  def test_segment_group_interface
    @b.ABC("1", "2", "3")
    @b.ABC(["Hello", "World"])
    @b.GHI("4", ["5", "6"])
    @b.KLM

    assert_equal "ABC+Hello:World'", @b["ABC+Hel"].to_edifact
    assert_equal 4, @b.segments.length
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

  def test_segment_stream_interface
    message_specification = {
      name: "MSG",
      segments: [
        { name: "ABC", elements: [["n1", "n1", "n1"]] },
        { name: "GHI", elements: [["an..10","n1"]] },
      ]
    }

    @b.segment("ABC")
    @b.element("1", "2", "3")

    @b.segment("GHI")
    @b.element("4", "5")

    tree = Edifact::SegmentTree.new(@b, message_specification)

    assert_equal "ABC+1:2:3'GHI+4:5'", tree.root.to_edifact
  end

  private

  def pos(line, column)
    Edifact::Position.new(line, column)
  end
end
