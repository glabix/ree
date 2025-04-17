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
      index_fn(server, 'seconds_ago')

      send_completion_request(server, uri, { line: 2, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('seconds_ago')
    end
  end

  it "returns correct result for class includeing link dsl" do
    source =  <<~RUBY
      class SomeClass
        include Ree::LinkDSL
        include Enumerable

        def something
          second
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn(server, 'seconds_ago')

      send_completion_request(server, uri, { line: 5, character: 5 })
      
      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('seconds_ago')
      expect(result.response.first.additional_text_edits.first.new_text).to match('link :seconds_ago')
    end
  end

  it "doesn't return params specification if arguments already entered" do
    source =  <<~RUBY
      class SomeClass
        def something
          func_with_three_args(some_obj.some_field, some_obj.id, third_arg)
        end
      end
    RUBY

    fn_source =  <<~RUBY
      def func_with_three_args(string_field, id, third_arg)
        puts id
      end
    RUBY

    with_server(source) do |server, uri|
      index_fn_from_source(server, fn_source)

      send_completion_request(server, uri, { line: 2, character: 8 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('func_with_three_args')
      expect(result.response.first.text_edit.new_text).to eq('func_with_three_args')
      expect(result.response.first.text_edit.range.start.character).to eq(4)
      expect(result.response.first.text_edit.range.end.character).to eq(4 + 'func_with_three_args'.size)
    end

  end
end
