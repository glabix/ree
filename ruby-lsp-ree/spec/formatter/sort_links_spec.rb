# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}) }

  it "sorts links inside fn block by groups" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :linked_service_3, from: :some_package
          import -> { SomeConst }, from: :some_package
          link :linked_service_1, target: :both
          link 'some/file/path', -> { SomeConst2 }
          link :linked_service_2
        end

        def call
          linked_service_3
          linked_service_2
          linked_service_1
          SomeConst
          SomeConst2
        end
      end
    RUBY

    result = subject.run_formatting('', ruby_document(source))
    
    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :linked_service_2')
    expect(result.lines[3].strip).to eq('')
    expect(result.lines[4].strip).to eq('link :linked_service_1, target: :both')
    expect(result.lines[5].strip).to eq('')
    expect(result.lines[6].strip).to eq('link :linked_service_3, from: :some_package')
    expect(result.lines[7].strip).to eq('')
    expect(result.lines[8].strip).to eq("link 'some/file/path', -> { SomeConst2 }")
    expect(result.lines[9].strip).to eq('')
    expect(result.lines[10].strip).to eq('import -> { SomeConst }, from: :some_package')
    expect(result.lines[11].strip).to eq('end')
  end
end
