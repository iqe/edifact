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
        raise Edifact::ParseError.new(segment.pos, "Expected segment #{@name.inspect} at position #{segment.pos}, but got #{segment.name.inspect}")
      end

      pos = segment.pos + segment.name.length
      @element_specs.each_with_index do |element_spec, i|
        element = segment.elements[i]
        if element
          element_spec.validate(element)
          pos = element.pos + element.to_edifact.length - 1 # to_edifact to correctly count escape characters, -1 to exclude element separator
        else
          unless element_spec.optional?
            raise Edifact::ParseError.new(segment.pos, "Missing element at position #{pos}, expected #{element_spec.to_s}")
          end
        end
      end
    end
  end
end
