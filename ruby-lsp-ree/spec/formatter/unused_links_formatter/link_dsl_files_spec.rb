# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  it "removes unused import link" do
    source =  <<~RUBY
      class SamplePackage::SomeEntity
        include Ree::LinkDSL

        link :some_import1
        link :some_import2

        def call(arg1)
          some_import2
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[2].strip).to eq('')
    expect(result.lines[3].strip).to eq('link :some_import2')
    expect(result.lines[4].strip).to eq('')
  end

  it "coorectly removes last link" do
    source =  <<~RUBY
      class SamplePackage::SomeEntity
        include Ree::LinkDSL

        link :some_import1

        def call(arg1)
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[2].strip).to eq('')
    expect(result.lines[3].strip).to eq('')
  end

  it "removes unused import link if constant is not used" do
    source =  <<~RUBY
      class SamplePackage::SomeEntity
        include Ree::LinkDSL

        link :some_import1, import: -> { SomeConst }
        link :some_import2

        def call(arg1)
          some_import2
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[2].strip).to eq('')
    expect(result.lines[3].strip).to eq('link :some_import2')
    expect(result.lines[4].strip).to eq('')
  end

  it "correctly removes unused constant from new line" do
    source =  <<~RUBY
      class SamplePackage::SomeEntity
        include Ree::LinkDSL
          
        link :some_import1, import: -> { 
          SomeConst &
          SomeConst1 &
          SomeConst2
        }

        def call(arg1)
          SomeConst
          SomeConst2
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[2].strip).to eq('')
    expect(result.lines[3].strip).to eq('link :some_import1, import: -> { SomeConst & SomeConst2 }')
    expect(result.lines[4].strip).to eq('')
  end
end