require_relative 'element_spec'

module Edifact::Validation
  class SegmentSpec
    def initialize(specification)
      @specification = specification
    end

    def validate(segment)
      element_specs = @specification.elements
      segment.elements.each_with_index do |element, i|
        element_specification = element_specs[i]
        if element_specification # only validate elements that have a spec (ignore all other elements)
          ElementSpec.new(element_specification).validate(element)
        end
      end
    end
  end
end
