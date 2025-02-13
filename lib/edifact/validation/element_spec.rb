require_relative 'component_spec'

module Edifact::Validation
  class ElementSpec
    def initialize(specification)
      @specification = specification
    end

    def validate(element)
      element.components.each_with_index do |component, i|
        component_specification = @specification[i]
        if component_specification # only validate components that have a spec (ignore all other components)
          ComponentSpec.new(component_specification).validate(component)
        end
      end
    end
  end
end
