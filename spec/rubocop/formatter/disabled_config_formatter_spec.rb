# encoding: utf-8

require 'spec_helper'

module RuboCop
  module Formatter
    describe DisabledConfigFormatter do
      subject(:formatter) { described_class.new(output) }
      let(:output) do
        o = StringIO.new
        def o.path
          '.rubocop_todo.yml'
        end
        o
      end
      let(:offenses) do
        [RuboCop::Cop::Offense.new(:convention, location, 'message', 'Cop1'),
         RuboCop::Cop::Offense.new(:convention, location, 'message', 'Cop2')]
      end
      let(:location) { OpenStruct.new(line: 1, column: 5) }
      before { $stdout = StringIO.new }

      describe '#finished' do
        it 'displays YAML configuration disabling all cops with offenses' do
          formatter.file_started('test_a.rb', {})
          formatter.file_finished('test_a.rb', offenses)
          formatter.file_started('test_b.rb', {})
          formatter.file_finished('test_b.rb', [offenses.first])
          formatter.finished(['test_a.rb', 'test_b.rb'])
          expect(output.string).to eq(format(described_class::HEADING,
                                             'rubocop --auto-gen-config') +
                                      ['',
                                       '',
                                       '# Offense count: 2',
                                       'Cop1:',
                                       '  Exclude:',
                                       "    - 'test_a.rb'",
                                       "    - 'test_b.rb'",
                                       '',
                                       '# Offense count: 1',
                                       'Cop2:',
                                       '  Exclude:',
                                       "    - 'test_a.rb'",
                                       ''].join("\n"))
          expect($stdout.string)
            .to eq(['Created .rubocop_todo.yml.',
                    'Run `rubocop --config .rubocop_todo.yml`, or',
                    'add inherit_from: .rubocop_todo.yml in a .rubocop.yml ' \
                    'file.',
                    ''].join("\n"))
        end

        it 'displays a file exclusion list up to a maximum of 15 offences' do
          exclusion_list = []
          file_list = []

          15.times do |index|
            file_name = format('test_%02d.rb', index)
            formatter.file_started(file_name, {})
            formatter.file_finished(file_name, offenses)
            file_list << file_name
            exclusion_list << "    - '#{file_name}'"
          end

          file_list << 'test.rb'
          formatter.file_started('test.rb', {})
          formatter.file_finished('test.rb', [offenses.first])
          formatter.finished(file_list)
          expect(output.string).to eq(format(described_class::HEADING,
                                             'rubocop --auto-gen-config') +
                                      ['',
                                       '',
                                       '# Offense count: 16',
                                       'Cop1:',
                                       '  Enabled: false',
                                       '',
                                       '# Offense count: 15',
                                       'Cop2:',
                                       '  Exclude:',
                                       exclusion_list,
                                       ''].flatten.join("\n"))
        end

        it 'can be configured to set the exclusion list limit' do
          exclusion_list = []
          file_list = []
          options = {
            cli_options: {
              exclude_limit: 5
            }
          }

          15.times do |index|
            file_name = format('test_%02d.rb', index)
            formatter.file_started(file_name, options)
            formatter.file_finished(file_name, offenses)
            file_list << file_name
            exclusion_list << "    - '#{file_name}'"
          end

          file_list << 'test.rb'
          formatter.file_started('test.rb', options)
          formatter.file_finished('test.rb', [offenses.first])
          formatter.finished(file_list)
          expect(output.string).to eq(format(described_class::HEADING,
                                             'rubocop --auto-gen-config ' \
                                             '--exclude-limit 5') +
                                      ['',
                                       '',
                                       '# Offense count: 16',
                                       'Cop1:',
                                       '  Enabled: false',
                                       '',
                                       '# Offense count: 15',
                                       'Cop2:',
                                       '  Enabled: false',
                                       ''].flatten.join("\n"))
        end
      end
    end
  end
end
