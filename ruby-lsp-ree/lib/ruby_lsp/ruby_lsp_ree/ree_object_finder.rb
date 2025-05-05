require 'delegate'
require_relative "utils/ree_lsp_utils"

module RubyLsp
  module Ree
    class ReeObjectFinder
      include RubyLsp::Ree::ReeLspUtils

      MAX_LIMIT = 1000

      REE_OBJECT_STRING = 'ree_object'

      class ReeObjectDecorator < SimpleDelegator
        include RubyLsp::Ree::ReeLspUtils

        def object_package
          return @package_name if @package_name

          package_name_from_uri(uri)
        end

        def set_package!(package_name)
          @package_name = package_name
        end
      end

      def initialize(index)
        @index = index
      end

      def search_objects(name, limit)
        @index.prefix_search(name)
          .take(MAX_LIMIT)
          .flatten
          .select{ _1.comments }
          .select{ _1.comments.to_s.lines.first&.chomp == REE_OBJECT_STRING }
          .sort_by{ _1.name.length }
          .take(limit)
      end

      def search_class_objects(name)
        @index
          .names
          .select{ _1.split('::').last[0...name.size] == name}
      end

      def search_classes(name)
        keys = search_class_objects(name)
        @index.instance_variable_get(:@entries).values_at(*keys)
      end

      def find_object(name)
        objects_by_name = @index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.to_s.lines.first&.chomp == REE_OBJECT_STRING }
      end

      def find_objects(name)
        objects_by_name = @index[name]
        return [] unless objects_by_name

        ree_objects = objects_by_name.select{ _1.comments.to_s.lines.first&.chomp == REE_OBJECT_STRING }
        decorate_objects(ree_objects)
      end

      def find_object_for_package(name, package_name)
        objects_by_name = @index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.to_s.lines.first&.chomp == REE_OBJECT_STRING && package_name_from_uri(_1.uri) == package_name }
      end

      def find_objects_by_types(name, types)
        objects_by_name = @index[name]
        return [] unless objects_by_name

        objects_by_name.select{ types.include?(object_type(_1)) }
      end

      def object_type(ree_object)
        type_str = ree_object.comments.lines[1]&.chomp
        return unless type_str
          
        type_str.split(' ').last[1..-1].to_sym
      end

      def object_documentation(ree_object)
        ree_object.comments.lines[2..-1].join("\n").chomp
      end

      private 
      
      def decorate_objects(ree_objects)
        ree_objects.map{ ReeObjectDecorator.new(_1) }
      end
    end
  end
end