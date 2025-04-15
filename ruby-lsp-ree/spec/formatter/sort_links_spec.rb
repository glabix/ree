# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}) }

  it "sorts links inside fn" do
    source =  <<~RUBY
      class SomeClass
        fn :some_class do
          link :linked_service_2
          link :linked_service_1
        end

        def call
          linked_service_2
          linked_service_1
        end
      end
    RUBY

    result = subject.run_formatting('', ruby_document(source))
    
    expect(result.lines[2]).to match('linked_service_1')
    expect(result.lines[3]).to match('linked_service_2')
  end
end
