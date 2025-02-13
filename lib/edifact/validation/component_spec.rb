require_relative '../errors'

module Edifact::Validation
  class ComponentSpec
    def initialize(specification)
      @specification = specification
    end

    def validate(component)
      case @specification
      when Hash
        if @specification[:optional].nil?
          raise "Unknown component spec: #{@specification.inspect}"
        end
        if component.text != ""
          ComponentSpec.new(@specification[:optional]).validate(component)
        end

      when Array # array of component specs (strings, regexps)
        @specification.each do |sub_specification|
          begin
            ComponentSpec.new(sub_specification).validate(component)
            return # success - we only need one of the specs to match
          rescue Edifact::ValidationError
            next
          end
        end
        raise Edifact::ValidationError.new(@specification, component)

      when /^a(\d+)$/ # fixed alpha-only datatype
        length = $1.to_i
        unless component.text =~ /^[A-Za-z]{#{length}}$/ # TODO support other characters?
          raise Edifact::ValidationError.new(@specification, component)
        end

      when /^an\.\.(\d+)$/ # variable alphanumeric datatype
        length = $1.to_i
        unless component.text.length <= length
          raise Edifact::ValidationError.new(@specification, component)
        end

      when /^n(\d+)$/ # fixed numeric datatype
        length = $1.to_i
        unless component.text =~ /^\d{#{length}}$/
          raise Edifact::ValidationError.new(@specification, component)
        end

      when /^n\.\.(\d+)$/ # variable numeric datatype
        length = $1.to_i
        unless component.text =~ /^\d{1,#{length}}$/
          raise Edifact::ValidationError.new(@specification, component)
        end

      when String # exact string match
        unless component.text == @specification
          raise Edifact::ValidationError.new(@specification, component)
        end

      when Regexp # regex match
        unless component.text =~ @specification
          raise Edifact::ValidationError.new(@specification, component)
        end

      else
        raise "Unknown component spec: #{@specification.inspect}"
      end
    end
  end
end
