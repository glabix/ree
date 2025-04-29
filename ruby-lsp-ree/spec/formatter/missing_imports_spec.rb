# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, @index) }

  before :each do
    with_server('') do |server, uri|
      index_fn(server, 'seconds_ago', 'sample_package')
      index_fn(server, 'create_item_cmd', 'create_package')
      @index = server.global_state.index 
    end
  end

  context "method calls" do
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
      expect(result.lines[2].strip).to eq('link :seconds_ago')
    end

    it "adds import link from other package" do
      source =  <<~RUBY
        class MyPackage::SomeClass
          fn :some_class do
            link :some_import1
          end
  
          def call(arg1)
            some_import1
            seconds_ago
          end
        end
      RUBY
  
      file_uri = URI("file://my_package/package/my_package/some_class.rb")
      result = subject.run_formatting(file_uri, ruby_document(source))
  
      expect(result.lines[2].strip).to eq('link :seconds_ago, from: :sample_package')
    end

    it "adds missing import link with do block" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            b = seconds_ago(1)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "adds missing import link for objects called outside method" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          SomeConst = seconds_ago(1)
  
          def call(arg1)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "adds multiple links" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
            
          def call(arg1)
            seconds_ago
            create_item_cmd
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :create_item_cmd, from: :create_package')
      expect(result.lines[3].strip).to eq('link :seconds_ago')
      expect(result.lines[4].strip).to eq('end')
    end

    it "doesn't add import if local method exist" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            seconds_ago
          end
  
          def seconds_ago
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result.lines[1].strip).to eq('fn :some_class')
    end
    
    it "doesn't add import if already imported" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :seconds_ago
          end
  
          def call(arg1)
            seconds_ago
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "doesn't add import twice" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          MyDate = seconds_ago

          def call(arg1)
            seconds_ago
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "adds import from nested method call" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            local_method(
              local_method([1, seconds_ago])
            )
          end

          def local_method(arg1)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "adds import from logical expression" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            my_var = 1 == 5 || seconds_ago.order(:id).first.user_id
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end
  end

  context "bean method calls" do
    it "adds missing import link for bean objects" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(arg1)
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "adds missing import link for bean objects in class root" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          SOME_CONST = seconds_ago.call_method
  
          def call(arg1)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "adds import link for calls from if predicate" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(arg1)
            return false if !seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end

    it "doesn't add import if local variable exist" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(arg1)
            seconds_ago = MyClass.new
  
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "doesn't add import if local variable inside block" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(arg1)
            if a == 1
              [1,2,3].each do |i|
                seconds_ago = i
              end
            end
  
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "doesn't add import if local variable assigned through multi assignment" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(arg1)
            x, seconds_ago = MyClass.new
  
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "doesn't add import if receiver is method argument" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(seconds_ago)
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "doesn't add import if receiver is keyword argument" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(seconds_ago:)
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "doesn't add import if receiver is splat args" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(*seconds_ago)
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "doesn't add import if receiver is kwargs" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(**seconds_ago)
            seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "doesn't add import if bean has receiver" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
          
          def call(arg1)
            arg1.seconds_ago.call_method
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    it "adds import from nested bean method call" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            local_method(
              seconds_ago.by_second(1).active,
              only: [:id]
            ).first
          end

          def local_method(arg1, fields)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :seconds_ago')
      expect(result.lines[3].strip).to eq('end')
    end
  end

  context "multiple found objects" do
    before :each do
      with_server('') do |server, uri|
        index_fn(server, 'duplicated_fn', 'package1')
        index_fn(server, 'duplicated_fn', 'sample_package')
        index_fn(server, 'duplicated_fn', 'package2')
        
        index_fn(server, 'do_something_with_my_date', 'ree_date')
        index_fn(server, 'do_something_with_my_date', 'ree_datetime')

        @index = server.global_state.index 
      end
    end

    it "adds import from same package by default" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            duplicated_fn
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :duplicated_fn')
      expect(result.lines[3].strip).to eq('end')
    end

    it "chooses datetime between ree_datetime and ree_date" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            do_something_with_my_date
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :do_something_with_my_date, from: :ree_datetime')
      expect(result.lines[3].strip).to eq('end')
    end

    it "adds import with placeholder if multiple objects found" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class
  
          def call(arg1)
            duplicated_fn
          end
        end
      RUBY
  
      result = subject.run_formatting('', ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :duplicated_fn, from: FILL_PACKAGE')
      expect(result.lines[3].strip).to eq('end')
    end
  end
end
