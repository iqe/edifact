module Edifact
  class ParseError < StandardError
    attr_reader :pos

    def initialize(pos, message)
      @pos = pos
      super(message)
    end
  end

  class InvalidUnaHeaderError < ParseError
    def initialize(pos, una_header)
      super(pos, "Invalid UNA header at position #{pos}. Got #{una_header.inspect}.")
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

  class SpecificationError < StandardError
    def initialize(spec_type, specification, message=nil)
      msg = "Invalid #{spec_type} specification"
      msg += ": #{message}" if message
      msg += ": #{specification.inspect}"
      super(msg)
    end
  end

  class ComponentSpecError < SpecificationError
    def initialize(specification, message=nil)
      super("component", specification, message)
    end
  end

  class ElementSpecError < SpecificationError
    def initialize(specification, message=nil)
      super("element", specification, message)
    end
  end

  class SegmentSpecError < SpecificationError
    def initialize(specification, message=nil)
      super("segment", specification, message)
    end
  end
end
