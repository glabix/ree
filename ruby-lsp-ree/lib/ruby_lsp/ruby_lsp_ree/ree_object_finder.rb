module RubyLsp
  module Ree
    class ReeObjectFinder
      MAX_LIMIT = 1000

      REE_OBJECT_STRING = 'ree_object'
      ENUM_TYPE_STRING = 'type: :enum'
      DAO_TYPE_STRING = 'type: :dao'
      BEAN_TYPE_STRING = 'type: :bean'
      MAPPER_TYPE_STRING = 'type: :mapper'

      def self.search_objects(index, name, limit)
        index.prefix_search(name)
          .take(MAX_LIMIT)
          .flatten
          .select{ _1.comments }
          .select{ _1.comments.to_s.lines.first&.chomp == REE_OBJECT_STRING }
          .sort_by{ _1.name.length }
          .take(limit)
      end

      def self.search_class_objects(index, name)
        index
          .instance_variable_get(:@entries)
          .keys
          .select{ _1.split('::').last[0...name.size] == name}
      end

      def self.find_object(index, name)
        objects_by_name = index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.to_s.lines.first&.chomp == REE_OBJECT_STRING }
      end

      def self.find_objects_by_types(index, name, types)
        objects_by_name = index[name]
        return [] unless objects_by_name

        objects_by_name.select{ types.include?(object_type(_1)) }
      end

      def self.find_enum(index, name)
        objects_by_name = index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.lines[1]&.chomp == ENUM_TYPE_STRING }
      end

      def self.find_dao(index, name)
        objects_by_name = index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.lines[1]&.chomp == DAO_TYPE_STRING }
      end

      def self.find_bean(index, name)
        objects_by_name = index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.lines[1]&.chomp == BEAN_TYPE_STRING }
      end

      def self.object_type(ree_object)
        case ree_object.comments.lines[1]&.chomp
        when DAO_TYPE_STRING
          :dao
        when BEAN_TYPE_STRING
          :bean
        when ENUM_TYPE_STRING
          :enum
        when MAPPER_TYPE_STRING
          :mapper
        else
          nil
        end
      end
    end
  end
end