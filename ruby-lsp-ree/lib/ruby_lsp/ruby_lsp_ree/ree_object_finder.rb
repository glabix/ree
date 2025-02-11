module RubyLsp
  module Ree
    class ReeObjectFinder
      MAX_LIMIT = 100

      REE_OBJECT_STRING = 'ree_object'
      ENUM_TYPE_STRING = 'type: :enum'
      DAO_TYPE_STRING = 'type: :dao'
      BEAN_TYPE_STRING = 'type: :bean'

      def self.search_objects(index, name, limit)
        index.prefix_search(name)
          .take(MAX_LIMIT).map(&:first)
          .select{ _1.comments }
          .select{ _1.comments.to_s.lines.first&.chomp == REE_OBJECT_STRING }
          .take(limit)
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
    end
  end
end