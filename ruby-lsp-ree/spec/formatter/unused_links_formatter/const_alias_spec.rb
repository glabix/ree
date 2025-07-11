# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  it "removes unused import link" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1, import: -> { SomeConst.as(MyConst) }
        end

        def call(arg1)
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class')
    expect(result.lines[2].strip).to eq('')
  end

  it "doesn't remove used constant" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1, import: -> { SomeConst.as(MyConst) }
        end

        def call(arg1)
          MyConst
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))
    expect(result).to eq(source)
  end

  it "correctly handles multiple constants with aliases" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1, import: -> { 
            SomeConst1.as(MyConst) & SomeConst2 & 
            SomeConst3.as(UnusedConst) & SomeConst4 
          }
        end

        def call(arg1)
          MyConst
          SomeConst4
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import1, import: -> { SomeConst1.as(MyConst) & SomeConst4 }')
    expect(result.lines[3].strip).to eq('end')
  end
end