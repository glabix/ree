# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  it "returns correct result for fn autocomplete request" do
    source =  <<~RUBY
      package_require("some_package/some_path")

      RSpec.describe SomePackage::SomeFn, type: [:autoclean] do
        link :some_other_fn, from: :other_package

        it "cheacks something" do
          fn_from_other_pack
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'fn_from_other_package', 'some_other_package')

      send_completion_request(server, uri, { line: 6, character: 5 })
      
      result = server.pop_response
      pp result
      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('fn_from_other_package')
    end
  end
end


