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

    file_uri = URI("file:///fake.rb")
    location = RubyIndexer::Location.new(0, 0, 0, 0)

    with_server(source) do |server, uri|
      server.global_state.index.add(RubyIndexer::Entry::Method.new(
        'seconds_ago',
        file_uri,
        location,
        location,
        "ree_object\ntype: :fn",
        [],
        RubyIndexer::Entry::Visibility::PUBLIC,
        nil,
      ))

      server.process_message(
        id: 1,
        method: "textDocument/completion",
        params: {
          textDocument: {
            uri: uri,
          },
          position: {
            line: 2,
            character: 5
          }
        }
      )

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('seconds_ago')
    end
  end
end
