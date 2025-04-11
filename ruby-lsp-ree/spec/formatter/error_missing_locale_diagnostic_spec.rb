# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}) }

  it "adds diagnostics if error locale is missing" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:invalid_arg1_error)
        InvalidArg2Error = invalid_param_error(:invalid_arg2_error, "some_unexisting_locale_path.some_unexsting_locale_path")

        contract(Integer => nil).throws(InvalidArg2Error)
        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_diagnostic(sample_file_uri, ruby_document(source))

    expect(result.size).to eq(4)
    expect(result.first.message).to match('Missing locale')
  end

  it "adds diagnostics for _MISSING_LOCALE_ placeholder" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:invalid_arg2_error, "local_placeholder_key")

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_diagnostic(sample_file_uri, ruby_document(source))

    expect(result.size).to eq(2)
    expect(result.first.message).to match('Missing locale')
  end
end
