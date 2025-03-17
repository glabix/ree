require 'psych'

# TODO try to use refinement
class Psych::Visitors::ToRuby
  def visit_Psych_Nodes_Scalar(o)
    register(o, OpenStruct.new(value: deserialize(o), line: o.start_line, column: o.start_column))
  end
end

module RubyLsp
  module Ree
    class YamlFileParser
      def self.parse(file_path)
        parser = Psych::Parser.new(Psych::TreeBuilder.new)
        parser.parse(File.read(file_path))

        parse_result = Psych::Visitors::ToRuby.create.accept(parser.handler.root)
        normalize_hash_keys(parse_result.first)
      end

      def self.normalize_hash_keys(res)
        deep_transform_keys_in_object!(res){ |k| k.value }
      end

      def self.deep_transform_keys_in_object!(object, &block)
        case object
        when Hash
          object.keys.each do |key|
            value = object.delete(key)
            object[yield(key)] = deep_transform_keys_in_object!(value, &block)
          end
          object
        when Array
          object.map! { |e| deep_transform_keys_in_object!(e, &block) }
        else
          object
        end
      end
    end
  end
end