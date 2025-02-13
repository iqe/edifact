module Edifact
  class ParseError < StandardError
    attr_reader :pos

    def initialize(pos, message)
      @pos = pos
      super(message)
    end
  end

  class InvalidUnaHeaderError < ParseError
    def initialize(una_header)
      super(0, "Invalid UNA header at position #{pos}. Got #{una_header.inspect}.")
    end
  end

  class UnexpectedEndOfInputError < ParseError
    def initialize(pos)
      super(pos, "Unexpected end of input at position #{pos}.")
    end
  end

  class UnexpectedTokenError < ParseError
    attr_reader :actual, :expected

    def initialize(token, expected_values=[])
      @actual = token.value
      @expected = expected_values

      message = "Unexpected #{@actual.inspect} at position #{token.pos}."
      if !expected_values.empty?
        message += " Expected one of #{@expected_values.inspect}."
      end

      super(token.pos, message)
    end
  end

  class ValidationError < ParseError
    def initialize(component_spec, component)
      super(component.pos, "Position #{component.pos}: Invalid value \"#{component.text}\". Expected \"#{component_spec}\"")
    end
  end
end
