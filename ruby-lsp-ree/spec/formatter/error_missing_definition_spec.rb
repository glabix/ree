# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}) }

  before :each do
    @locales_cache = store_locales_cache
  end

  after :each do
    restore_locales_cache(@locales_cache)
  end

  it "adds error definition raised error" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('InvalidArg1Error = invalid_param_error(:invalid_arg1_error)')
  end

  it "adds error definition after last existing definition" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        InvalidArg2Error = invalid_param_error(:invalid_arg2_error)

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[4].strip).to eq('InvalidArg1Error = invalid_param_error(:invalid_arg1_error)')
  end

  it "adds error definition after fn block" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :somthing
        end

        def call(arg1)
          somthing
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result.lines[5].strip).to eq('InvalidArg1Error = invalid_param_error(:invalid_arg1_error)')
  end

  it "adds error on 'raise ErrorClass'" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        def call(arg1)
          raise InvalidArg1Error
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('InvalidArg1Error = invalid_param_error(:invalid_arg1_error)')
  end

  it "correctly adds multiple error definitions" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        def call(arg1)
          raise InvalidArg1Error.new
          raise InvalidArg2Error
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('InvalidArg1Error = invalid_param_error(:invalid_arg1_error)')
    expect(result.lines[4].strip).to eq('InvalidArg2Error = invalid_param_error(:invalid_arg2_error)')
  end

  it "doesn't add definition on 'raise string'" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        def call(arg1)
          raise 'some string'
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result).to eq(source)
  end

  it "adds both missing definition and contract throws" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        contract(Integer => nil)
        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('InvalidArg1Error = invalid_param_error(:invalid_arg1_error)')
    expect(result.lines[5].strip).to eq('contract(Integer => nil).throws(InvalidArg1Error)')
  end

  it "doesn't add definition for imported error" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_fn, import: -> { InvalidArg1Error }
        end

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't add definition for ruby standard error" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        def call(arg1)
          raise ArgumentError.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't add definition for custom defined class" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        class CustomError < StandardError; end

        def call(arg1)
          raise CustomError.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't add definition for custom class defined by assignment" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        CustomError = Class.new(StandardError)
        
        def call(arg1)
          raise CustomError.new
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end
end
