module ReeDao
  module AssociationMethods
    def self.included(base)
      base.include(InstanceMethods)
    end

    def self.extended(base)
      base.include(Instance)
    end

    module InstanceMethods
      SUFFIXES = ["", "s", "es", "dao", "s_dao", "es_dao"].freeze

      def find_dao(assoc_name, parent_caller, scope = nil)
        SUFFIXES.each do |suffix|
          dao_from_name = parent_caller.instance_variable_get("@#{assoc_name}#{suffix}")
          return dao_from_name if dao_from_name
        end

        if scope.is_a?(Sequel::Dataset)
          return scope.unfiltered
        end

        raise ArgumentError, "can't find DAO for :#{assoc_name}, provide correct scope or association name"
      end
    end
  end
end