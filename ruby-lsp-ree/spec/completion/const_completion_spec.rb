# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  it "places already imported constants first" do
    source =  <<~RUBY
      class SomeFn
        fn :some_fn do
          link :some_package_fn, from: :some_package, import: -> { User }
        end

        def something
          Use
        end
      end
    RUBY

    file_uri1 = URI("file:///some_package/package/some_package/some_package_fn.rb")
    file_uri2 = URI("file:///other_package/package/other_package/other_package_fn.rb")

    with_server(source) do |server, uri|
      index_class(server, 'User', file_uri2)
      index_class(server, 'User', file_uri1)

      send_completion_request(server, uri, { line: 6, character: 7 })

      result = server.pop_response

      expect(result.response.size).to eq(2)
      expect(result.response[0].label).to eq('User')
      expect(result.response[0].label_details.description).to eq('imported from: :some_package')
      expect(result.response[1].label).to eq('User')
      expect(result.response[1].label_details.description).to eq('from: :other_package')
    end
  end
end
