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

    result = subject.run_formatting('', ruby_document(source))
    
    expect(result.lines[6].strip).to eq('contract(Integer => nil).throws(InvalidArg2Error, InvalidArg1Error)')
  end

  it "handles spaces in throw section" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:invalid_arg1_error)
        InvalidArg2Error = invalid_param_error(:invalid_arg2_error)

        contract(Integer => nil).throws(InvalidArg2Error  )
        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting('', ruby_document(source))
    
    expect(result.lines[6].strip).to eq('contract(Integer => nil).throws(InvalidArg2Error, InvalidArg1Error)')
  end

  it "adds throw section if needed" do
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

    result = subject.run_formatting('', ruby_document(source))
    
    expect(result.lines[5].strip).to eq('contract(Integer => nil).throws(InvalidArg1Error)')
  end

  it "handles case when error is raised in nested method" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:invalid_arg1_error)

        contract(Integer => nil)
        def call(arg1)
          if true 
            [1,2,3].each do 
              first_method_raising_error()
            end
          end
        end

        private

        def first_method_raising_error
          while true
            second_method_raising_error()
            break
          end
        end

        def second_method_raising_error
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting('', ruby_document(source))
    
    expect(result.lines[5].strip).to eq('contract(Integer => nil).throws(InvalidArg1Error)')
  end

  it "adds imported error to contract throw section" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :some_fn, import: -> { InvalidArg1Error }
        end

        InvalidArg2Error = invalid_param_error(:invalid_arg2_error)

        contract(Integer => nil).throws(InvalidArg2Error)
        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    result = subject.run_formatting('', ruby_document(source))
    
    expect(result.lines[7].strip).to eq('contract(Integer => nil).throws(InvalidArg2Error, InvalidArg1Error)')
  end

  # TODO it correctly adds error to multiline throw section
end
