require_relative 'component_spec'

module Edifact::Validation
  class ElementSpec
    def initialize(specification)
      case specification
        when Hash
          @optional = specification[:optional]
          if specification[:components].respond_to?(:map)
            @component_specs = specification[:components].map { |spec| ComponentSpec.new(spec) }
          else
            raise "Invalid element specification: #{specification.inspect}"
          end
        when Array
          @optional = false
          @component_specs = specification.map { |spec| ComponentSpec.new(spec) }
        else
          raise "Invalid element specification: #{specification.inspect}"
      end
    end

    def optional?
      @optional
    end

    def validate(element)
      pos = element.pos
      @component_specs.each_with_index do |component_spec, i|
        component = element.components[i]
        if component
          component_spec.validate(component)
          pos = Edifact::Position.new(component.pos.line, component.pos.column + component.length)
        else
          unless component_spec.optional?
            raise Edifact::ParseError.new(pos, "Missing component at position #{pos}, expected #{component_spec.to_s.inspect}")
          end
        end
      end
    end

    def to_s
      "[" + @component_specs.map(&:to_s).join(", ") + "]"
    end
  end
end
