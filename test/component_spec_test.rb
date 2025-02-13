require 'test_helper'
require 'edifact/validation/component_spec'

class ComponentSpecTest < Minitest::Test
  def test_literal_string
    assert_valid("a", "a")
    assert_invalid("a", "b")
    assert_invalid("a", "")
  end

  def test_regex
    assert_valid(/a/, "a")
    assert_invalid(/a/, "b")
    assert_invalid(/a/, "")
  end

  def test_fixed_number_datatype
    assert_valid("n1", "1")
    assert_valid("n2", "11")

    assert_invalid("n1", "a")
    assert_invalid("n1", "11") # too long
    assert_invalid("n2", "1") # too short
    assert_invalid("n1", "")
  end

  def test_variable_number_datatype
    assert_valid("n..1", "1")
    assert_valid("n..2", "11")
    assert_valid("n..2", "1")

    assert_invalid("n..1", "a")
    assert_invalid("n..1", "11") # too long
    assert_invalid("n..2", "") # not a number
  end

  def test_variable_alphanumeric_datatype
    assert_valid("an..3", "abc")
    assert_valid("an..3", "a1c")
    assert_valid("an..3", "a")
    assert_valid("an..3", "")

    assert_invalid("an..3", "abcd")
  end

  def test_fixed_alpha_datatype
    assert_valid("a1", "a")
    assert_valid("a2", "ab")

    assert_invalid("a1", "1")
    assert_invalid("a1", "ab")
    assert_invalid("a2", "a")
    assert_invalid("a1", "")
  end

  def test_hash_for_optional_value
    assert_valid({optional: "a"}, "")
    assert_valid({optional: "a"}, "a")
    assert_invalid({optional: "a"}, "b")
  end

  def test_array_of_component_specs
    assert_valid(["hello", "world"], "hello")
    assert_valid(["hello", "world"], "world")
    assert_invalid(["hello", "world"], "x")

    assert_valid([/^a/, "world"], "abc")
    assert_invalid([/^a/, "world"], "hello")
  end

  private

  def assert_valid(component_spec, component_value)
    element = Edifact::Element.new(0)
    element << Edifact::Component.new(0, component_value)

    Edifact::Validation::ComponentSpec.new(component_spec).validate(Edifact::Component.new(0, component_value))
  end

  def assert_invalid(component_spec, component_value)

    element = Edifact::Element.new(0)
    element << Edifact::Component.new(0, component_value)

    begin
      Edifact::Validation::ComponentSpec.new(component_spec).validate(Edifact::Component.new(0, component_value))
      fail "Expected Edifact::ValidationError for spec #{component_spec.inspect} and value #{component_value.inspect}"
    rescue Edifact::ValidationError
      # ok
    end
  end
end
