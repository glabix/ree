# frozen_string_literal: true

class ReeDao::LoadAgg
  include Ree::FnDSL

  fn :load_agg do
    link "ree_dao/associations", -> { Associations }
    link "ree_dao/contract/dao_dataset_contract", -> { DaoDatasetContract }
    link "ree_dao/contract/entity_contract", -> { EntityContract }
  end

  contract(
    Or[Sequel::Dataset, ArrayOf[Integer], ArrayOf[EntityContract], Integer],
    Nilor[DaoDatasetContract],
    Ksplat[
      only?: ArrayOf[Symbol],
      except?: ArrayOf[Symbol],
      RestKeys => Any
    ],
    Optblock => ArrayOf[Any]
  )
  def call(ids_or_scope, dao = nil, **opts, &block)
    scope = if ids_or_scope.is_a?(Array) && ids_or_scope.any? { _1.is_a?(Integer) }
      raise ArgumentError.new("Dao should be provided") if dao.nil?
      return [] if ids_or_scope.empty?

      dao.where(id: ids_or_scope)
    elsif ids_or_scope.is_a?(Integer)
      raise ArgumentError.new("Dao should be provided") if dao.nil?

      dao.where(id: ids_or_scope)
    else
      ids_or_scope
    end

    list = scope.is_a?(Sequel::Dataset) ? scope.all : scope

    load_associations(list, **opts, &block) if block_given?

    if ids_or_scope.is_a?(Array)
      list.sort_by { ids_or_scope.index(_1.id) }
    else
      list
    end
  end

  private

  def load_associations(list, **opts, &block)
    dao = block.binding.eval(<<-CODE, __FILE__, __LINE__ + 1)
      vars = self.instance_variables
      vars
        .filter { |v| self.instance_variable_get(v).class.ancestors.include?(ReeDao::DatasetExtensions::InstanceMethods) }
        .reduce({}) { |hsh, var| hsh[var] = self.instance_variable_get(var); hsh }
    CODE

    if ReeDao.load_sync_associations_enabled?
      Associations.new(list, dao, **opts).instance_exec(&block)
    else
      Associations.new(list, dao, **opts).instance_exec(&block).map(&:join)
    end
  end
end