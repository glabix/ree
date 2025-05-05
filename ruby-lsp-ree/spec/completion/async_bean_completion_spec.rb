# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  it "returns correct result for async_bean autocomplete request" do
    source =  <<~RUBY
      class SomeClass
        def something
          second
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_ree_object(server, 'seconds_ago', :async_bean)

      send_completion_request(server, uri, { line: 2, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('seconds_ago')
    end
  end

  it "returns correct result for async_bean method autocomplete request" do
    source = <<~RUBY
      class SomeClass
        fn :someclass do 
          link :my_async_bean
        end

        def something
          my_async_bean.cre
        end
      end
    RUBY

    bean_source = <<~RUBY
      class SamplePackage::MyAsyncBean
        async_bean :my_async_bean

        def create(a)
          "do something"
        end
      end
    RUBY

    allow(RubyLsp::Ree::ParsedDocumentBuilder).to receive(:build_from_uri).and_return(RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(bean_source, type: :bean))

    with_server(source) do |server, uri|
      index_ree_object(server, 'my_async_bean', :async_bean, 'sample_package', URI.parse('my_async_bean.rb'))

      send_completion_request(server, uri, { line: 6, character: 20 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('create')
    end
  end

  it "doesn't return params specification if arguments already entered" do
    source = <<~RUBY
      class SomeClass
        fn :someclass do 
          link :my_async_bean
        end

        def something
          my_async_bean.create(b)
        end
      end
    RUBY

    bean_source = <<~RUBY
      class SamplePackage::MyAsyncBean
        async_bean :my_async_bean

        def create(a)
          "do something"
        end
      end
    RUBY

    allow(RubyLsp::Ree::ParsedDocumentBuilder).to receive(:build_from_uri).and_return(RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(bean_source, type: :bean))

    with_server(source) do |server, uri|
      index_ree_object(server, 'my_async_bean', :async_bean, 'sample_package', URI.parse('my_async_bean.rb'))

      send_completion_request(server, uri, { line: 6, character: 20 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('create')
      expect(result.response.first.text_edit.new_text).to eq('create')
      expect(result.response.first.text_edit.range.start.character).to eq(18)
      expect(result.response.first.text_edit.range.end.character).to eq(18 + 'create'.size)
    end
  end
end
