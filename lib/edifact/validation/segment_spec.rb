require_relative 'element_spec'

module Edifact::Validation
  class SegmentSpec
    def initialize(specification)
      case specification
        when Hash
          @name = specification[:name]
          if @name.nil?
            raise "Invalid segment specification, name is missing: #{specification.inspect}"
          end
          @element_specs = (specification[:elements] || []).map { |spec| ElementSpec.new(spec) }
        else
          raise "Invalid segment specification: #{specification.inspect}"
      end
    end

    def validate(segment)
      if @name != segment.name
        raise Edifact::ParseError.new(segment.pos, "Expected segment #{@name}, got #{segment.name}")
      end

      @element_specs.each_with_index do |element_spec, i|
        element = segment.elements[i]
        if element
          element_spec.validate(element)
        else
          unless element_spec.optional?
            raise Edifact::ParseError.new(segment.pos, "Missing element at index #{i}, expected #{element_spec.inspect}")
          end
        end
      end
    end
  end
end
