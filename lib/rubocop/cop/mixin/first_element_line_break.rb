# encoding: utf-8

module RuboCop
  module Cop
    # Common functionality for checking for a line break before the first
    # element in a multi-line collection.
    module FirstElementLineBreak
      def autocorrect(node)
        ->(corrector) { corrector.insert_before(node.loc.expression, "\n") }
      end

      private

      def check_method_line_break(node, children)
        return if children.empty?

        return unless method_uses_parens?(node, children.first)

        check_children_line_break(node, children)
      end

      def method_uses_parens?(node, limit)
        source = node.loc.expression.source_line[0...limit.loc.column]
        source =~ /\s*\(\s*$/
      end

      def check_children_line_break(node, children, start = node)
        return if children.size < 2

        line = start.loc.line
        min = children.min_by { |n| n.loc.first_line }
        return if line != min.loc.first_line

        max = children.max_by { |n| n.loc.last_line }
        return if line == max.loc.last_line

        add_offense(min, :expression, self.class::MSG)
      end
    end
  end
end
