module Edifact
  class ValidationError < StandardError
    def initialize(component_spec, component)
      super("Position #{component.pos}: Invalid value \"#{component.text}\". Expected \"#{component_spec}\"")
    end
  end

  class ElementValidator
    def validate_elements(spec_node, segment)
      spec_node.elements.each_with_index do |element_spec, i|
        case element_spec
        when Array # array of component specs
          validate_components(element_spec, segment.elements[i])
        # when String # TODO validate against global list of elements

        else
          raise "Unknown element spec: #{element_spec.inspect}"
        end
      end
    end

    def validate_components(element_spec, element)
      element_spec.each_with_index do |component_spec, i|
        component = element.components[i]
        validate_component(component_spec, component)
      end
    end

    def validate_component(component_spec, component)
      case component_spec
      when Hash
        if component_spec[:optional].nil?
          raise "Unknown component spec: #{component_spec.inspect}"
        end
        if component.text != ""
          validate_component(component_spec[:optional], component)
        end

      when Array # array of component specs (strings, regexps)
        component_spec.each do |sub_component_spec|
          begin
            validate_component(sub_component_spec, component)
            return # success - we only need one of the specs to match
          rescue ValidationError
            next
          end
        end
        raise ValidationError.new(component_spec, component)

      when /^a(\d+)$/ # fixed alpha-only datatype
        length = $1.to_i
        unless component.text =~ /^[A-Za-z]{#{length}}$/ # TODO support other characters?
          raise ValidationError.new(component_spec, component)
        end

      when /^an\.\.(\d+)$/ # variable alphanumeric datatype
        length = $1.to_i
        unless component.text.length <= length
          raise ValidationError.new(component_spec, component)
        end

      when /^n(\d+)$/ # fixed numeric datatype
        length = $1.to_i
        unless component.text =~ /^\d{#{length}}$/
          raise ValidationError.new(component_spec, component)
        end

      when /^n\.\.(\d+)$/ # variable numeric datatype
        length = $1.to_i
        unless component.text =~ /^\d{1,#{length}}$/
          raise ValidationError.new(component_spec, component)
        end

      when String # exact string match
        unless component.text == component_spec
          raise ValidationError.new(component_spec, component)
        end

      when Regexp # regex match
        unless component.text =~ component_spec
          raise ValidationError.new(component_spec, component)
        end

      else
        raise "Unknown component spec: #{component_spec.inspect}"
      end
    end
  end
end
