# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::HoverListener" do
  it "returns correct result for error hover request" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class

        SomeError = invalid_param_error(:some_error_code, 'some_key.some_key1')

        def something
          raise SomeError
        end
      end
    RUBY

    with_server(source, sample_file_uri) do |server, uri|
      index_fn(server, 'some_class', 'sample_package', sample_file_uri)

      send_hover_request(server, uri, { line: 3, character: 47 })
      
      result = server.pop_response
      expect(result.response.contents.value).to match('some_value')
    end
  end
end
