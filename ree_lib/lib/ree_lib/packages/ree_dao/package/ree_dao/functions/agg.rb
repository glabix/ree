# frozen_string_literal: true

class ReeDao::Agg
  include Ree::FnDSL

  fn :agg do
    link "ree_dao/associations", -> { Associations }
    link "ree_dao/contract/dao_dataset_contract", -> { DaoDatasetContract }
    link "ree_dao/contract/entity_contract", -> { EntityContract }
  end

  contract(
    DaoDatasetContract,
    Or[Sequel::Dataset, ArrayOf[Integer], ArrayOf[EntityContract], Integer],
    Ksplat[
      only?: ArrayOf[Symbol],
      except?: ArrayOf[Symbol],
      to_dto?: Proc,
      RestKeys => Any
    ],
    Optblock => ArrayOf[Any]
  )
  def call(dao, ids_or_scope, **opts, &block)
    scope = if ids_or_scope.is_a?(Array) && ids_or_scope.any? { _1.is_a?(Integer) }
      return [] if ids_or_scope.empty?
      dao.where(id: ids_or_scope)
    elsif ids_or_scope.is_a?(Integer)
      dao.where(id: ids_or_scope)
    else
      ids_or_scope
    end

    list = scope.is_a?(Sequel::Dataset) ? scope.all : scope

    if opts[:to_dto]
      list = list.map do |item|
        list = opts[:to_dto].call(item)
      end
    end

    load_associations(dao.unfiltered, list, **opts, &block) if block_given?

    if ids_or_scope.is_a?(Array)
      list.sort_by { ids_or_scope.index(_1.id) }
    else
      list
    end
  end

  private

  def load_associations(dao, list, **opts, &block)
    return if list.empty?

    local_vars = block.binding.eval(<<-CODE, __FILE__, __LINE__ + 1)
      vars = self.instance_variables
      vars.reduce({}) { |hsh, var| hsh[var] = self.instance_variable_get(var); hsh }
    CODE

    agg_caller = block.binding.eval("self")

    associations = Associations.new(agg_caller, list, local_vars, dao, **opts).instance_exec(list, &block)

    if dao.db.in_transaction? || ReeDao.load_sync_associations_enabled?
      associations
    else
      associations[:association_threads].map do |association, assoc_type, assoc_name, opts, block|
        Thread.new do
          association.load(assoc_type, assoc_name, **opts, &block)
        end
      end.map(&:join)

      associations[:field_threads].map do |association, field_proc|
        Thread.new do
          association.handle_field(field_proc)
        end
      end.map(&:join)
    end
  end
end