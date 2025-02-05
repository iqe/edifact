require_relative 'message_specification_node'

module Edifact
  class SegmentValidator
    def initialize(parser, message_specification)
      @parser = parser
      @node = MessageSpecificationNode.new(nil, 0, message_specification)

      @parser.on(:segment) do |segment|
        on_segment(segment)
      end
    end

    private

    def on_segment(segment)
      @node.next.each do |n|
        if n.name == segment.name
          if n.index == 0
            n.parent.visits += 1
            n.parent.segments.each {|c| c.visits = 0}
          end
          n.visits += 1
          @node = n
          return
        end
      end

      raise "Position #{segment.pos}: Invalid segment: #{segment.name} after #{@node.name}. Expected one of: #{@node.next.map(&:name).join(", ")}"
    end
  end
end
