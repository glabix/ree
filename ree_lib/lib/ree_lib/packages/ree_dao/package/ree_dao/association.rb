module ReeDao
  class Association
    include Ree::LinkDSL

    link :demodulize, from: :ree_string
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :underscore, from: :ree_string

    attr_reader :parent, :list, :global_opts

    contract(ReeDao::Associations, Array, Ksplat[RestKeys => Any] => Any)
    def initialize(parent, list, **global_opts)
      @parent = parent
      @list = list
      @global_opts = global_opts
    end

    contract(
      Or[:belongs_to, :has_one, :has_many, :field],
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[RestKeys => Any],
      Optblock => Array
    )
    def load(assoc_type, assoc_name, scope, **opts, &block)
      load_association(assoc_type, assoc_name, scope, **opts, &block)
    end

    contract(
      Or[:belongs_to, :has_one, :has_many, :field],
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[RestKeys => Any],
      Optblock => Array
    )
    def load_association(assoc_type, assoc_name, scope, **opts, &block)
      assoc_index = load_association_by_type(
        assoc_type,
        assoc_name,
        scope,
        **opts
      )

      process_block(assoc_index, &block) if block_given?

      list
    end

    contract(
      Or[:belongs_to, :has_one, :has_many, :field],
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[RestKeys => Any] => Any
    )
    def load_association_by_type(type, assoc_name, scope, **opts)
      case type
      when :belongs_to
        one_to_one(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          setter: opts[:setter],
          reverse: false
        )
      when :has_one
        one_to_one(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          setter: opts[:setter],
          reverse: true
        )
      when :has_many
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          setter: opts[:setter]
        )
      else
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          setter: opts[:setter]
        )
      end
    end

    contract(Hash, Block => Any)
    def process_block(assoc, &block)
      assoc_list = assoc.values.flatten

      if ReeDao::Associations.sync_mode?
        ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          **global_opts
        ).instance_exec(&block)
      else
        ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          **global_opts
        ).instance_exec(&block).map(&:join)
      end
    end

    contract(
      Symbol,
      Array,
      Nilor[Sequel::Dataset],
      Kwargs[
        foreign_key: Nilor[Symbol],
        assoc_dao: Nilor[Sequel::Dataset],
        setter: Nilor[Or[Symbol, Proc]],
        reverse: Bool
      ] => Nilor[Hash]
    )
    def one_to_one(
      assoc_name,
      list,
      scope,
      foreign_key: nil,
      assoc_dao: nil,
      setter: nil,
      reverse: true
    )
      return if list.empty?

      assoc_dao ||= parent.instance_variable_get("@#{assoc_name}s")

      foreign_key ||= if reverse
        name = underscore(demodulize(list.first.class.name))
        "#{name}_id".to_sym
      else
        :id
      end

      root_ids = if reverse
        list.map(&:id).uniq
      else
        dto_class = assoc_dao
          .opts[:schema_mapper]
          .dto(:db_load)

        name = underscore(demodulize(dto_class.name))
        
        list.map(&:"#{"#{name}_id".to_sym}").uniq
      end

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = add_scopes(assoc_name, default_scope, scope, global_opts[assoc_name])

      assoc = index_by(items) { _1.send(foreign_key) }

      populate_association(
        list,
        assoc,
        assoc_name,
        setter: setter,
        reverse: reverse
      )

      assoc
    end

    contract(
      Symbol,
      Array,
      Nilor[Sequel::Dataset],
      Kwargs[
        foreign_key: Nilor[Symbol],
        assoc_dao: Nilor[Sequel::Dataset],
        setter: Nilor[Or[Symbol, Proc]]
      ] => Nilor[Hash]
    )
    def one_to_many(
      assoc_name,
      list,
      scope,
      foreign_key: nil,
      assoc_dao: nil,
      setter: nil
    )
      return if list.empty?

      assoc_dao ||= parent.instance_variable_get("@#{assoc_name}")

      foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

      root_ids = list.map(&:id)

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = add_scopes(assoc_name, default_scope, scope, global_opts[assoc_name])

      assoc = group_by(items) { _1.send(foreign_key) }

      populate_association(
        list,
        assoc,
        assoc_name,
        setter: setter
      )

      assoc
    end

    contract(
      Array,
      Hash,
      Symbol,
      Kwargs[
        reverse: Nilor[Bool],
        setter: Nilor[Or[Symbol, Proc]]
      ] => Any
    )
    def populate_association(
      list,
      association_index,
      assoc_name,
      reverse: nil,
      setter: nil
    )
      assoc_setter = if setter
        setter
      else
        "set_#{assoc_name}"
      end

      list.each do |item|
        if setter && setter.is_a?(Proc)
          self.instance_exec(item, association_index, &assoc_setter)
        else
          key = if reverse.nil?
            :id
          else
            reverse ? :id : "#{assoc_name}_id"
          end
          value = association_index[item.send(key)]
          next if value.nil?

          item.send(assoc_setter, value)
        end
      end
    end

    contract(Symbol, Nilor[Sequel::Dataset], Nilor[Sequel::Dataset], Nilor[Proc] => Array)
    def add_scopes(assoc_name, default_scope, scope, named_scope)
      if default_scope && !scope
        res = default_scope
      end

      if default_scope && scope
        if scope.empty?
          res = default_scope
        else
          scope_ids = scope.select(:id).all.map(&:id)
          res = default_scope.where(id: scope_ids)
        end
      end

      if !default_scope && scope
        return [] if scope.empty?

        res = scope
      end

      if named_scope
        res = named_scope.call(res)
      end

      res.all
    end
  end
end