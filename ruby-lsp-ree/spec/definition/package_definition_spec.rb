# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::DefinitionListener" do
  it "returns correct result for link package" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :seconds_ago, from: :package1
        end

        def something
          seconds_ago
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago', 'package1')

      send_definition_request(server, uri, { line: 2, character: 33 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq('file:///package1/package/package1.rb')
    end
  end
end
