module ReeDao
  class Association
    include Ree::LinkDSL

    link :demodulize, from: :ree_string
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :underscore, from: :ree_string

    attr_reader :parent, :parent_dao_name, :list, :global_opts

    contract(ReeDao::Associations, Symbol, Array, Ksplat[RestKeys => Any] => Any)
    def initialize(parent, parent_dao_name, list, **global_opts)
      @parent = parent
      @parent_dao_name = parent_dao_name
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

    def handle_field(field_proc)
      field_proc.call
    end

    contract(
      Or[:belongs_to, :has_one, :has_many],
      Symbol,
      Ksplat[RestKeys => Any],
      Optblock => Nilor[Array]
    )
    def load_association(assoc_type, assoc_name, **opts, &block)
      opts[:autoload_children] ||= false

      assoc_index = load_association_by_type(
        assoc_type,
        assoc_name,
        **opts
      )

      dao = find_dao(assoc_name, parent, opts[:scope])

      dao_name = if dao
        dao.first_source_table
      elsif opts[:scope].is_a?(Array)
        name = underscore(demodulize(opts[:scope].first.class.name))

        if name.end_with?("s")
          "#{name}es"
        else
          "#{name}s"
        end
      end

      process_block(assoc_index, opts[:autoload_children], opts[:to_dto], dao_name, &block) if block_given?

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
          parent_dao_name,
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
          parent_dao_name,
          assoc_name,
          list,
          scope: opts[:scope],
          primary_key: opts[:primary_key],
          foreign_key: opts[:foreign_key],
          to_dto: opts[:to_dto],
          setter: opts[:setter],
          reverse: true
        )
      when :has_many
        one_to_many(
          parent_dao_name,
          assoc_name,
          list,
          scope: opts[:scope],
          primary_key: opts[:primary_key],
          foreign_key: opts[:foreign_key],
          to_dto: opts[:to_dto],
          setter: opts[:setter]
        )
      end
    end

    contract(Or[Hash, Array], Bool, Nilor[Proc], Symbol, Block => Any)
    def process_block(assoc, autoload_children, to_dto, parent_dao_name, &block)
      assoc_list = assoc.is_a?(Array) ? assoc : assoc.values.flatten

      if to_dto
        assoc_list = assoc_list.map do |item|
          to_dto.call(item)
        end
      end

      if ReeDao::Associations.sync_mode?
        ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          parent_dao_name,
          autoload_children,
          **global_opts
        ).instance_exec(assoc_list, &block)
      else
        threads = ReeDao::Associations.new(
          parent.agg_caller,
          assoc_list,
          parent.local_vars,
          parent_dao_name,
          autoload_children,
          **global_opts
        ).instance_exec(assoc_list, &block)
        threads[:association_threads].map do |association, assoc_type, assoc_name, opts, block|
          Thread.new do
            association.load(assoc_type, assoc_name, **opts, &block)
          end
        end.map(&:join)

        threads[:field_threads].map do |association, field_proc|
          Thread.new do
            association.handle_field(field_proc)
          end
        end.map(&:join)
      end
    end

    contract(
      Symbol,
      Symbol,
      Array,
      Kwargs[
        primary_key: Nilor[Symbol],
        foreign_key: Nilor[Symbol],
        scope: Nilor[Sequel::Dataset, Array],
        setter: Nilor[Or[Symbol, Proc]],
        to_dto: Nilor[Proc],
        reverse: Bool
      ] => Or[Hash, Array]
    )
    def one_to_one(parent_assoc_name, assoc_name, list, scope: nil, primary_key: :id, foreign_key: nil, setter: nil, to_dto: nil, reverse: true)
      return {} if list.empty?

      primary_key ||= :id

      if scope.is_a?(Array)
        items = scope
      else
        assoc_dao = find_dao(assoc_name, parent, scope)

        if reverse
          # has_one
          if !foreign_key
            foreign_key = "#{parent_assoc_name.to_s.gsub(/s$/,'')}_id".to_sym
          end

          root_ids = list.map(&:id).uniq
        else
          # belongs_to
          if !foreign_key
            foreign_key = :"#{assoc_name}_id"
          end

          root_ids = list.map(&:"#{foreign_key}").compact
        end

        scope ||= assoc_dao
        scope = scope.where((reverse ? foreign_key : :id) => root_ids)

        items = add_scopes(scope, global_opts[assoc_name])
      end

      assoc = index_by(items) { _1.send(reverse ? foreign_key : :id) }

      populate_association(
        list,
        assoc,
        assoc_name,
        setter: setter,
        reverse: reverse,
        primary_key: primary_key,
        foreign_key: foreign_key,
        to_dto: to_dto
      )

      assoc
    end

    contract(
      Symbol,
      Symbol,
      Array,
      Kwargs[
        foreign_key: Nilor[Symbol],
        primary_key: Nilor[Symbol],
        scope: Nilor[Sequel::Dataset, Array],
        setter: Nilor[Or[Symbol, Proc]],
        to_dto: Nilor[Proc]
      ] => Or[Hash, Array]
    )
    def one_to_many(parent_assoc_name, assoc_name, list, primary_key: nil, foreign_key: nil, scope: nil, setter: nil, to_dto: nil)
      return {} if list.empty?

      primary_key ||= :id

      if scope.is_a?(Array)
        items = scope
      else
        assoc_dao = nil
        assoc_dao = find_dao(assoc_name, parent, scope)

        foreign_key ||= "#{parent_assoc_name.to_s.gsub(/s$/, '')}_id".to_sym

        root_ids = list.map(&:"#{primary_key}")

        scope ||= assoc_dao
        scope = scope.where(foreign_key => root_ids)

        items = add_scopes(scope, global_opts[assoc_name])
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
        primary_key: primary_key,
        foreign_key: foreign_key,
        to_dto: to_dto,
        multiple: true
      )

      assoc
    end

    contract(
      Array,
      Or[Hash, Array],
      Symbol,
      Kwargs[
        primary_key: Nilor[Symbol],
        foreign_key: Nilor[Symbol],
        reverse: Nilor[Bool],
        setter: Nilor[Or[Symbol, Proc]],
        to_dto: Nilor[Proc],
        multiple: Bool
      ] => Any
    )
    def populate_association(list, association_index, assoc_name, primary_key: nil, foreign_key: nil, reverse: nil, setter: nil, to_dto: nil, multiple: false)
      assoc_setter = if setter
        setter
      else
        "set_#{assoc_name}"
      end

      list.each do |item|
        if setter && setter.is_a?(Proc)
          if to_dto
            assoc_index = {}

            association_index.each do |key, value|
              if value.is_a?(Array)
                assoc_index[key] = value.map { to_dto.call(_1) }
              else
                assoc_index[key] = to_dto.call(value)
              end
            end

            self.instance_exec(item, assoc_index, &assoc_setter)
          else
            self.instance_exec(item, association_index, &assoc_setter)
          end
        else
          key = if reverse.nil?
            primary_key
          else
            if reverse
              primary_key
            else
              foreign_key ? foreign_key : "#{assoc_name}_id"
            end
          end

          value = association_index[item.send(key)]

          if to_dto && !value.nil?
            value = if value.is_a?(Array)
              value.map { to_dto.call(_1) }
            else
              to_dto.call(value)
            end
          end

          value = [] if value.nil? && multiple

          begin
            item.send(assoc_setter, value)
          rescue NoMethodError
            item.send("#{assoc_name}=", value)
          end
        end
      end
    end

    contract(Nilor[Sequel::Dataset], Nilor[Proc] => Array)
    def add_scopes(scope, named_scope)
      res = if named_scope
        named_scope.call(scope)
      else
        scope
      end

      res.all
    end

    def find_dao(assoc_name, parent, scope)
      dao_from_name = parent.instance_variable_get("@#{assoc_name}") || parent.instance_variable_get("@#{assoc_name}s")
      return dao_from_name if dao_from_name

      raise ArgumentError, "can't find DAO for :#{assoc_name}, provide correct scope or association name" if scope.nil?
      return nil if scope.is_a?(Array)

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