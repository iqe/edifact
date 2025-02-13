require 'test_helper'
require 'edifact/validation/segment_spec'

class SegmentSpecTest < Minitest::Test
  def test_segment_name
    spec = {
      name: "ABC",
      elements: [
        ["n1"]
      ]
    }

    assert_valid(spec, "ABC+1'")
    assert_invalid(spec, "DEF+1'")
  end


  def test_mandatory_element
    spec = {
      name: "ABC",
      elements: [
        ["n1"]
      ]
    }

    assert_valid(spec, "ABC+1'")
    assert_invalid(spec, "ABC+'") # n1 is mandatory
    assert_invalid(spec, "ABC'") # element is mandatory
  end

  def test_optional_element
    spec = {
      name: "ABC",
      elements: [
        {optional: true, components: ["n1"]}
      ]
    }

    assert_valid(spec, "ABC+1'")
    assert_valid(spec, "ABC'")
    assert_invalid(spec, "ABC+'") # n1 is not optional, only the element itself
  end

  def test_multiple_trailing_optional_elements
    spec = {
      name: "ABC",
      elements: [
        {optional: true, components: ["n1"]},
        {optional: true, components: ["n1"]}
      ]
    }

    assert_valid(spec, "ABC'")
    assert_valid(spec, "ABC+1'")
    assert_valid(spec, "ABC+1+1'")
  end

  def test_only_elements_with_specs_are_validated
    spec = {
      name: "ABC",
      elements: [
        ["n1"]
      ]
    }

    assert_valid(spec, "ABC+1'")
    assert_valid(spec, "ABC+1+hello+world'") # second and third element have no specs, so they are ignored
  end

  private

  def assert_valid(segment_spec, s)
    segment = create_segment(s)

    Edifact::Validation::SegmentSpec.new(segment_spec).validate(segment)
  end

  def assert_invalid(segment_spec, s)
    segment = create_segment(s)

    begin
      Edifact::Validation::SegmentSpec.new(segment_spec).validate(segment)
      fail "Expected ParseError for spec #{segment_spec.inspect} and value #{segment.inspect}"
    rescue Edifact::ParseError
      # ok
    end
  end

  def create_segment(s)
    segment_stream = Edifact::SegmentStream.new(Edifact::TokenStream.new(StringIO.new("UNA:+.? '#{s}")))
    segment_stream.read
  end
end
