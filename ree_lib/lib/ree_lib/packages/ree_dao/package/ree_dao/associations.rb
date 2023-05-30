# frozen_string_literal: true

module ReeDao
  class ReeDao::Associations
    include Ree::LinkDSL

    link :demodulize, from: :ree_string
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :underscore, from: :ree_string

    attr_reader :list, :dao, :only, :except, :global_opts

    def initialize(list, dao, **opts)
      @list = list
      @dao = dao
      @threads = [] if !sync_mode?
      @global_opts = opts
      @only = opts[:only] if opts[:only]
      @except = opts[:except] if opts[:except]

      raise ArgumentError.new("you can't use both :only and :except arguments at the same time") if @only && @except

      dao.each do |k, v|
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
        foreign_key?: Symbol,
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
        assoc_setter?: Symbol
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
        polymorphic?: Bool
      ],
      Optblock => Any
    )
    def association(assoc_type, assoc_name, scope = nil, **opts, &block)
      return if association_is_not_included?(assoc_name)

      if sync_mode?
        load_association(assoc_type, assoc_name, scope, **opts, &block)
      else
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
          reverse: true
        )
      when :has_many
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          assoc_setter: opts[:assoc_setter]
        )
      else
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          assoc_setter: opts[:assoc_setter]
        )
      end
    end

    def process_block(assoc, &block)
      assoc_list = assoc.values.flatten
      if sync_mode?
        ReeDao::Associations.new(assoc_list, dao, **global_opts).instance_exec(&block)
      else
        ReeDao::Associations.new(assoc_list, dao, **global_opts).instance_exec(&block).map(&:join)
      end
    end

    def one_to_one(assoc_name, list, scope, foreign_key: nil, assoc_dao: nil, assoc_setter: nil, reverse: true)
      return if list.empty?

      assoc_dao ||= self.instance_variable_get("@#{assoc_name}s")

      foreign_key ||= if reverse
        name = underscore(demodulize(list.first.class.name))
        "#{name}_id".to_sym
      else
        :id
      end

      root_ids = if reverse
        list.map(&:id)
      else
        list.map(&:"#{foreign_key}")
      end

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = add_scopes(assoc_name, default_scope, scope, global_opts)

      assoc = index_by(items) { _1.send(foreign_key) }

      populate_association(list, assoc, assoc_name, assoc_setter)

      assoc
    end

    def one_to_many(assoc_name, list, scope, foreign_key: nil, assoc_dao: nil, assoc_setter: nil)
      return if list.empty?

      assoc_dao ||= self.instance_variable_get("@#{assoc_name}")

      foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

      root_ids = list.map(&:id)

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = add_scopes(assoc_name, default_scope, scope, global_opts)

      assoc = group_by(items) { _1.send(foreign_key) }

      populate_association(list, assoc, assoc_name, assoc_setter)

      assoc
    end

    def populate_association(list, association_items, assoc_name, assoc_setter)
      setter = if assoc_setter
        assoc_setter
      else
        "set_#{assoc_name}"
      end

      list.each do |item|
        value = association_items[item.id]
        item.send(setter, value)
      end
    end

    def add_scopes(assoc_name, default_scope, scope, opts = {})
      res = default_scope

      if scope
        scope_ids = scope.select(:id).all.map(&:id)
        res = res ? res.where(id: scope_ids) : scope
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