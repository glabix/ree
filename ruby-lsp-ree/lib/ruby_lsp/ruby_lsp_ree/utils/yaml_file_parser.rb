require 'psych'

class PsychScalarHandler < Psych::TreeBuilder #Psych::Handler
  def parser=(parser)
    @parser=parser
  end

  def mark
    @parser.mark
  end

  def scalar(value, anchor, tag, plain, quoted, style)
    # pp value, anchor, tag, plain, quoted, style, mark
    OpenStruct.new(value: value, line: mark.line, column: mark.column)
    super
  end
end

class Psych::Visitors::ToRuby 
  def visit_Psych_Nodes_Scalar o
    register o, OpenStruct.new(value: deserialize(o), line: o.start_line, column: o.start_column)
  end
end

module RubyLsp
  module Ree
    refine Psych::Nodes::Scalar do
      attr_reader :line_number

      def self.create_with_line_number(line_number, *args)
        node = new(*args)
        node.line_number = line_number
        node
      end
    end

    class YamlFileParser
      def self.parse(file_path)
        scalar_handler = PsychScalarHandler.new
        parser = Psych::Parser.new(scalar_handler)
        scalar_handler.parser = parser

        parser.parse(File.read(file_path))

        result = Psych::Visitors::ToRuby.create.accept(parser.handler.root)
        pp normalize_hash_keys(result)
      end

      def self.normalize_hash_keys(res)
        _deep_transform_keys_in_object!(res){ |k| k.value }
      end

      def self._deep_transform_keys_in_object!(object, &block)
        case object
        when Hash
          object.keys.each do |key|
            value = object.delete(key)
            object[yield(key)] = _deep_transform_keys_in_object!(value, &block)
          end
          object
        when Array
          object.map! { |e| _deep_transform_keys_in_object!(e, &block) }
        else
          object
        end
      end
    end
  end
end