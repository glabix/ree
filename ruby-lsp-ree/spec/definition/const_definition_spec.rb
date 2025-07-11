# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::DefinitionListener" do
  let(:entity_file_name){ sample_package_entities_dir + '/user.rb' }
  
  it "returns correct result for const definition request" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :some_package_fn, from: :some_package, import: -> { User }
        end

        def something
          User
        end
      end
    RUBY

    file_uri = URI("file:///some_package/package/some_package/some_package_fn.rb")

    with_server(source) do |server, uri|
      index_fn(server, 'some_package_fn', 'some_package')
      index_class(server, 'User', file_uri)

      send_definition_request(server, uri, { line: 6, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq(file_uri.to_s)
    end
  end

  it "returns only exact class matches" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          import -> { UserAvatar }, from: :some_package
          import -> { User }, from: :some_package
        end

        def something
          User
        end
      end
    RUBY

    file_uri1 = URI("file:///some_package/package/some_package/some_package_fn1.rb")
    file_uri2 = URI("file:///some_package/package/some_package/some_package_fn2.rb")

    with_server(source) do |server, uri|
      index_class(server, 'UserAvatar', file_uri2)
      index_class(server, 'User', file_uri1)

      send_definition_request(server, uri, { line: 7, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq(file_uri1.to_s)
    end
  end
end
