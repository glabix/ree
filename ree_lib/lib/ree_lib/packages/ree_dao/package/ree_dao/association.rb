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
      Ksplat[RestKeys => Any],
      Optblock => Array
    )
    def load(assoc_type, assoc_name, **opts, &block)
      load_association(assoc_type, assoc_name, **opts, &block)
    end

    contract(
      Or[:belongs_to, :has_one, :has_many, :field],
      Symbol,
      Ksplat[RestKeys => Any],
      Optblock => Nilor[Array]
    )
    def load_association(assoc_type, assoc_name, **opts, &block)
      assoc_index = load_association_by_type(
        assoc_type,
        assoc_name,
        **opts
      )

      process_block(assoc_index, opts[:autoload_children] ||= false, &block) if block_given?

      list
    end

    contract(
      Or[:belongs_to, :has_one, :has_many, :field],
      Symbol,
      Ksplat[RestKeys => Any] => Any
    )
    def load_association_by_type(type, assoc_name, **opts)
      case type
      when :belongs_to
        one_to_one(
          assoc_name,
          list,
          scope: opts[:scope],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter],
          reverse: false
        )
      when :has_one
        one_to_one(
          assoc_name,
          list,
          scope: opts[:scope],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter],
          reverse: true
        )
      when :has_many
        one_to_many(
          assoc_name,
          list,
          scope: opts[:scope],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter]
        )
      else
        one_to_many(
          assoc_name,
          list,
          scope: opts[:scope],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter]
        )
      end
    end

    contract(Hash, Bool, Block => Any)
    def process_block(assoc, autoload_children, &block)
      assoc_list = assoc.values.flatten

      if ReeDao::Associations.sync_mode?
        ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          autoload_children,
          **global_opts
        ).instance_exec(&block)
      else
        ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          autoload_children,
          **global_opts
        ).instance_exec(&block).map(&:join)
      end
    end

    contract(
      Symbol,
      Array,      
      Kwargs[
        foreign_key: Nilor[Symbol],
        scope: Nilor[Sequel::Dataset],
        setter: Nilor[Or[Symbol, Proc]],
        reverse: Bool
      ] => Hash
    )
    def one_to_one(
      assoc_name,
      list,
      scope: nil,
      foreign_key: nil,
      setter: nil,
      reverse: true
    )
      return {} if list.empty?

      assoc_dao = find_dao(assoc_name, parent, scope)

      if reverse
        if !foreign_key
          name = underscore(demodulize(list.first.class.name))
          foreign_key = "#{name}_id".to_sym
        end

        root_ids = list.map(&:id).uniq
      else
        if !foreign_key
          dto_class = assoc_dao
            .opts[:schema_mapper]
            .dto(:db_load)
  
          name = underscore(demodulize(dto_class.name))
          
          root_ids = list.map(&:"#{"#{name}_id".to_sym}").uniq
          foreign_key = :id
        else
          root_ids = list.map(&:"#{foreign_key}")
          foreign_key = :id
        end
      end

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = add_scopes(default_scope, scope, global_opts[assoc_name])

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
      Kwargs[
        foreign_key: Nilor[Symbol],
        scope: Nilor[Sequel::Dataset],
        setter: Nilor[Or[Symbol, Proc]]
      ] => Hash
    )
    def one_to_many(
      assoc_name,
      list,
      foreign_key: nil,
      scope: nil,
      setter: nil
    )
      return {} if list.empty?

      assoc_dao = find_dao(assoc_name, parent, scope)

      foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

      root_ids = list.map(&:id)

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = add_scopes(default_scope, scope, global_opts[assoc_name])

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

    contract(Nilor[Sequel::Dataset], Nilor[Sequel::Dataset], Nilor[Proc] => Array)
    def add_scopes(default_scope, scope, named_scope)
      if default_scope && !scope
        res = default_scope
      end

      if default_scope && scope
        if scope == []
          res = default_scope
        else
          res = merge_scopes(default_scope, scope)
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

    def merge_scopes(s1, s2)
      if s2.opts[:where]
        s1 = s1.where(s2.opts[:where])
      end

      if s2.opts[:order]
        s1 = s1.order(*s2.opts[:order])
      end

      s1
    end

    def find_dao(assoc_name, parent, scope)
      dao_from_name = parent.instance_variable_get("@#{assoc_name}") || parent.instance_variable_get("@#{assoc_name}s")
      return dao_from_name if dao_from_name

      raise ArgumentError, "can't find DAO for :#{assoc_name}, provide correct scope or association name" if scope.nil?

      table_name = scope.first_source_table
      dao_from_scope = parent.instance_variable_get("@#{table_name}")
      return dao_from_scope if dao_from_scope

      raise ArgumentError, "can't find DAO for :#{assoc_name}, provide correct scope or association name"
    end
  end
end