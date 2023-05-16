# frozen_string_literal: true

class ReeDao::LoadAgg
  include Ree::FnDSL

  fn :load_agg do
    link :merge, from: :ree_hash
  end

  contract(
    Or[Sequel::Dataset, ArrayOf[Integer], Integer],
    Sequel::Dataset, # TODO: change to dao class
    Ksplat[RestKeys => Any],
    Optblock => Any # Project from schema
  )
  def call(ids_or_scope, dao, **opts, &block)
    scope = if ids_or_scope.is_a?(Array)
      return [] if ids_or_scope.empty?

      dao.where(id: ids_or_scope)
    elsif ids_or_scope.is_a?(Integer)
      dao.where(id: ids_or_scope)
    else
      ids_or_scope
    end

    list = scope.all

    associations = if block_given?
      load_associations(list, opts, &block)
    end
    
    populate_associations(list, associations)

    if ids_or_scope.is_a?(Array)
      list.sort_by { ids_or_scope.index(_1.id) }
    else
      list
    end
  end

  private

  def load_associations(list, opts, &block)
    dto_class = list.first.class
    block.binding.eval("@nested_list_store = {}")
    block.binding.eval("@nested_list_store[0] = {}")
    block.binding.eval("@nested_list_store[0][:dto_class] = #{dto_class}")
    block.binding.eval("@nested_list_store[0][:list] = #{list.map(&:to_h)}")
    block.binding.eval("@current_level = 0")

    if ReeDao.load_sync_associations_enabled?
      block.call.reduce { |a,b| merge(a, b, deep: true) }
    else
      block.call.map(&:value).reduce { |a,b| merge(a, b, deep: true) }
    end
  end

  def populate_associations(list, associations)
    return if !associations

    attrs = associations.keys
    list.each do |item|
      attrs.each do |attr|
        setter = get_setter_name(attr)
        value = associations[attr][item.id]
        item.send(setter, value)
        # check if we have nested associations in hash
        if associations[attr].keys.any? { _1.is_a?(Symbol) }
          nested_keys = associations[attr].keys.select { _1.is_a?(Symbol) }
          if value.is_a?(Array)
            value.each do |v|
              set_nested_associations(nested_keys, associations[attr], v)
            end
          else
            set_nested_associations(nested_keys, associations[attr], value)
          end
        end
      end
    end
  end

  def get_setter_name(attribute)
    "set_#{attribute}"
  end

  def set_nested_associations(keys, assocs, item)
    return unless item

    keys.each do |attr|
      setter = get_setter_name(attr)
      value = assocs[attr][item.id]
      item.send(setter, value)

      if assocs[attr].keys.any? { _1.is_a?(Symbol) }
        nested_keys = assocs[attr].keys.select { _1.is_a?(Symbol) }
        if value.is_a?(Array)
          value.each do |v|
            set_nested_associations(nested_keys, assocs[attr], v)
          end
        else
          set_nested_associations(nested_keys, assocs[attr], value)
        end
      end
    end
  end
end