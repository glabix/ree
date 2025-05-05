# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::CompletionListener" do
  it "returns correct result for dao autocomplete request" do
    source =  <<~RUBY
      class SomeClass
        def something
          some_d
        end
      end
    RUBY

    with_server(source) do |server, uri|
      index_ree_object(server, 'some_dao', :dao)

      send_completion_request(server, uri, { line: 2, character: 5 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('some_dao')
    end
  end

  it "returns correct result for dao method autocomplete request" do
    source = <<~RUBY
      class SomeClass
        fn :someclass do 
          link :some_dao
        end

        def something
          some_dao.late
        end
      end
    RUBY

    bean_source = <<~RUBY
      class SamplePackage::SomeDao
        dao :some_dao

        filter :later_than, -> (date) { where(Sequel[:created_at] > date) }
      end
    RUBY

    allow(RubyLsp::Ree::ParsedDocumentBuilder).to receive(:build_from_uri).and_return(RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(bean_source, type: :dao))

    with_server(source) do |server, uri|
      index_ree_object(server, 'some_dao', :dao, 'sample_package', URI.parse('some_dao.rb'))

      send_completion_request(server, uri, { line: 6, character: 15 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('later_than')
    end
  end

  it "doesn't return params specification if arguments already entered" do
    source = <<~RUBY
      class SomeClass
        fn :someclass do 
          link :some_dao
        end

        def something
          some_dao.later_than(my_date)
        end
      end
    RUBY

    bean_source = <<~RUBY
      class SamplePackage::SomeDao
        dao :some_dao

        filter :later_than, -> (date) { where(Sequel[:created_at] > date) }
      end
    RUBY

    allow(RubyLsp::Ree::ParsedDocumentBuilder).to receive(:build_from_uri).and_return(RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(bean_source, type: :dao))

    with_server(source) do |server, uri|
      index_ree_object(server, 'some_dao', :dao, 'sample_package', URI.parse('some_dao.rb'))

      send_completion_request(server, uri, { line: 6, character: 20 })
      
      result = server.pop_response

      expect(result.response.size).to eq(1)
      expect(result.response.first.label).to eq('later_than')
      expect(result.response.first.text_edit.new_text).to eq('later_than')
      expect(result.response.first.text_edit.range.start.character).to eq(13)
      expect(result.response.first.text_edit.range.end.character).to eq(13 + 'later_than'.size)
    end
  end
end
