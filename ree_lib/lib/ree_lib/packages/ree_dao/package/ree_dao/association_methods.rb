module ReeDao
  module AssociationMethods
    def self.included(base)
      base.include(InstanceMethods)
    end

    def self.extended(base)
      base.include(Instance)
    end

    module InstanceMethods
      def find_dao(assoc_name, parent_caller, scope = nil)
        dao_from_name = parent_caller.instance_variable_get("@#{assoc_name}") || parent_caller.instance_variable_get("@#{assoc_name}s")
        return dao_from_name if dao_from_name
  
        raise ArgumentError, "can't find DAO for :#{assoc_name}, provide correct scope or association name" if scope.nil?
        return nil if scope.is_a?(Array)
  
        table_name = scope.first_source_table
        dao_from_scope = parent_caller.instance_variable_get("@#{table_name}")
        return dao_from_scope if dao_from_scope
  
        raise ArgumentError, "can't find DAO for :#{assoc_name}, provide correct scope or association name"
      end
    
      def dao_in_transaction?(dao)
        return false if dao.nil?
    
        dao.db.in_transaction?
      end
    end
  end
end