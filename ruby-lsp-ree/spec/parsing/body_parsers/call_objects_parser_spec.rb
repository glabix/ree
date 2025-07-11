# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CallObjectsParser" do
  it "parses call objects called with splat" do
     source =  <<~RUBY
      class SamplePackage::SomeClass
        def call(arg1)
          a, b = *some_import1
        end
      end
    RUBY

    parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
    parser = RubyLsp::Ree::CallObjectsParser.new(parsed_doc)

    expect(parser.class_call_objects.map(&:name)).to eq([:some_import1])
  end
end