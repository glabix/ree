# frozen_string_literal: true

class ReeDao::LoadAgg
  include Ree::FnDSL

  fn :load_agg do
    link :merge, from: :ree_hash
    link "ree_dao/associations", -> { Associations }
  end

  contract(
    Or[Sequel::Dataset, ArrayOf[Integer], Integer],
    Nilor[-> (v) { v.class.ancestors.include?(ReeDao::DatasetExtensions::InstanceMethods) }],
    Ksplat[RestKeys => Any],
    Optblock => ArrayOf[Any]
  )
  def call(ids_or_scope, dao = nil, **opts, &block)
    scope = if ids_or_scope.is_a?(Array)
      raise ArgumentError.new("Dao should be provided") if dao.nil?
      return [] if ids_or_scope.empty?

      dao.where(id: ids_or_scope)
    elsif ids_or_scope.is_a?(Integer)
      raise ArgumentError.new("Dao should be provided") if dao.nil?

      dao.where(id: ids_or_scope)
    else
      ids_or_scope
    end

    list = scope.all

    if block_given?
      associations = load_associations(list, opts, &block)
      list = populate_associations(list, associations)
    end
    
    if ids_or_scope.is_a?(Array)
      list.sort_by { ids_or_scope.index(_1.id) }
    else
      list
    end
  end

  private

  def load_associations(list, opts, &block)
    dao = block.binding.eval(<<-CODE, __FILE__, __LINE__ + 1)
      vars = self.instance_variables
      vars
        .filter { |v| self.instance_variable_get(v).class.ancestors.include?(ReeDao::DatasetExtensions::InstanceMethods) }
        .reduce({}) { |hsh, var| hsh[var] = self.instance_variable_get(var); hsh }
    CODE

    if ReeDao.load_sync_associations_enabled?
      Associations.new(list, dao).instance_exec(&block)
      # block.call.reduce { |a,b| merge(a, b, deep: true) }
    else
      thr = block.call.map(&:value)
      thr.reduce { |a,b| merge(a, b, deep: true) }
    end
  end

  def populate_associations(list, associations)
    return if !associations

    attrs = associations.keys
    list.each do |item|
      attrs.each do |attr_name|
        setter = get_setter_name(attr_name)
        value = associations[attr_name][item.id]
        item.send(setter, value)
      end
    end

    list
    # list.each do |item|
    #   if ReeDao.load_sync_associations_enabled?
    #     attrs.each do |attr|
    #       setter = get_setter_name(attr)
    #       value = associations[attr][item.id]
    #       item.send(setter, value)
    #       # check if we have nested associations in hash
    #       if associations[attr].keys.any? { _1.is_a?(Symbol) }
    #         nested_keys = associations[attr].keys.select { _1.is_a?(Symbol) }
    #         if value.is_a?(Array)
    #           value.each do |v|
    #             set_nested_associations(nested_keys, associations[attr], v)
    #           end
    #         else
    #           set_nested_associations(nested_keys, associations[attr], value)
    #         end
    #       end
    #     end
    #   else
    #     threads = []
    #     attrs.each do |attr|
    #       threads << Thread.new do
    #         setter = get_setter_name(attr)
    #         value = associations[attr][item.id]
    #         item.send(setter, value)
    #         # check if we have nested associations in hash
    #         if associations[attr].keys.any? { _1.is_a?(Symbol) }
    #           nested_keys = associations[attr].keys.select { _1.is_a?(Symbol) }
    #           if value.is_a?(Array)
    #             value.each do |v|
    #               set_nested_associations(nested_keys, associations[attr], v)
    #             end
    #           else
    #             set_nested_associations(nested_keys, associations[attr], value)
    #           end
    #         end
    #       end
    #     end

    #     threads.map(&:join)
    #   end
    # end
  end

  def get_setter_name(attribute)
    "set_#{attribute}"
  end
end