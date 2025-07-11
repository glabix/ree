# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  it "doesn't remove import link if consts are used" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          import -> { SomeConst }, from: :some_package
        end

        def call(arg1)
          SomeConst.do_something
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('import -> { SomeConst }, from: :some_package')
    expect(result.lines[3].strip).to eq('end')
  end

  it "removes only unused consts from link" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          import -> { SomeConst & SomeConst2 }, from: :some_package
        end

        def call(arg1)
          SomeConst.do_something
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('import -> { SomeConst }, from: :some_package')
    expect(result.lines[3].strip).to eq('end')
  end

  it "removes link if no used consts" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          import -> { SomeConst & SomeConst2 }
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