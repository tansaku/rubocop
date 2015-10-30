# encoding: utf-8

require 'spec_helper'

describe RuboCop::Cop::Lint::Debugger do
  subject(:cop) { described_class.new }

  include_examples 'debugger', 'debugger', 'debugger'
  include_examples 'debugger', 'byebug', 'byebug'
  include_examples 'debugger', 'pry binding', %w(binding.pry binding.remote_pry
                                                 binding.pry_remote Pry.rescue)
  include_examples 'debugger',
                   'capybara debug method', %w(save_and_open_page
                                               save_and_open_screenshot
                                               save_screenshot)
  include_examples 'debugger', 'debugger with an argument', 'debugger foo'
  include_examples 'debugger', 'byebug with an argument', 'byebug foo'
  include_examples 'debugger',
                   'pry binding with an argument', ['binding.pry foo',
                                                    'binding.remote_pry foo',
                                                    'binding.pry_remote foo']
  include_examples 'debugger',
                   'capybara debug method with an argument',
                   ['save_and_open_page foo',
                    'save_and_open_screenshot foo',
                    'save_screenshot foo']
  include_examples 'non-debugger', 'a non-pry binding', 'binding.pirate'

  ALL_COMMANDS = %w(debugger byebug pry remote_pry pry_remote
                    save_and_open_page save_and_open_screenshot
                    save_screenshot)

  ALL_COMMANDS.each do |src|
    include_examples 'non-debugger', "a #{src} in comments", "# #{src}"
    include_examples 'non-debugger', "a #{src} method", "code.#{src}"
  end
end
