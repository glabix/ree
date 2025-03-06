# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::DefinitionListener" do
  it "returns correct result for fn definition request" do
    source =  <<~RUBY
      class SomeClass
        link :seconds_ago

        def something
          seconds_ago
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago')

      send_definition_request(server, uri, { line: 4, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq('file:///seconds_ago.rb')
    end
  end
end
