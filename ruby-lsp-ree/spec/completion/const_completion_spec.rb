# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  def stub_parse_document(uri, source)
    allow(Prism).to receive(:parse_file).with(uri.path).and_return(Prism.parse(source))
  end

  it "places already imported constants first" do
    source =  <<~RUBY
      class SomeFn
        fn :some_fn do
          link :some_package_fn, from: :some_package, import: -> { User }
        end

        def something
          Use
        end
      end
    RUBY

    file_uri1 = URI("file:///some_package/package/some_package/some_package_fn.rb")
    file_uri2 = URI("file:///other_package/package/other_package/other_package_fn.rb")

    with_server(source) do |server, uri|
      index_class(server, 'User', file_uri2)
      index_class(server, 'User', file_uri1)

      send_completion_request(server, uri, { line: 6, character: 7 })

      result = server.pop_response

      expect(result.response.size).to eq(2)
      expect(result.response[0].label).to eq('User')
      expect(result.response[0].label_details.description).to eq('imported from: :some_package')
      expect(result.response[1].label).to eq('User')
      expect(result.response[1].label_details.description).to eq('from: :other_package')
    end
  end

  it "adds link to filename" do
    source =  <<~RUBY
      class SomeFn
        fn :some_fn

        def something
          Use
        end
      end
    RUBY

    some_package_fn_source = <<~RUBY
      class SomePackage::SomePackageFn
        class User; end
      end
    RUBY

    file_uri1 = URI("file:///some_package/package/some_package/some_package_fn.rb")
    stub_parse_document(file_uri1, some_package_fn_source)

    with_server(source) do |server, uri|
      index_class(server, 'User', file_uri1)

      send_completion_request(server, uri, { line: 4, character: 7 })

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response[0].additional_text_edits.first.new_text).to match('link "some_package/some_package_fn", -> { User }')
    end
  end

  it "adds link to ree object" do
    source = <<~RUBY
      class SomeFn
        fn :some_fn

        def something
          Use
        end
      end
    RUBY

    some_package_fn_source = <<~RUBY
      class SomePackage::SomePackageFn
        bean :some_package_fn

        class User; end
      end
    RUBY

    current_uri = URI("file:///some_package/package/some_package/some_fn.rb")
    file_uri1 = URI("file:///some_package/package/some_package/some_package_fn.rb")
    stub_parse_document(file_uri1, some_package_fn_source)

    with_server(source, current_uri) do |server, uri|
      index_class(server, 'User', file_uri1)
      index_fn(server, 'some_package_fn', 'some_package', file_uri1)

      send_completion_request(server, uri, { line: 4, character: 7 })

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response[0].additional_text_edits.first.new_text).to match('link :some_package_fn, import: -> { User }')
    end
  end

  it "adds link to ree object with from section" do
    source = <<~RUBY
      class SomeFn
        fn :some_fn

        def something
          Use
        end
      end
    RUBY

    some_package_fn_source = <<~RUBY
      class SomeOtherPackage::SomePackageFn
        bean :some_package_fn

        class User; end
      end
    RUBY

    current_uri = URI("file:///some_package/package/some_package/some_fn.rb")
    file_uri1 = URI("file:///some_other_package/package/some_other_package/some_package_fn.rb")
    stub_parse_document(file_uri1, some_package_fn_source)

    with_server(source, current_uri) do |server, uri|
      index_class(server, 'User', file_uri1)
      index_fn(server, 'some_package_fn', 'some_other_package', file_uri1)

      send_completion_request(server, uri, { line: 4, character: 7 })

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response[0].additional_text_edits.first.new_text).to match('link :some_package_fn, from: :some_other_package, import: -> { User }')
    end
  end

  it "adds import section to already linked ree object" do
    source = <<~RUBY
      class SomeFn
        fn :some_fn do
          link :some_package_fn, from: :some_other_package
        end

        def something
          Use
        end
      end
    RUBY

    some_package_fn_source = <<~RUBY
      class SomeOtherPackage::SomePackageFn
        bean :some_package_fn

        class User; end
      end
    RUBY

    current_uri = URI("file:///some_package/package/some_package/some_fn.rb")
    file_uri1 = URI("file:///some_other_package/package/some_other_package/some_package_fn.rb")
    stub_parse_document(file_uri1, some_package_fn_source)

    with_server(source, current_uri) do |server, uri|
      index_class(server, 'User', file_uri1)
      index_fn(server, 'some_package_fn', 'some_other_package', file_uri1)

      send_completion_request(server, uri, { line: 6, character: 7 })

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response[0].additional_text_edits.first.new_text).to eq(', import: -> { User }')
    end
  end

  it "adds const to existing import section for ree object" do
    source = <<~RUBY
      class SomeFn
        fn :some_fn do
          link :some_package_fn, from: :some_other_package, import: -> { User1 }
        end

        def something
          Use
        end
      end
    RUBY

    some_package_fn_source = <<~RUBY
      class SomeOtherPackage::SomePackageFn
        bean :some_package_fn

        class User; end
        class User1; end
      end
    RUBY

    current_uri = URI("file:///some_package/package/some_package/some_fn.rb")
    file_uri1 = URI("file:///some_other_package/package/some_other_package/some_package_fn.rb")
    stub_parse_document(file_uri1, some_package_fn_source)

    with_server(source, current_uri) do |server, uri|
      index_class(server, 'User', file_uri1)
      index_fn(server, 'some_package_fn', 'some_other_package', file_uri1)

      send_completion_request(server, uri, { line: 6, character: 7 })

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response[0].additional_text_edits.first.new_text).to eq('& User }')
    end
  end
  
  it "adds import section to already linked file path" do
    source = <<~RUBY
      class SomeFn
        fn :some_fn do
          link "some_other_package/some_package_fn"
        end

        def something
          Use
        end
      end
    RUBY

    some_package_fn_source = <<~RUBY
      class SomeOtherPackage::SomePackageFn
        class User; end
      end
    RUBY

    current_uri = URI("file:///some_package/package/some_package/some_fn.rb")
    file_uri1 = URI("file:///some_other_package/package/some_other_package/some_package_fn.rb")
    stub_parse_document(file_uri1, some_package_fn_source)

    with_server(source, current_uri) do |server, uri|
      index_class(server, 'User', file_uri1)
      send_completion_request(server, uri, { line: 6, character: 7 })

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response[0].additional_text_edits.first.new_text).to eq(', -> { User }')
    end
  end

  it "adds const to existing import section for file path" do
    source = <<~RUBY
      class SomeFn
        fn :some_fn do
          link "some_other_package/some_package_fn", -> { User1 }
        end

        def something
          Use
        end
      end
    RUBY

    some_package_fn_source = <<~RUBY
      class SomeOtherPackage::SomePackageFn
        class User; end
        class User1; end
      end
    RUBY

    current_uri = URI("file:///some_package/package/some_package/some_fn.rb")
    file_uri1 = URI("file:///some_other_package/package/some_other_package/some_package_fn.rb")
    stub_parse_document(file_uri1, some_package_fn_source)

    with_server(source, current_uri) do |server, uri|
      index_class(server, 'User', file_uri1)
      send_completion_request(server, uri, { line: 6, character: 7 })

      result = server.pop_response
      expect(result.response.size).to eq(1)
      expect(result.response[0].additional_text_edits.first.new_text).to eq('& User }')
    end
  end
end
