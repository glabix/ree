# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  it "removes unused import link" do
    source =  <<~RUBY
      package_require("some_package/services/some_class")

      RSpec.describe SamplePackage::SomeClass, type: [:autoclean] do
        link :some_import1
        link :some_import2

        it {
          some_import2
        }
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('link :some_import2')
    expect(result.lines[4].strip).to eq('')
  end

  it "removes unused import link if constant is not used" do
    source =  <<~RUBY
      package_require("some_package/services/some_class")

      RSpec.describe SamplePackage::SomeClass, type: [:autoclean] do
        link :some_import1, import: -> { SomeConst }
        link :some_import2

        it {
          some_import2
        }
      end
    RUBY
    
    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('link :some_import2')
    expect(result.lines[4].strip).to eq('')
  end

  it "correctly removes unused constant from new line" do
    source =  <<~RUBY
      package_require("some_package/services/some_class")

      RSpec.describe SamplePackage::SomeClass, type: [:autoclean] do
        link :some_import1, import: -> { 
          SomeConst &
          SomeConst1 &
          SomeConst2
        }

        it {
          SomeConst
          SomeConst2
        }
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[3].strip).to eq('link :some_import1, import: -> { SomeConst & SomeConst2 }')
    expect(result.lines[4].strip).to eq('')
  end
end