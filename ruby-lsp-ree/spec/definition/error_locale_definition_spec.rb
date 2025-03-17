# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::DefinitionListener" do
  it "returns correct result for error with locale" do
    source =  <<~RUBY
      class SomeClass
        SomeError = invalid_param_error(:some_error_code, 'some_key.some_key1')

        def something
          raise SomeError
        end
      end
    RUBY

    file_name = 'my_file'
    package_name = 'sample_package'
    file_uri = URI("file://#{sample_package_dir}/package/#{package_name}/#{file_name}.rb")
    
    with_server(source, file_uri) do |server, uri|
      send_definition_request(server, file_uri, { line: 1, character: 47 })
      
      result = server.pop_response
      pp result

      expect(result.response.size).to eq(1)
      pp result.response
    end
  end

  # TODO it "returns correct result for error with code only" do
end
