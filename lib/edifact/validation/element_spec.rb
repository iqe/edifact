require_relative 'component_spec'

module Edifact::Validation
  class ElementSpec
    def initialize(specification)
      case specification
      when Hash
        @component_specs = specification[:components].map { |spec| ComponentSpec.new(spec) }
      when Array
        @component_specs = specification.map { |spec| ComponentSpec.new(spec) }
      else
        raise "Invalid element specification: #{specification.inspect}"
      end
    end

    def validate(element)
      element.components.each_with_index do |component, i|
        component_spec = @component_specs[i]
        if component_spec # only validate components that have a spec (ignore all other components)
          component_spec.validate(component)
        end
      end
    end
  end
end
