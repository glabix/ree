class ReeDao::PersistAssoc
  include Ree::FnDSL

  fn :persist_assoc do
    link :demodulize, from: :ree_string
    link :underscore, from: :ree_string
  end

  contract(
    -> (v) {
      v.class.ancestors.include?(ReeDto::EntityDSL)
    },
    Sequel::Dataset,
    Ksplat[
      root_setter?: Symbol,
      child_assoc?: Symbol,
    ] => nil
  )
  def call(agg_root, assoc_dao, **opts)
    setter_method = if opts[:root_setter].nil?
      name = underscore(demodulize(agg_root.class.name))
      "#{name}_id="
    else
      "#{opts[:root_setter]}"
    end

    assoc_name = if opts[:child_assoc].nil?
      dto_class = assoc_dao
        .opts[:schema_mapper]
        .strategies
        .detect {_1 .method == :db_load }
        .output
        .dto

      name = underscore(demodulize(dto_class.name))
      "#{name}s"
    else
      opts[:child_assoc]
    end

    agg_root.send(assoc_name).each do |child|
      if !child.respond_to?(setter_method)
        raise ArgumentError.new("#{child.class} does not respond to `#{setter_method}` method")
      end

      child.send(setter_method, agg_root.id)

      if child.id
        assoc_dao.update(child)
      else
        assoc_dao.put(child)
      end
    end

    nil
  end
end