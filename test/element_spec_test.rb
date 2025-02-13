require 'test_helper'

class ElementSpecTest < Minitest::Test
  def test_mandatory_component
    spec = {
      name: "ABC",
      elements: [
        ["n1"]
      ]
    }

    assert_valid(spec, "ABC+1'")
    assert_invalid(spec, "ABC+::'")
  end

  def test_optional_components
    spec = {
      name: "ABC",
      elements: [
        ["n1", {value: "n1", optional: true}]
      ]
    }

    assert_valid(spec, "ABC+1'")
    assert_valid(spec, "ABC+1:'")
    assert_valid(spec, "ABC+1:1'")
    assert_invalid(spec, "ABC+'")
  end

  def test_all_specified_components_must_be_present
    spec = {
      name: "ABC",
      elements: [
        ["n1", "n1"]
      ]
    }

    assert_invalid(spec, "ABC+1'")
  end

  def test_only_components_with_specs_are_validated
    spec = {
      name: "ABC",
      elements: [
        ["n1"]
      ]
    }

    assert_valid(spec, "ABC+1:hello:world'") # second and third component have no specs, so they are ignored
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
