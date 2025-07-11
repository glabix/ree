# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  it "removes unused import link" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
          link :some_import2
        end

        def call(arg1)
          some_import2
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import2')
    expect(result.lines[3].strip).to eq('end')
  end

  it "removes do block if last unused import link removed" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result.lines[1].strip).to eq('fn :some_class')
    expect(result.lines[2].strip).to eq('')
  end  

  it "doesn't remove link if it is used as a call receiver" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import_object
        end

        def call(arg1)

          some_import_object.call
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't remove link if it is used in a call chain" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_types
        end

        def call(arg1)
          some_var = my_dataset
            .by_user(user_id)
            .by_type(some_types.type_1, arg1)
            .by_arg(arg1)
            .first
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't remove link if it is used in if condition" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
          if true
            return
          else
            some_import1
          end
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't remove link if it is used in case condition" do
    source1 =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
          case arg1 
          when 0
            return 0
          when 1
            some_import1
          else
            return nil
          end
        end
      end
    RUBY

    source2 =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
          case arg1 
          when 1
            return 1
          else
            some_import1
          end
        end
      end
    RUBY

    source3 =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
          case some_import1 
          when 1
            return 1
          else
            return nil
          end
        end
      end
    RUBY

    source4 =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
          case arg1
          when some_import1 
            return 1
          else
            return nil
          end
        end
      end
    RUBY

    result1 = subject.run_formatting(sample_file_uri, ruby_document(source1))
    result2 = subject.run_formatting(sample_file_uri, ruby_document(source2))
    result3 = subject.run_formatting(sample_file_uri, ruby_document(source3))
    result4 = subject.run_formatting(sample_file_uri, ruby_document(source4))

    expect(result1).to eq(source1)
    expect(result2).to eq(source2)
    expect(result3).to eq(source3)
    expect(result4).to eq(source4)
  end

  it "doesn't remove link if it is used in a rescue" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
        end

        def call(arg1)
          do_something
        rescue
          some_import1
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't remove link if it is used in a rescue inside block" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :handle_error
        end

        def call(items)
          items.each do |item|
            do_something
          rescue => e
            handle_error(e)
          end
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't remove link if it is used on the top level of class" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import_fn
        end

        x = some_import_fn

        def call(arg1)
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "doesn't remove import link if alias is used" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import, as: :some_import2
        end

        def call(arg1)
          some_import2
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import, as: :some_import2')
    expect(result.lines[3].strip).to eq('end')
  end

  it "removes import link if usage is a symbol" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
          link :some_import2
        end

        def call(arg1)
          some_import2
          :some_import1
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import2')
    expect(result.lines[3].strip).to eq('end')
  end

  it "removes import link if usage is a call with receiver" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
          link :some_import2
        end

        def call(arg1)
          some_import2
          my_obj = MyObj.new
          my_obj.some_import1
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import2')
    expect(result.lines[3].strip).to eq('end')
  end
end