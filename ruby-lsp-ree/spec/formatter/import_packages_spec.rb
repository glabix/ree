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

  it "changes package if incorrect link package" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :create_item_cmd, from: :sample_package
        end

        def call(arg1)
          create_item_cmd
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result.lines[2].strip).to eq('link :create_item_cmd, from: :create_package')
  end

  it "adds package if no object found in current package" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :create_item_cmd
        end

        def call(arg1)
          create_item_cmd
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result.lines[2].strip).to eq('link :create_item_cmd, from: :create_package')
  end

  it "correctly inserts from param if import constants exist" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :create_item_cmd, import: -> { SomeEntity }
        end

        def call(arg1)
          SomeEntity
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result.lines[2].strip).to eq('link :create_item_cmd, import: -> { SomeEntity }, from: :create_package')
  end

  it "removes 'from' section if no object found in 'from' package but found in current" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :seconds_ago, from: :create_package, import: -> { SomeEntity }
        end

        def call(arg1)
          SomeEntity
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result.lines[2].strip).to eq('link :seconds_ago, import: -> { SomeEntity }')
  end

  context "multiple found link" do
    before :each do
      with_server('') do |server, uri|
        index_fn(server, 'duplicated_fn', 'package1')
        index_fn(server, 'duplicated_fn', 'package2')
        
        @index = server.global_state.index 
      end
    end

    it "doesn't change file if object by link not found and several candidates exist" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :duplicated_fn
          end

          def call(arg1)
            duplicated_fn
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result.lines[2].strip).to eq('link :duplicated_fn')
    end
  end
end