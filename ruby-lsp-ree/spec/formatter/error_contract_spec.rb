# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new }

  it "adds error to contract throw section" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:invalid_arg1_error)
        InvalidArg2Error = invalid_param_error(:invalid_arg2_error)

        contract(Integer => nil).throws(InvalidArg2Error)
        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    document = RubyLsp::RubyDocument.new(source: source, version: 1, uri: URI.parse(''), global_state: RubyLsp::GlobalState.new)
    result = subject.run_formatting('', document)
    
    expect(result.lines[6].strip).to eq('contract(Integer => nil).throws(InvalidArg2Error, InvalidArg1Error)')
  end

  xit "adds throw section if needed" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:invalid_arg1_error)

        contract(Integer => nil)
        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    document = RubyLsp::RubyDocument.new(source: source, version: 1, uri: URI.parse(''), global_state: RubyLsp::GlobalState.new)
    result = subject.run_formatting('', document)
    
    expect(result.lines[5].strip).to eq('contract(Integer => nil).throws(InvalidArg1Error)')
  end
end
