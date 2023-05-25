# frozen_string_literal: true

module ReeDao
  class ReeDao::Associations
    include Ree::LinkDSL

    link :demodulize, from: :ree_string
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :underscore, from: :ree_string

    attr_reader :list, :dao, :global_opts

    def initialize(list, dao, **opts)
      @list = list
      @dao = dao
      @threads = [] if !sync_mode?
      @global_opts = opts

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
        foreign_key?: Symbol,
        assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?
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
        foreign_key?: Symbol,
        assoc_dao?: Sequel::Dataset,
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
        foreign_key?: Symbol,
        assoc_dao?: Sequel::Dataset # TODO: change to ReeDao::Dao class?
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
        assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?
        list?: Or[Sequel::Dataset, Array]
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
        polymorphic?: Bool
      ],
      Optblock => Any
    )
    def association(assoc_type, assoc_name, scope = nil, **opts, &block)
      scope = opts[assoc_name] if opts[assoc_name] && !global_opts[assoc_name]
      scope = global_opts[assoc_name] if !opts[assoc_name] && global_opts[assoc_name]

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
      
      populate_association(list, assoc, assoc_name)

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
          reverse: false
        )
      when :has_one
        one_to_one(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao],
          reverse: true
        )
      when :has_many
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao]
        )
      else
        one_to_many(
          assoc_name,
          list,
          scope,
          foreign_key: opts[:foreign_key],
          assoc_dao: opts[:assoc_dao]
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

    def one_to_one(assoc_name, list, scope, foreign_key: nil, assoc_dao: nil, reverse: true)
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

      items = if scope
        if scope.is_a?(Sequel::Dataset)
          scope.all
        else
          scope.call(default_scope).all
        end
      else
        default_scope.all
      end
      
      index_by(items) { _1.send(foreign_key) }
    end

    def one_to_many(assoc_name, list, scope, foreign_key: nil, assoc_dao: nil)
      return if list.empty?

      assoc_dao ||= self.instance_variable_get("@#{assoc_name}")

      foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

      root_ids = list.map(&:id)

      default_scope = assoc_dao&.where(foreign_key => root_ids)

      items = if scope
        if scope.is_a?(Sequel::Dataset)
          scope.all
        else
          scope.call(default_scope).all
        end
      else
        default_scope.all
      end

      group_by(items) { _1.send(foreign_key) }
    end

    def populate_association(list, assoc, assoc_name)
      list.each do |item|
        setter = "set_#{assoc_name}"
        value = assoc[item.id]
        item.send(setter, value)
      end
    end

    def sync_mode?
      ReeDao.load_sync_associations_enabled?
    end
  end
end