# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::HoverListener" do
  it "returns correct result for fn hover request" do
    source =  <<~RUBY
      class SomeClass
        def something
          seconds_ago
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago')

      send_hover_request(server, uri, { line: 2, character: 5 })
      
      result = server.pop_response
      expect(result.response.contents.value).to match('seconds_ago')
    end
  end
end
