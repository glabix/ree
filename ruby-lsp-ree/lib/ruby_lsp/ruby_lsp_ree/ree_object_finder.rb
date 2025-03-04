module RubyLsp
  module Ree
    class ReeObjectFinder
      MAX_LIMIT = 1000

      REE_OBJECT_STRING = 'ree_object'
      ENUM_TYPE_STRING = 'type: :enum'
      DAO_TYPE_STRING = 'type: :dao'
      BEAN_TYPE_STRING = 'type: :bean'
      MAPPER_TYPE_STRING = 'type: :mapper'
      AGGREGATE_TYPE_STRING = 'type: :aggregate'

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

      def find_objects_by_types(name, types)
        objects_by_name = @index[name]
        return [] unless objects_by_name

        objects_by_name.select{ types.include?(object_type(_1)) }
      end

      def find_enum(name)
        objects_by_name = @index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.lines[1]&.chomp == ENUM_TYPE_STRING }
      end

      def find_dao(name)
        objects_by_name = @index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.lines[1]&.chomp == DAO_TYPE_STRING }
      end

      def find_bean(index, name)
        objects_by_name = @index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.lines[1]&.chomp == BEAN_TYPE_STRING }
      end

      def object_type(ree_object)
        type_str = ree_object.comments.lines[1]&.chomp
        return unless type_str
          
        type_str.split(' ').last[1..-1].to_sym
      end

      def object_documentation(ree_object)
        ree_object.comments.lines[2..-1].join("\n").chomp
      end
    end
  end
end