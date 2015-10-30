# encoding: utf-8

require 'spec_helper'

describe RuboCop::Cop::Style::FirstMethodArgumentLineBreak do
  subject(:cop) { described_class.new }

  context 'args listed on the first line' do
    let(:source) do
      ['foo(bar,',
       '  baz)']
    end

    it 'detects the offense' do
      inspect_source(cop, source)

      expect(cop.offenses.length).to eq(1)
      expect(cop.offenses.first.line).to eq(1)
      expect(cop.highlights).to eq(['bar'])
    end

    it 'autocorrects the offense' do
      new_source = autocorrect_source(cop, source)

      expect(new_source).to eq(
        "foo(\n" \
        "bar,\n" \
        '  baz)')
    end
  end

  context 'arg spanning multiple lines' do
    let(:source) do
      ['something(3, bar: 1,',
       'baz: 2)']
    end

    it 'detects the offense' do
      inspect_source(cop, source)

      expect(cop.offenses.length).to eq(1)
      expect(cop.offenses.first.line).to eq(1)
      expect(cop.highlights).to eq(['3'])
    end

    it 'autocorrects the offense' do
      new_source = autocorrect_source(cop, source)

      expect(new_source).to eq(
        "something(\n" \
        "3, bar: 1,\n" \
        'baz: 2)')
    end
  end

  it 'ignores arguments listed on a single line' do
    inspect_source(cop, 'foo(bar, baz, bing)')

    expect(cop.offenses).to be_empty
  end

  it 'ignores arguments without parens' do
    inspect_source(
      cop,
      ['foo bar,',
       '  baz'])

    expect(cop.offenses).to be_empty
  end

  it 'ignores methods without arguments' do
    inspect_source(cop, 'foo')

    expect(cop.offenses).to be_empty
  end
end
