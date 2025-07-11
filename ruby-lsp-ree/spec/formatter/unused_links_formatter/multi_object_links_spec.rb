# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  it "doesn't remove import link if objects are used" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import, :some_import2
        end

        def call(arg1)
          some_import
          some_import2
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import, :some_import2')
    expect(result.lines[3].strip).to eq('end')
  end

  it "removes only unused objects from link" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import, :some_import2
        end

        def call(arg1)
          some_import
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import')
    expect(result.lines[3].strip).to eq('end')
  end

  it "removes link if no used objects" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import, :some_import2
        end

        def call(arg1)
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class')
    expect(result.lines[2].strip).to eq('')
  end
end