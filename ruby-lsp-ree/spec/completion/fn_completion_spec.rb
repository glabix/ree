# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  it "returns correct result for fn autocomplete request" do
    source =  <<~RUBY
      class SomeClass
        def something
          second
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago')

      send_completion_request(server, uri, { line: 2, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('seconds_ago')
    end
  end

  it "returns correct result for class includeing link dsl" do
    source =  <<~RUBY
      class SomeClass
        include Ree::LinkDSL
        include Enumerable

        def something
          second
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago')

      send_completion_request(server, uri, { line: 5, character: 5 })
      
      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('seconds_ago')
      expect(result.response.first.additional_text_edits.first.new_text).to match('link :seconds_ago')
    end
  end
end
