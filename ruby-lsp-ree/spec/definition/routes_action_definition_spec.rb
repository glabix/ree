# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::DefinitionListener" do
  it "returns correct result for action definition request in routes" do
    source =  <<~RUBY
      class SomePackage::SomeRoutes
        include ReeRoutes::DSL

        routes :some_routes do
          opts = {from: :sample_package}

          get "/some_route" do
            action :some_action, **opts
          end
        end
      end
    RUBY

    action_bean_uri = sample_package_file_uri('some_action.rb')

    with_server(source) do |server, uri|
      index_ree_object(server, 'some_action', :action, 'sample_package', action_bean_uri)

      send_definition_request(server, uri, { line: 7, character: 16 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq(action_bean_uri.to_s)
    end
  end
end
