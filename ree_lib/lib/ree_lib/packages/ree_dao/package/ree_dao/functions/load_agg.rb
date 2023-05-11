# frozen_string_literal: true

class ReeDao::LoadAgg
  include Ree::FnDSL

  fn :load_agg do
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
      block.call.reduce(&:merge)
    else
      threads = block.call
  
      threads.map do |t|
        t.join
        t.value
      end.reduce(&:merge)
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
      end
    end
  end

  def get_setter_name(attribute)
    "set_#{attribute}"
  end
end