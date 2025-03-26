# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ParsedMethodNode" do
  def parse_instance_methods(source)
    ast = Prism.parse(source).value
    class_node = ast.statements.body.first

    doc_instance_methods = []
    class_node.body.body.each do |node| 
      if node.is_a?(Prism::DefNode)
        doc_instance_methods << RubyLsp::Ree::ParsedMethodNode.new(node, nil)
      end
    end
    doc_instance_methods
  end

  describe '#parse_nested_local_methods' do
    it "returns correct result with nested methods" do
      source =  <<~RUBY
        class SomPackage::SomeClass
          def call(attrs)
            call_nested_method
          end

          def call_nested_method
            puts "nested method"
          end
        end
      RUBY

      doc_instance_methods = parse_instance_methods(source)
      expect(
        doc_instance_methods[0].parse_nested_local_methods(doc_instance_methods).map(&:name)
      ).to eq([:call_nested_method])
    end

    it "returns correct result for method with rescue" do
      source =  <<~RUBY
        class SomPackage::SomeClass
          def call(attrs)
            call_nested_method
          rescue AnyError
            return true
          end

          def call_nested_method
            puts "nested method"
          end
        end
      RUBY

      doc_instance_methods = parse_instance_methods(source)
      expect(
        doc_instance_methods[0].parse_nested_local_methods(doc_instance_methods).map(&:name)
      ).to eq([:call_nested_method])
    end
  end
end