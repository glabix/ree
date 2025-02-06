module RubyLsp
  module Ree
    class ReeObjectFinder
      ENUM_TYPE_STRING = 'type: :enum'

      def self.find_enum(index, name)
        objects_by_name = index[name]
        return unless objects_by_name

        objects_by_name.detect{ _1.comments.lines[1]&.chomp == ENUM_TYPE_STRING }
      end
    end
  end
end