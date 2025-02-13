require_relative 'element_spec'

module Edifact::Validation
  class SegmentSpec
    def initialize(specification)
      case specification
        when Hash
          @element_specs = (specification[:elements] || []).map { |spec| ElementSpec.new(spec) }
        else
          raise "Invalid segment specification: #{specification.inspect}"
      end
    end

    def validate(segment)
      segment.elements.each_with_index do |element, i|
        element_spec = @element_specs[i]
        if element_spec # only validate elements that have a spec (ignore all other elements)
          element_spec.validate(element)
        end
      end
    end
  end
end
