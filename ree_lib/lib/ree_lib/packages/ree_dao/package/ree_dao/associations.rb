# frozen_string_literal: true

module ReeDao
  class ReeDao::Associations
    include Ree::LinkDSL

    link :demodulize, from: :ree_string
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :merge, from: :ree_hash
    link :underscore, from: :ree_string

    attr_reader :list, :dao

    def initialize(list, dao)
      @list = list
      @dao = dao

      @dao.each do |k, v|
        instance_variable_set(k, v)

        self.class.define_method k.to_s.gsub('@', '') do
          v
        end
      end

      @assocs = {}
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
      @assocs = merge(@assocs, association(__method__, assoc_name, scope, **opts, &block), deep: true)
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
    def has_one(assoc_name, scope = nil, **opts, &block)
      @assocs = merge(@assocs, association(__method__, assoc_name, scope, **opts, &block), deep: true)
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
      @assocs = merge(@assocs, association(__method__, assoc_name, scope, **opts, &block), deep: true)
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
      @assocs = merge(@assocs, association(__method__, assoc_name, scope, **opts, &block), deep: true)
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
      if ReeDao.load_sync_associations_enabled?
        if !instance_variable_get(:@sync_store)
          instance_variable_set(:@sync_store, [])
        end

        assoc = load_association_by_type(
          assoc_type,
          assoc_name,
          scope,
          **opts
        )

        process_sync_block(assoc, assoc_name, &block) if block_given?

        { assoc_name => assoc }
      else
        if !instance_variable_get(:@store)
          instance_variable_set(:@store, {})
        end

        if !instance_variable_get(:@threads)
          instance_variable_set(:@threads, [])
        end

        if !instance_variable_get(:@exec_thread)
          instance_variable_set(:@exec_thread, Thread.current)
        end

        t = Thread.new do
          assoc = load_association_by_type(
            assoc_type,
            assoc_name,
            scope,
            **opts
          )

          assoc = process_async_block(assoc, &block) if block_given?

          @store[Thread.current.parent.object_id] ||= {}
          @store[Thread.current.parent.object_id].merge!({ assoc_name => assoc })
          @store[Thread.current.parent.object_id]
        end

        if @threads.include?(find_parent_thread(t))
          t.value
        else
          @threads << t
          @threads
        end
      end
    end

    def load_association_by_type(type, assoc_name, scope, **opts)
      list = @list

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
        items = scope.is_a?(Sequel::Dataset) ? scope.order(:id).paged_each { _1 }.all : scope
      else
        items = assoc_dao.where(foreign_key => root_ids).order(:id).paged_each { _1 }.all
      end

      index_by(items) { _1.send(foreign_key) }
    end

    def one_to_many(assoc_name, list, scope, foreign_key: nil, assoc_dao: nil)
      return if list.empty?

      assoc_dao ||= self.instance_variable_get("@#{assoc_name}")

      foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

      root_ids = list.map(&:id)

      if scope
        items = scope.is_a?(Sequel::Dataset) ? scope.order(:id).paged_each { _1 }.all : scope
      else
        items = assoc_dao.where(foreign_key => root_ids).order(:id).paged_each { _1 }.all
      end

      group_by(items) { _1.send(foreign_key) }
    end

    def find_parent_thread(thr)
      return thr if thr.parent == @exec_thread 

      find_parent_thread(thr.parent)
    end

    def set_parent_association_key(assoc_name)
      @nested_list_store[@current_level][:parent_assoc] ||= []
      previous_parent_assoc = @nested_list_store.dig(@current_level - 1, :parent_assoc)

      if previous_parent_assoc && previous_parent_assoc.size > 0
        @nested_list_store[@current_level][:parent_assoc].push(*previous_parent_assoc)
      end
      
      @nested_list_store[@current_level][:parent_assoc] << assoc_name
    end

    def current_level_store_list
      if ReeDao.load_sync_associations_enabled?
        @nested_list_store[@current_level][:list] 
      else
        Thread.current.parent[:list]
      end
    end

    def current_level_store_dto
      if ReeDao.load_sync_associations_enabled?
        @nested_list_store[@current_level][:dto_class]
      else
        Thread.current.parent[:dto_class]
      end
    end

    def get_current_level_list
      dto = current_level_store_dto
      current_level_store_list.map do |v|
        v.is_a?(Hash) ? dto.new(**v) : v
      end
    end

    def process_async_block(assoc, &block)
      items = assoc.values.flatten

      Thread.current[:list] = items
      Thread.current[:dto_class] = items.first.class

      nested = block.call
      
      assoc = merge(assoc, nested, deep: true)        
      assoc
    end

    def process_sync_block(assoc, assoc_name, &block)
      assoc_list = assoc.values.flatten
      nested_assoc = ReeDao::Associations.new(assoc_list, dao).instance_exec(&block)
      
      attrs = nested_assoc.keys
      assoc_list.each do |item|
        attrs.each do |attr_name|
          setter = "set_#{attr_name}"
          value = nested_assoc[attr_name][item.id]
          item.send(setter, value)
        end
      end
    end
  end
end