# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::DefinitionListener" do
  it "returns correct result for link name" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :seconds_ago, from: :package1
        end

        def something
          seconds_ago
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago', 'package1')

      send_definition_request(server, uri, { line: 2, character: 13 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq('file:///package1/package/package1/seconds_ago.rb')
    end
  end

  it "returns correct result for alias" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :seconds_ago, as: :do_something, from: :package1
        end

        def something
          do_something
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago', 'package1')

      send_definition_request(server, uri, { line: 2, character: 34 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq('file:///package1/package/package1/seconds_ago.rb')
    end
  end

  it "returns correct result for multi-object link" do
     source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :seconds_ago, :seconds_ago1, from: :package1
        end

        def something
          seconds_ago1
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago', 'package1')
      index_fn(server, 'seconds_ago1', 'package1')

      send_definition_request(server, uri, { line: 2, character: 34 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.uri).to eq('file:///package1/package/package1/seconds_ago1.rb')
    end
  end

  # TODO it "returns correct result for const in import link" do
end
