# encoding: utf-8

require 'spec_helper'

describe RuboCop::Cop::Style::BlockDelimiters, :config do
  subject(:cop) { described_class.new(config) }

  context 'Semantic style' do
    cop_config = {
      'EnforcedStyle' => 'semantic',
      'ProceduralMethods' => %w(tap),
      'FunctionalMethods' => %w(let),
      'IgnoredMethods' => %w(lambda)
    }

    let(:cop_config) { cop_config }

    it 'accepts a multi-line block with braces if the return value is ' \
       'assigned' do
      inspect_source(cop, ['foo = map { |x|',
                           '  x',
                           '}'])
      expect(cop.offenses).to be_empty
    end

    it 'accepts a multi-line block with braces if it is the return value ' \
       'of its scope' do
      inspect_source(cop, ['block do',
                           '  map { |x|',
                           '    x',
                           '  }',
                           'end'])
      expect(cop.offenses).to be_empty
    end

    it 'accepts a multi-line block with braces when passed to a method' do
      inspect_source(cop, ['puts map { |x|',
                           '  x',
                           '}'])
      expect(cop.offenses).to be_empty
    end

    it 'accepts a multi-line block with braces when chained' do
      inspect_source(cop, ['map { |x|',
                           '  x',
                           '}.inspect'])
      expect(cop.offenses).to be_empty
    end

    it 'accepts a multi-line block with braces when passed to a known ' \
       'functional method' do
      inspect_source(cop, ['let(:foo) {',
                           '  x',
                           '}'])
      expect(cop.offenses).to be_empty
    end

    it 'registers an offense for a multi-line block with braces if the ' \
       'return value is not used' do
      inspect_source(cop, ['each { |x|',
                           '  x',
                           '}'])
      expect(cop.messages)
        .to eq(['Prefer `do...end` over `{...}` for procedural blocks.'])
    end

    it 'registers an offense for a multi-line block with do-end if the ' \
       'return value is assigned' do
      inspect_source(cop, ['foo = map do |x|',
                           '  x',
                           'end'])
      expect(cop.messages)
        .to eq(['Prefer `{...}` over `do...end` for functional blocks.'])
    end

    it 'registers an offense for a multi-line block with do-end if the ' \
       'return value is passed to a method' do
      inspect_source(cop, ['puts (map do |x|',
                           '  x',
                           'end)'])
      expect(cop.messages)
        .to eq(['Prefer `{...}` over `do...end` for functional blocks.'])
    end

    it 'accepts a multi-line block with do-end if it is the return value ' \
       'of its scope' do
      inspect_source(cop, ['block do',
                           '  map do |x|',
                           '    x',
                           '  end',
                           'end'])
      expect(cop.messages).to be_empty
    end

    it 'accepts a single line block with {} if used in an if statement' do
      inspect_source(cop, 'return if any? { |x| x }')
      expect(cop.messages).to be_empty
    end

    it 'accepts a single line block with {} if used in a logical or' do
      inspect_source(cop, 'any? { |c| c } || foo')
      expect(cop.messages).to be_empty
    end

    it 'accepts a single line block with {} if used in a logical and' do
      inspect_source(cop, 'any? { |c| c } && foo')
      expect(cop.messages).to be_empty
    end

    it 'accepts a single line block with {} if used in an array' do
      inspect_source(cop, '[detect { true }, other]')
      expect(cop.messages).to be_empty
    end

    it 'accepts a single line block with {} if used in an irange' do
      inspect_source(cop, 'detect { true }..other')
      expect(cop.messages).to be_empty
    end

    it 'accepts a single line block with {} if used in an erange' do
      inspect_source(cop, 'detect { true }...other')
      expect(cop.messages).to be_empty
    end

    it 'accepts a multi-line functional block with do-end if it is ' \
       'a known procedural method' do
      inspect_source(cop, ['foo = bar.tap do |x|',
                           '  x.age = 3',
                           'end'])
      expect(cop.messages).to be_empty
    end

    it 'accepts a multi-line functional block with do-end if it is ' \
       'an ignored method' do
      inspect_source(cop, ['foo = lambda do',
                           '  puts 42',
                           'end'])
      expect(cop.messages).to be_empty
    end

    it 'registers an offense for a single line procedural block' do
      inspect_source(cop, 'each { |x| puts x }')
      expect(cop.messages)
        .to eq(['Prefer `do...end` over `{...}` for procedural blocks.'])
    end

    it 'accepts a single line block with do-end if it is procedural' do
      inspect_source(cop, 'each do |x| puts x; end')
      expect(cop.messages).to be_empty
    end

    it 'auto-corrects { and } to do and end if it is a procedural block' do
      source = <<-END.strip_indent
        each { |x|
          x
        }
      END

      expected_source = <<-END.strip_indent
        each do |x|
          x
        end
      END

      new_source = autocorrect_source(cop, source)
      expect(new_source).to eq(expected_source)
    end

    it 'does not auto-correct {} to do-end if it is a known functional ' \
       'method' do
      source = <<-END.strip_indent
        let(:foo) { |x|
          x
        }
      END

      new_source = autocorrect_source(cop, source)
      expect(new_source).to eq(source)
    end

    it 'does not autocorrect do-end to {} if it is a known procedural ' \
       'method' do
      source = <<-END.strip_indent
        foo = bar.tap do |x|
          x.age = 1
        end
      END

      new_source = autocorrect_source(cop, source)
      expect(new_source).to eq(source)
    end

    it 'auto-corrects do-end to {} if it is a functional block' do
      source = <<-END.strip_indent
        foo = map do |x|
          x
        end
      END

      expected_source = <<-END.strip_indent
        foo = map { |x|
          x
        }
      END

      new_source = autocorrect_source(cop, source)
      expect(new_source).to eq(expected_source)
    end

    it 'auto-corrects do-end to {} if it is a functional block and does ' \
       'not change the meaning' do
      source = <<-END.strip_indent
        puts (map do |x|
          x
        end)
      END

      expected_source = <<-END.strip_indent
        puts (map { |x|
          x
        })
      END

      new_source = autocorrect_source(cop, source)
      expect(new_source).to eq(expected_source)
    end
  end

  context 'line count-based style' do
    let(:cop_config) { { 'EnforcedStyle' => 'line_count_based' } }

    it 'accepts a multi-line block with do-end' do
      inspect_source(cop, ['each do |x|',
                           'end'])
      expect(cop.offenses).to be_empty
    end

    it 'registers an offense for a single line block with do-end' do
      inspect_source(cop, 'each do |x| end')
      expect(cop.messages)
        .to eq(['Prefer `{...}` over `do...end` for single-line blocks.'])
    end

    it 'accepts a single line block with braces' do
      inspect_source(cop, 'each { |x| }')
      expect(cop.offenses).to be_empty
    end

    it 'auto-corrects do and end for single line blocks to { and }' do
      new_source = autocorrect_source(cop, 'block do |x| end')
      expect(new_source).to eq('block { |x| }')
    end

    it 'does not auto-correct do-end if {} would change the meaning' do
      src = "s.subspec 'Subspec' do |sp| end"
      new_source = autocorrect_source(cop, src)
      expect(new_source).to eq(src)
    end

    it 'does not auto-correct {} if do-end would change the meaning' do
      src = ['foo :bar, :baz, qux: lambda { |a|',
             '  bar a',
             '}'].join("\n")
      new_source = autocorrect_source(cop, src)
      expect(new_source).to eq(src)
    end

    context 'when there are braces around a multi-line block' do
      it 'registers an offense in the simple case' do
        inspect_source(cop, ['each { |x|',
                             '}'])
        expect(cop.messages)
          .to eq(['Avoid using `{...}` for multi-line blocks.'])
      end

      it 'accepts braces if do-end would change the meaning' do
        src = ['scope :foo, lambda { |f|',
               '  where(condition: "value")',
               '}',
               '',
               'expect { something }.to raise_error(ErrorClass) { |error|',
               '  # ...',
               '}',
               '',
               'expect { x }.to change {',
               '  Counter.count',
               '}.from(0).to(1)']
        inspect_source(cop, src)
        expect(cop.offenses).to be_empty
      end

      it 'registers an offense for braces if do-end would not change ' \
         'the meaning' do
        src = ['scope :foo, (lambda { |f|',
               '  where(condition: "value")',
               '})',
               '',
               'expect { something }.to(raise_error(ErrorClass) { |error|',
               '  # ...',
               '})']
        inspect_source(cop, src)
        expect(cop.offenses.size).to eq(2)
      end

      it 'can handle special method names such as []= and done?' do
        src = ['h2[k2] = Hash.new { |h3,k3|',
               '  h3[k3] = 0',
               '}',
               '',
               'x = done? list.reject { |e|',
               '  e.nil?',
               '}']
        inspect_source(cop, src)
        expect(cop.messages)
          .to eq(['Avoid using `{...}` for multi-line blocks.'])
      end

      it 'auto-corrects { and } to do and end' do
        source = <<-END.strip_indent
          each{ |x|
            some_method
            other_method
          }
        END

        expected_source = <<-END.strip_indent
          each do |x|
            some_method
            other_method
          end
        END

        new_source = autocorrect_source(cop, source)
        expect(new_source).to eq(expected_source)
      end

      it 'auto-corrects adjacent curly braces correctly' do
        source = ['(0..3).each { |a| a.times {',
                  '  puts a',
                  '}}']

        new_source = autocorrect_source(cop, source)
        expect(new_source).to eq(['(0..3).each do |a| a.times do',
                                  '  puts a',
                                  'end end'].join("\n"))
      end

      it 'does not auto-correct {} if do-end would introduce a syntax error' do
        src = ['my_method :arg1, arg2: proc {',
               '  something',
               '}, arg3: :another_value'].join("\n")
        new_source = autocorrect_source(cop, src)
        expect(new_source).to eq(src)
      end
    end
  end

  context 'braces for chaining style' do
    let(:cop_config) { { 'EnforcedStyle' => 'braces_for_chaining' } }

    it 'accepts a multi-line block with do-end' do
      inspect_source(cop, ['each do |x|',
                           'end'])
      expect(cop.offenses).to be_empty
    end

    it 'registers an offense for multi-line chained do-end blocks' do
      inspect_source(cop, ['each do |x|',
                           'end.map(&:to_s)'])
      expect(cop.messages)
        .to eq([
          'Prefer `{...}` over `do...end` for multi-line chained blocks.'])
    end

    it 'auto-corrects do-end for chained blocks' do
      src = ['each do |x|',
             'end.map(&:to_s)']
      new_source = autocorrect_source(cop, src)
      expect(new_source).to eq("each { |x|\n}.map(&:to_s)")
    end

    it 'registers an offense for a single line block with do-end' do
      inspect_source(cop, 'each do |x| end')
      expect(cop.messages)
        .to eq(['Prefer `{...}` over `do...end` for single-line blocks.'])
    end

    it 'accepts a single line block with braces' do
      inspect_source(cop, 'each { |x| }')
      expect(cop.offenses).to be_empty
    end

    context 'when there are braces around a multi-line block' do
      it 'registers an offense in the simple case' do
        inspect_source(cop, ['each { |x|',
                             '}'])
        expect(cop.messages)
          .to eq(['Prefer `do...end` for multi-line blocks without chaining.'])
      end

      it 'allows when the block is being chained' do
        inspect_source(cop, ['each { |x|',
                             '}.map(&:to_sym)'])
        expect(cop.offenses).to be_empty
      end
    end
  end
end
