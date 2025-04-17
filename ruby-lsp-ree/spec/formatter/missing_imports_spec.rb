# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, @index) }

  before :each do
    with_server('') do |server, uri|
      index_fn(server, 'seconds_ago')
      @index = server.global_state.index 
    end

    # @formatter = RubyLsp::Ree::ReeFormatter.new([], {}, @index)
  end

  it "adds missing import link" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
          some_import1
          seconds_ago
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('link :seconds_ago')
  end

  # TODO it "adds missing import link with do block" do
end
