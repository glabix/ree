class ReeDao::OneToMany
  include Ree::FnDSL

  fn :one_to_many do
    link :demodulize, from: :ree_string
    link :underscore, from: :ree_string
    link :group_by, from: :ree_array
  end

  contract(
    ArrayOf[ -> (v) { v.class.ancestors.include?(ReeDto::EntityDSL) } ],
    Sequel::Dataset,
    Ksplat[
      foreign_key?: Symbol,
      assoc_setter?: Symbol
    ] => nil
  )
  def call(list, assoc_dao, **opts)
    return if list.empty?
    root_ids = list.map(&:id)

    assoc_setter = if opts.key?(:assoc_setter)
      opts[:assoc_setter]
    else
      dto_class = assoc_dao
        .opts[:schema_mapper]
        .strategies
        .detect {_1 .method == :db_load }
        .output
        .dto

      name = underscore(demodulize(dto_class.name))
      "set_#{name}s".to_sym
    end

    foreign_key = if opts.key?(:foreign_key)
      opts[:foreign_key]
    else
      name = underscore(demodulize(list.first.class.name))
      "#{name}_id".to_sym
    end

    assoc_by_group = group_by(assoc_dao.where(foreign_key => root_ids).all) { _1.send(foreign_key) }

    list.each do |item|
      item.send(assoc_setter, assoc_by_group[item.id] || [])
    end

    nil
  end
end