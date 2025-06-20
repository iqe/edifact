require_relative 'errors'
require_relative 'validation/segment_spec'

module Edifact
  # Interchange represents an EDIFACT interchange.
  #
  # It validates the basic structure of the interchange and its messages.
  class Interchange
    class Message
      attr_reader :unh, :segments, :unt

      def initialize(unh:, segments:, unt:)
        @unh, @segments, @unt = unh, segments, unt
      end

      def to_edifact(config = Edifact::Nodes::ToEdifactConfig::DEFAULT)
        [@unh, *@segments, @unt].map {|s| s.to_edifact(config)}.join
      end
    end

    UNB_SPEC = Validation::SegmentSpec.new({
      name: "UNB",
      elements: [
        ["a4", "n1"],
        ["an..35", { value: "an..4", optional: true }, { value: "an..14", optional: true }],
        ["an..35", { value: "an..4", optional: true }, { value: "an..14", optional: true }],
        ["n6", "n4"],
        ["an..14"],
        { components: ["an..14", { value: "an2", optional: true }], optional: true },
        { components: ["an..14"], optional: true },
        { components: ["a1"], optional: true },
        { components: ["n1"], optional: true },
        { components: ["an..35"], optional: true },
        { components: ["n1"], optional: true }
      ]
    })

    UNZ_SPEC = Validation::SegmentSpec.new({
      name: "UNZ",
      elements: [
        ["n..6"],
        ["an..14"]
      ]
    })

    UNH_SPEC = Validation::SegmentSpec.new({
      name: "UNH",
      elements: [
          ["an..14"],
          ["an..6", "an..3", "an..3", "an..2", { value: "an..6", optional: true }],
          { components: ["an..35"], optional: true },
          { components: ["n..2", { value: "a1", optional: true }], optional: true }
        ]
    })

    UNT_SPEC = Validation::SegmentSpec.new({
      name: "UNT",
      elements: [
        ["n..6"],
        ["an..14"]
      ]
    })

    attr_reader :unb, :messages, :unz

    def initialize(segment_stream)
      @segment_stream = segment_stream

      @messages = []
      @peek_buf = []

      read_interchange
    end

    private

    def read_interchange
      @unb = read_segment("UNB", UNB_SPEC)

      while s = peek_segment do
        if s.name == "UNZ"
          break
        else
          @messages << read_message
        end
      end

      @unz = read_segment("UNZ", UNZ_SPEC)

      s = peek_segment
      if s != nil
        raise ParseError.new(s.pos, "Expected end of interchange, but got #{s.name}")
      end

      validate_interchange_control_references
    end

    def read_message
      unh = read_segment("UNH", UNH_SPEC)
      segments = []

      while s = peek_segment do
        if s.name == "UNT"
          break
        else
          segments << read_segment
        end
      end

      unt = read_segment("UNT", UNT_SPEC)

      validate_message_segment_counts(segments, unt)
      validate_message_references(unh, unt)

      Message.new(unh: unh, segments: segments, unt: unt)
    end

    def read_segment(name = nil, segment_spec = nil)
      if @peek_buf.empty?
        peek_segment
      end
      segment = @peek_buf.shift

      if segment.nil?
        raise UnexpectedEndOfInputError.new(@segment_stream.next_pos)
      end

      if name != nil && segment.name != name
        raise ParseError.new(segment.pos, "Expected #{name} segment, got #{segment.name}")
      end

      if segment_spec
        segment_spec.validate(segment)
      end

      segment
    end

    def peek_segment
      if @peek_buf.empty?
        @peek_buf << @segment_stream.read
      end
      @peek_buf.last
    end

    def validate_message_segment_counts(segments, unt)
      unt_segment_count = unt.elements[0].components[0].text.to_i
      actual_segment_count = segments.length + 2 # +2 for UNH and UNT

      if unt_segment_count != actual_segment_count
        raise ParseError.new(unt.pos, "Segment count does not match: UNT:#{unt_segment_count} != Actual:#{actual_segment_count}")
      end
    end

    def validate_message_references(unh, unt)
      unh_message_reference = unh.elements[0].components[0].text
      unt_message_reference = unt.elements[1].components[0].text

      if unh_message_reference != unt_message_reference
        raise ParseError.new(unt, "Message control numbers do not match: UNH:#{unh_message_reference} != UNT:#{unt_message_reference}")
      end
    end

    def validate_interchange_control_references
      unb_control_reference = @unb.elements[4].components[0].text
      unz_control_reference = @unz.elements[1].components[0].text

      if unb_control_reference != unz_control_reference
        raise ParseError.new(@unz.pos, "Interchange control references do not match: UNB:#{unb_control_reference} != UNZ:#{unz_control_reference}")
      end
    end
  end
end
