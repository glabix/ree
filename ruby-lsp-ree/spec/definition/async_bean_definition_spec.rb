# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::DefinitionListener" do
  it "returns correct result for async bean definition request" do
    source =  <<~RUBY
      class SomeClass
        link :seconds_ago

        def something
          my_async_bean
        end
      end
    RUBY

    async_bean_uri = sample_package_file_uri('my_async_bean.rb')

    with_server(source) do |server, uri|
      index_ree_object(server, 'my_async_bean', :async_bean, 'sample_package', async_bean_uri)

      send_definition_request(server, uri, { line: 4, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq(async_bean_uri.to_s)
    end
  end
end
