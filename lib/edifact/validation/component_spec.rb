require_relative '../errors'

module Edifact::Validation
  class ComponentSpec
    def initialize(specification)
      @specification = specification
      @validator = self.class.build_validator(specification)
    end

    def optional?
      @validator.respond_to?(:optional?) && @validator.optional?
    end

    def validate(component)
      unless @validator.valid?(component)
        raise Edifact::ParseError.new(component.pos, "Position #{component.pos}: Invalid value \"#{component.text}\". Expected \"#{@specification}\"")
      end
    end

    def to_s
      @specification.inspect
    end

    private

    def self.build_validator(specification)
      case specification
      when Hash
        HashValidator.new(specification)
      when Array
        ArrayValidator.new(specification)
      when /^a(\d+)$/
        length = $1.to_i
        FixedAlphaValidator.new(length)
      when /^an\.\.(\d+)$/
        length = $1.to_i
        VariableAlphanumericValidator.new(length)
      when /^n(\d+)$/
        length = $1.to_i
        FixedNumericValidator.new(length)
      when /^n\.\.(\d+)$/
        length = $1.to_i
        VariableNumericValidator.new(length)
      when String
        StringValidator.new(specification)
      when Regexp
        RegexValidator.new(specification)
      else
        raise "Invalid component specification: #{specification.inspect}"
      end
    end

    # {value: "n4", optional: true}
    class HashValidator
      def initialize(specification)
        @optional = specification[:optional]
        @spec = specification[:value]

        if @spec.nil?
          raise "Invalid component specification: #{specification.inspect}"
        else
          @spec = ComponentSpec.build_validator(@spec)
        end
      end

      def optional?
        @optional
      end

      def valid?(component)
        if @optional && component.text == ""
          return true
        else
          @spec.valid?(component)
        end
      end
    end

    # ["an..10", "n4"]
    class ArrayValidator
      def initialize(specification)
        @component_specs = specification.map { |spec| ComponentSpec.build_validator(spec) }
      end

      def valid?(component)
        @component_specs.any? {|sub_spec| sub_spec.valid?(component)}
      end
    end

    # "a5"
    class FixedAlphaValidator
      def initialize(length)
        @length = length
      end

      def valid?(component)
        component.text =~ /^[A-Za-z]{#{@length}}$/ # TODO support other characters?
      end
    end

    # "an..20"
    class VariableAlphanumericValidator
      def initialize(length)
        @length = length
      end

      def valid?(component)
        component.text.length <= @length
      end
    end

    # "n3"
    class FixedNumericValidator
      def initialize(length)
        @length = length
      end

      def valid?(component)
        component.text =~ /^\d{#{@length}}$/
      end
    end

    # "n..2"
    class VariableNumericValidator
      def initialize(length)
        @length = length
      end

      def valid?(component)
        component.text =~ /^\d{1,#{@length}}$/
      end
    end

    # "somevalue"
    class StringValidator
      def initialize(specification)
        @value = specification
      end

      def valid?(component)
        component.text == @value
      end
    end

    # /a+/
    class RegexValidator
      def initialize(specification)
        @regex = specification
      end

      def valid?(component)
        component.text =~ @regex
      end
    end
  end
end
