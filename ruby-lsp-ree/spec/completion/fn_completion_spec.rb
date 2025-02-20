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
      server.process_message(
        id: 1,
        method: "textDocument/completion",
        params: {
          textDocument: {
            uri: uri.to_s,
          },
          position: {
            line: 3,
            character: 5
          }
        }
      )

      result = server.pop_response
      pp result
      result = server.pop_response
      pp result
      result = server.pop_response
      pp result
    end
  end
end
