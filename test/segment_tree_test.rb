require 'test_helper'

class SegmentTreeTest < Minitest::Test
  include TestHelper

  def test_single_element_tree
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" }
      ]
    })

    input("ABC'")

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
      ]
    })
  end

  def test_wrong_segment
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
      ]
    })

    assert_raises_msg('Invalid segment "DEF" at position 10. Expected one of ["ABC"]') { input("DEF'") }
  end

  def test_multiple_possible_segments
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "DEF", min: 0 },
        { name: "GHI" },
      ]
    })

    input("ABC'GHI'")
    input("ABC'DEF'GHI'")
  end

  def test_same_possible_segments_with_different_elements
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "DEF", min: 0, elements: [["A"]] },
        { name: "DEF", min: 0, elements: [["B"]] },
      ]
    })

    input("ABC'DEF+A'")
    input("ABC'DEF+B'")
  end

  def test_missing_segment
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "DEF" },
      ]
    })

    assert_raises_msg('Unexpected end of input. Expected one of ["DEF"]') { input("ABC'") }
  end

  def test_optional_trailing_segment
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "DEF", min: 0 },
        { name: "GHI", min: 0 },
      ]
    })

    input("ABC'")

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
      ]
    })
  end

  def test_nested_tree
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" },
          ]
        }
      ]
    })

    input("ABC'DEF'")

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" }
          ]
        }
      ]
    })
  end

  def test_nested_groups
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "SG1", segments: [
                { name: "GHI" }
              ]
            }
          ]
        }
      ]
    })

    input("ABC'DEF'GHI'")

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "SG1", segments: [
                { name: "GHI" }
              ]
            }
          ]
        }
      ]
    })
  end

  def test_repeating_groups
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", max: 99, segments: [
            { name: "DEF" },
            { name: "GHI" }
          ]
        }
      ]
    })

    input("ABC'DEF'GHI'DEF'GHI'")

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "GHI" }
          ]
        },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "GHI" },
          ]
        }
      ]
    })
  end

  def test_segment_after_repeating_group
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", max: 99, segments: [
            { name: "DEF" },
            { name: "GHI" }
          ]
        },
        { name: "JKL" },
      ]
    })

    input("ABC'DEF'GHI'DEF'GHI'JKL'")

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "GHI" }
          ]
        },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "GHI" },
          ]
        },
        { name: "JKL" },
      ]
    })
  end

  def test_double_nested_tree_at_end_of_group
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "SG1", segments: [
                { name: "GHI" }
              ]
            },
          ]
        },
        { name: "JKL" },
      ]
    })

    input("ABC'DEF'GHI'JKL'")

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "SG0", segments: [
            { name: "DEF" },
            { name: "SG1", segments: [
                { name: "GHI" }
              ]
            },
          ]
        },
        { name: "JKL" },
      ]
    })
  end

  def test_element_validation_is_triggered
    definition({
      name: "MSG",
      segments: [
        { name: "ABC", elements: [["1234"]] }
      ]
    })

    assert_raises_msg('Position 14: Invalid value "hello". Expected "1234"') { input("ABC+hello'") }
  end

  def test_reading_from_array_of_segments
    definition({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "DEF" },
      ]
    })

    segments = [
      Edifact::Nodes::Segment.new(0, "ABC", elements: [Edifact::Nodes::Element.new(0, "1234")]),
      Edifact::Nodes::Segment.new(0, "DEF"),
    ]

    segment_tree = Edifact::SegmentTree.new(segments, @tree_spec)
    @tree = to_test_hash(segment_tree.root)

    assert_tree({
      name: "MSG",
      segments: [
        { name: "ABC" },
        { name: "DEF" },
      ]
    })
  end

  private

  def definition(tree_spec)
    @tree_spec = tree_spec
  end

  def input(input)
    @input = StringIO.new("UNA:+.? '#{input}")

    segments = Edifact::SegmentStream.new(Edifact::TokenStream.new(@input))
    segment_tree = Edifact::SegmentTree.new(segments, @tree_spec)

    @tree = to_test_hash(segment_tree.root)
  end

  def assert_tree(expected)
    assert_equal expected, @tree
  end

  def to_test_hash(node)
    case node
    when Edifact::Nodes::SegmentGroup
      {
        name: node.name,
        segments: node.segments.map {|s| to_test_hash(s)}
      }
    when Edifact::Nodes::Segment
      {
        name: node.name
      }
    else
      nil
    end
  end
end
