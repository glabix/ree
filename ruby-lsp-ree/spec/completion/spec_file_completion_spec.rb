# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  let(:source) do
    <<~RUBY
      package_require("some_package/some_path")

      RSpec.describe SomePackage::SomeFn, type: [:autoclean] do
        link :some_other_fn, from: :other_package

        it "cheacks something" do
          fn_from_other_pack
          some_other_
        end
      end
    RUBY
  end

  it "returns correct result for fn autocomplete request" do
    with_server(source) do |server, uri|
      index_fn(server, 'fn_from_other_package', 'some_other_package')

      send_completion_request(server, uri, { line: 6, character: 5 })
      
      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('fn_from_other_package')
      expect(result.response.first.additional_text_edits.size).to eq(1)
      expect(result.response.first.additional_text_edits.first.new_text).to match("link :fn_from_other_package, from: :some_other_package")
    end
  end

  it "doesn't add link if already added" do
    with_server(source) do |server, uri|
      index_fn(server, 'some_other_fn', 'other_package')

      send_completion_request(server, uri, { line: 7, character: 5 })
      
      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('some_other_fn')
      expect(result.response.first.additional_text_edits).to eq([])
    end
  end
end


