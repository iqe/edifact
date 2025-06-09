require_relative 'element_spec'

module Edifact::Validation
  class SegmentSpec
    def initialize(specification)
      case specification
        when Hash
          @name = specification[:name]
          if @name.nil?
            raise Edifact::SegmentSpecError.new(specification, "Missing ':name' key")
          end
          @element_specs = (specification[:elements] || []).map { |spec| ElementSpec.new(spec) }
        else
          raise Edifact::SegmentSpecError.new(specification)
      end
    end

    def validate(segment)
      if @name != segment.name
        raise Edifact::ParseError.new(segment.pos, "Expected segment #{@name.inspect} at position #{segment.pos}, but got #{segment.name.inspect}")
      end

      pos = Edifact::Position.new(segment.pos.line, segment.pos.column + segment.name.length)
      @element_specs.each_with_index do |element_spec, i|
        element = segment.elements[i]
        if element
          element_spec.validate(element)
          pos = Edifact::Position.new(element.pos.line, element.pos.column + element.length)
        else
          unless element_spec.optional?
            raise Edifact::ParseError.new(segment.pos, "Missing element at position #{pos}, expected #{element_spec.to_s}")
          end
        end
      end
    end
  end
end
