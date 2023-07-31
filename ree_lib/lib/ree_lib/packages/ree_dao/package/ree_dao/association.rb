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

    def handle_field(assoc_name, proc)
      proc.call
    end

    contract(
      Or[:belongs_to, :has_one, :has_many],
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
          primary_key: opts[:primary_key],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter],
          reverse: false
        )
      when :has_one
        one_to_one(
          assoc_name,
          list,
          scope: opts[:scope],
          primary_key: opts[:primary_key],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter],
          reverse: true
        )
      when :has_many
        one_to_many(
          assoc_name,
          list,
          scope: opts[:scope],
          primary_key: opts[:primary_key],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter]
        )
      else
        one_to_many(
          assoc_name,
          list,
          scope: opts[:scope],
          primary_key: opts[:primary_key],
          foreign_key: opts[:foreign_key],
          setter: opts[:setter]
        )
      end
    end

    contract(Or[Hash, Array], Bool, Block => Any)
    def process_block(assoc, autoload_children, &block)
      assoc_list = assoc.is_a?(Array) ? assoc : assoc.values.flatten

      if ReeDao::Associations.sync_mode?
        ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          autoload_children,
          **global_opts
        ).instance_exec(assoc_list, &block)
      else
        ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          autoload_children,
          **global_opts
        ).instance_exec(assoc_list, &block)[:association_threads].map(&:join)
      end
    end

    contract(
      Symbol,
      Array,      
      Kwargs[
        primary_key: Nilor[Symbol],
        foreign_key: Nilor[Symbol],
        scope: Nilor[Sequel::Dataset, Array],
        setter: Nilor[Or[Symbol, Proc]],
        reverse: Bool
      ] => Or[Hash, Array]
    )
    def one_to_one(assoc_name, list, scope: nil, primary_key: :id, foreign_key: nil, setter: nil, reverse: true)
      return {} if list.empty?

      primary_key ||= :id

      if scope.is_a?(Array)
        items = scope
      else
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
  
        default_scope = if !scope 
          assoc_dao&.where(foreign_key => root_ids)
        end
  
        items = add_scopes(default_scope, scope, global_opts[assoc_name])
      end

      assoc = if foreign_key
        index_by(items) { _1.send(foreign_key) }
      else
        items
      end 

      populate_association(
        list,
        assoc,
        assoc_name,
        setter: setter,
        reverse: reverse,
        primary_key: primary_key
      )

      assoc
    end

    contract(
      Symbol,
      Array,
      Kwargs[
        foreign_key: Nilor[Symbol],
        primary_key: Nilor[Symbol],
        scope: Nilor[Sequel::Dataset, Array],
        setter: Nilor[Or[Symbol, Proc]]
      ] => Or[Hash, Array]
    )
    def one_to_many(assoc_name, list, primary_key: nil, foreign_key: nil, scope: nil, setter: nil)
      return {} if list.empty?

      primary_key ||= :id

      if scope.is_a?(Array)
        items = scope
      else
        assoc_dao = nil
        assoc_dao = find_dao(assoc_name, parent, scope)
  
        foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym
  
        root_ids = list.map(&:"#{primary_key}")
  
        default_scope = if !scope
          assoc_dao&.where(foreign_key => root_ids)
        end
  
        items = add_scopes(default_scope, scope, global_opts[assoc_name])
      end

      assoc = if foreign_key
        group_by(items) { _1.send(foreign_key) }
      else
        items
      end

      populate_association(
        list,
        assoc,
        assoc_name,
        setter: setter,
        primary_key: primary_key
      )

      assoc
    end

    contract(
      Array,
      Or[Hash, Array],
      Symbol,
      Kwargs[
        primary_key: Nilor[Symbol],
        reverse: Nilor[Bool],
        setter: Nilor[Or[Symbol, Proc]]
      ] => Any
    )
    def populate_association(list, association_index, assoc_name, primary_key: nil, reverse: nil, setter: nil)
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
            primary_key
          else
            reverse ? primary_key : "#{assoc_name}_id"
          end
          value = association_index[item.send(key)]
          next if value.nil?

          begin
            item.send(assoc_setter, value)
          rescue NoMethodError
            item.send("#{assoc_name}=", value)
          end
        end
      end
    end

    contract(Nilor[Sequel::Dataset], Nilor[Sequel::Dataset], Nilor[Proc] => Array)
    def add_scopes(default_scope, scope, named_scope)
      res = scope || default_scope

      if named_scope
        res = named_scope.call(res)
      end

      res.all
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

    def method_missing(method, *args, &block)
      return super if !parent.agg_caller.private_methods(false).include?(method)

      parent.agg_caller.send(method, *args, &block)
    end
  end
end