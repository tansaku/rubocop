# encoding: utf-8

module RuboCop
  module Cop
    module Style
      # This cop checks for extra underscores in variable assignment.
      #
      # @example
      #   # bad
      #   a, b, _ = foo()
      #   a, b, _, = foo()
      #   a, _, _ = foo()
      #   a, _, _, = foo()
      #
      #   #good
      #   a, b, = foo()
      #   a, = foo()
      #   *a, b, _ = foo()  => We need to know to not include 2 variables in a
      #   a, *b, _ = foo()  => The correction `a, *b, = foo()` is a syntax error
      class TrailingUnderscoreVariable < Cop
        include SurroundingSpace

        MSG = 'Do not use trailing `_`s in parallel assignment.'.freeze
        UNDERSCORE = '_'.freeze

        def on_masgn(node)
          left, = *node
          variables = *left
          first_offense = find_first_offense(variables)

          return if first_offense.nil?

          range =
            Parser::Source::Range.new(node.loc.expression.source_buffer,
                                      first_offense.loc.expression.begin_pos,
                                      variables.last.loc.expression.end_pos)
          add_offense(node, range)
        end

        def autocorrect(node)
          left, right = *node
          variables = *left
          first_offense = find_first_offense(variables)

          end_position =
            if first_offense.loc.expression == variables.first.loc.expression
              right.loc.expression.begin_pos
            else
              node.loc.operator.begin_pos
            end

          range =
            Parser::Source::Range.new(node.loc.expression.source_buffer,
                                      first_offense.loc.expression.begin_pos,
                                      end_position)

          ->(corrector) { corrector.remove(range) unless range.nil? }
        end

        private

        def find_first_offense(variables)
          first_offense = nil

          variables.reverse_each do |variable|
            var, = *variable
            var, = *var
            if allow_named_underscore_variables
              break unless var == :_
            else
              break unless var.to_s.start_with?(UNDERSCORE)
            end
            first_offense = variable
          end

          return nil if first_offense.nil?

          first_offense_index = variables.index(first_offense)
          0.upto(first_offense_index - 1).each do |index|
            return nil if variables[index].splat_type?
          end

          first_offense
        end

        def allow_named_underscore_variables
          @allow_named_underscore_variables ||=
            cop_config['AllowNamedUnderscoreVariables']
        end
      end
    end
  end
end
