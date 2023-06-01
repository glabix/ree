# frozen_string_literal: true

module ReeDao
  class ReeDao::Associations
    include Ree::LinkDSL

    link :demodulize, from: :ree_string
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :underscore, from: :ree_string

    attr_reader :list, :local_vars, :only, :except, :global_opts

    def initialize(list, local_vars, **opts)
      @list = list
      @local_vars = local_vars
      @threads = [] if !sync_mode?
      @global_opts = opts
      @only = opts[:only] if opts[:only]
      @except = opts[:except] if opts[:except]

      raise ArgumentError.new("you can't use both :only and :except arguments at the same time") if @only && @except

      local_vars.each do |k, v|
        instance_variable_set(k, v)

        self.class.define_method k.to_s.gsub('@', '') do
          v
        end
      end
    end

    contract(
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[
        assoc_dao?: Sequel::Dataset,
        assoc_setter?: Symbol,
        setter_proc?: Proc,
        foreign_key?: Symbol
      ],
      Optblock => Any
    )
    def belongs_to(assoc_name, scope = nil, **opts, &block)
      association(__method__, assoc_name, scope, **opts, &block)
    end
  
    contract(
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[
        assoc_dao?: Sequel::Dataset,
        assoc_setter?: Symbol,
        setter_proc?: Proc,
        foreign_key?: Symbol,
      ],
      Optblock => Any
    )
    def has_one(assoc_name, scope = nil, **opts, &block)
      association(__method__, assoc_name, scope, **opts, &block)
    end
  
    contract(
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[
        assoc_dao?: Sequel::Dataset,
        assoc_setter?: Symbol,
        setter_proc?: Proc,
        foreign_key?: Symbol
      ],
      Optblock => Any
    )
    def has_many(assoc_name, scope = nil, **opts, &block)
      association(__method__, assoc_name, scope, **opts, &block)
    end
  
    contract(
      Symbol,
      Or[Sequel::Dataset, Array],
      Ksplat[
        assoc_dao?: Sequel::Dataset,
        assoc_setter?: Symbol,
        setter_proc?: Proc
      ],
      Optblock => Any
    )
    def field(assoc_name, scope = nil, **opts, &block)
      association(__method__, assoc_name, scope, **opts, &block)
    end

    contract(
      Sequel::Dataset,
      Ksplat[RestKeys => Any] => Any
    ) 
    def build_scope(scope, **opts)
      # TODO
    end

    private

    contract(
      Or[
        :belongs_to,
        :has_one,
        :has_many,
        :field
      ],
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[
        foreign_key?: Symbol,
        assoc_dao?: Sequel::Dataset,
        assoc_setter?: Symbol,
        setter_proc?: Proc,
        polymorphic?: Bool
      ],
      Optblock => Any
    )
    def association(assoc_type, assoc_name, scope = nil, **opts, &block)
      if sync_mode?
        return if association_is_not_included?(assoc_name)

        load_association(assoc_type, assoc_name, scope, **opts, &block)
      else
        return @threads if association_is_not_included?(assoc_name)

        @threads << Thread.new do
          load_association(assoc_type, assoc_name, scope, **opts, &block)
        end
      end
    end

    def load_association(assoc_type, assoc_name, scope, **opts, &block)
      assoc = load_association_by_type(
        assoc_type,
        assoc_name,
        scope,
        **opts
      )

      process_block(assoc, &block) if block_given?

      list
    end

    def load_association_by_type(type, assoc_name, scope, **opts)
      case type
      when :belongs_to
        one_to_one(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          assoc_setter: opts[:assoc_setter],
          setter_proc: opts[:setter_proc],
          reverse: false
        )
      when :has_one
        one_to_one(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          assoc_setter: opts[:assoc_setter],
          setter_proc: opts[:setter_proc],
          reverse: true
        )
      when :has_many
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          assoc_setter: opts[:assoc_setter],
          setter_proc: opts[:setter_proc]
        )
      else
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          assoc_setter: opts[:assoc_setter],
          setter_proc: opts[:setter_proc]
        )
      end
    end

    def process_block(assoc, &block)
      assoc_list = assoc.values.flatten
      if sync_mode?
        ReeDao::Associations.new(assoc_list, local_vars, **global_opts).instance_exec(&block)
      else
        ReeDao::Associations.new(assoc_list, local_vars, **global_opts).instance_exec(&block).map(&:join)
      end
    end

    def one_to_one(
      assoc_name,
      list,
      scope,
      foreign_key: nil,
      assoc_dao: nil,
      assoc_setter: nil,
      setter_proc: nil,
      reverse: true
    )
      return if list.empty?

      assoc_dao ||= self.instance_variable_get("@#{assoc_name}s")

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

      items = add_scopes(assoc_name, default_scope, scope, global_opts)

      assoc = index_by(items) { _1.send(foreign_key) }

      populate_association(
        list,
        assoc,
        assoc_name,
        assoc_setter: assoc_setter,
        reverse: reverse,
        setter_proc: setter_proc
      )

      assoc
    end

    def one_to_many(
      assoc_name,
      list,
      scope,
      foreign_key: nil,
      assoc_dao: nil,
      assoc_setter: nil,
      setter_proc: nil
    )
      return if list.empty?

      assoc_dao ||= self.instance_variable_get("@#{assoc_name}")

      foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

      root_ids = list.map(&:id)

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = add_scopes(assoc_name, default_scope, scope, global_opts)

      assoc = group_by(items) { _1.send(foreign_key) }

      populate_association(
        list,
        assoc,
        assoc_name,
        assoc_setter: assoc_setter,
        setter_proc: setter_proc
      )

      assoc
    end

    def populate_association(
      list,
      association_items,
      assoc_name,
      assoc_setter: nil,
      reverse: nil,
      setter_proc: nil
    )
      setter = if assoc_setter
        assoc_setter
      else
        "set_#{assoc_name}"
      end

      list.each do |item|
        if setter_proc
          self.instance_exec(item, setter, association_items, &setter_proc)
        else
          key = if reverse.nil?
            :id
          else
            reverse ? :id : "#{assoc_name}_id"
          end
          value = association_items[item.send(key)]
          next if value.nil?

          item.send(setter, value)
        end
      end
    end

    def add_scopes(assoc_name, default_scope, scope, opts = {})
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

      if opts[assoc_name]
        res = opts[assoc_name].call(res)
      end

      res.all
    end

    def association_is_not_included?(assoc_name)
      return false if !only && !except

      if only
        return false if only && only.include?(assoc_name)
        return true if only && !only.include?(assoc_name)
      end

      if except
        return true if except && except.include?(assoc_name)
        return false if except && !except.include?(assoc_name)
      end
    end

    def sync_mode?
      ReeDao.load_sync_associations_enabled?
    end
  end
end