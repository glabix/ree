class ReeDao::OneToOne
  include Ree::FnDSL

  fn :one_to_one do
    link :demodulize, from: :ree_string
    link :underscore, from: :ree_string
    link :index_by, from: :ree_array
  end

  contract(
    ArrayOf[ -> (v) { v.class.ancestors.include?(ReeDto::EntityDSL) } ],
    Sequel::Dataset,
    Ksplat[
      reverse?: Bool,
      foreign_key?: Symbol,
      assoc_setter?: Symbol
    ] => nil
  )
  def call(list, assoc_dao, **opts)
    return if list.empty?

    dto_class = assoc_dao
      .opts[:schema_mapper]
      .strategies
      .detect {_1 .method == :db_load }
      .output
      .dto

    assoc_name = underscore(demodulize(dto_class.name))
    reverse = opts[:reverse]

    assoc_setter = if opts.key?(:assoc_setter)
      opts[:assoc_setter]
    else
      "set_#{assoc_name}"
    end

    foreign_key = if opts.key?(:foreign_key)
      opts[:foreign_key]
    else
      if reverse
        name = underscore(demodulize(list.first.class.name))
        "#{name}_id".to_sym
      else
        :id
      end
    end

    root_ids = if reverse
      list.map(&:id)
    else
      list.map(&:"#{foreign_key}")
    end

    assoc_by_fk = index_by(assoc_dao.where(foreign_key => root_ids).all) { _1.send(foreign_key) }

    list.each do |item|
      item.send(assoc_setter, assoc_by_fk[item.id])
    end

    nil
  end
end
