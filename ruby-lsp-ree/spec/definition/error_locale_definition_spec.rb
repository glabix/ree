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
      send_definition_request(server, uri, { line: 1, character: 47 })
      
      result = server.pop_response
      expect(result.response.size).to eq(2)
      expect(result.response.first.range.start.line).to eq(2)
    end
  end

  it "returns correct result for error with code only" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        SomeError = invalid_param_error(:some_error_code)

        def something
          raise SomeError
        end
      end
    RUBY

    file_name = 'my_file'
    package_name = 'sample_package'
    file_uri = URI("file://#{sample_package_dir}/package/#{package_name}/#{file_name}.rb")
    
    with_server(source, file_uri) do |server, uri|
      send_definition_request(server, uri, { line: 1, character: 47 })
      
      result = server.pop_response
      expect(result.response.size).to eq(2)
      expect(result.response.first.range.start.line).to eq(10)
    end
  end

  it "returns correct result for error with duplicated locale keys" do
    source =  <<~RUBY
      class SomeClass
        SomeError = invalid_param_error(:some_error_code, 'duplicated_key1.duplicated_key2')

        def something
          raise SomeError
        end
      end
    RUBY

    file_name = 'my_file'
    package_name = 'sample_package'
    file_uri = URI("file://#{sample_package_dir}/package/#{package_name}/#{file_name}.rb")
    
    with_server(source, file_uri) do |server, uri|
      send_definition_request(server, uri, { line: 1, character: 47 })
      
      result = server.pop_response
      expect(result.response.size).to eq(2)
      expect(result.response.first.range.start.line).to eq(7)
    end
  end
end
