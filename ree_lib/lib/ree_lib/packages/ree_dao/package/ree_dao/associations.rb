# frozen_string_literal: true

module ReeDao
  class ReeDao::Associations
    include Ree::LinkDSL

    link :demodulize, from: :ree_string
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :underscore, from: :ree_string

    attr_reader :list, :dao

    def initialize(list, dao)
      @list = list
      @dao = dao
      @threads = []

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
      scope = opts[assoc_name] if opts[assoc_name]
      if ReeDao.load_sync_associations_enabled?
        load_association(assoc_type, assoc_name, scope, **opts, &block)
      else
        @threads << Thread.new do
          load_association(assoc_type, assoc_name, scope, **opts, &block)
        end
      end
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

      if scope
        items = scope.is_a?(Sequel::Dataset) ? scope.all : scope
      else
        items = assoc_dao.where(foreign_key => root_ids).all
      end

      index_by(items) { _1.send(foreign_key) }
    end

    def one_to_many(assoc_name, list, scope, foreign_key: nil, assoc_dao: nil)
      return if list.empty?

      assoc_dao ||= self.instance_variable_get("@#{assoc_name}")

      foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

      root_ids = list.map(&:id)

      if scope
        items = scope.is_a?(Sequel::Dataset) ? scope.all : scope
      else
        items = assoc_dao.where(foreign_key => root_ids).all
      end

      group_by(items) { _1.send(foreign_key) }
    end

    def process_block(assoc, &block)
      assoc_list = assoc.values.flatten
      if ReeDao.load_sync_associations_enabled?
        ReeDao::Associations.new(assoc_list, dao).instance_exec(&block)
      else
        ReeDao::Associations.new(assoc_list, dao).instance_exec(&block).map(&:join)
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

    def populate_association(list, assoc, assoc_name)
      list.each do |item|
        setter = "set_#{assoc_name}"
        value = assoc[item.id]
        item.send(setter, value)
      end
    end
  end
end