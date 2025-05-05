# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  it "returns correct result for enum autocomplete request" do
    source =  <<~RUBY
      class SomeClass
        def something
          some_e
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_ree_object(server, 'some_enum', :enum)

      send_completion_request(server, uri, { line: 2, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('some_enum')
    end
  end

  it "returns correct result for enum method autocomplete request" do
    source = <<~RUBY
      class SomeClass
        fn :someclass do 
          link :some_enum
        end

        def something
          some_enum.firs
        end
      end
    RUBY

    bean_source = <<~RUBY
      class SamplePackage::SomeEnum
        enum :some_enum

        val :first_val, 0
      end
    RUBY

    allow(RubyLsp::Ree::ParsedDocumentBuilder).to receive(:build_from_uri).and_return(RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(bean_source, type: :enum))

    with_server(source) do |server, uri|
      index_ree_object(server, 'some_enum', :enum, 'sample_package', URI.parse('some_enum.rb'))

      send_completion_request(server, uri, { line: 6, character: 15 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('first_val')
    end
  end
end
