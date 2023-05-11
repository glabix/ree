# frozen_string_literal: true

module ReeDao
  module Associations
    def self.included(base)
      base.include(InstanceMethods)
      load_helpers(base)
    end
  
    def self.extended(base)
      base.include(InstanceMethods)
      load_helpers(base)
    end

    private_class_method def self.load_helpers(base)
      base.include(Ree::LinkDSL)
      base.link :index_by, from: :ree_array
      base.link :group_by, from: :ree_array
      base.link :underscore, from: :ree_string
      base.link :demodulize, from: :ree_string
    end
  
    module InstanceMethods
      include Ree::Contracts::Core
      include Ree::Contracts::ArgContracts
  
      contract Symbol, Ksplat[
        foreign_key?: Symbol,
        assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?
      ], Optblock => Any
      def belongs_to(assoc_name, **opts, &block)
        if !instance_variable_get(:@store)
          instance_variable_set(:@store, {})
        end

        if ReeDao.load_sync_associations_enabled?
          if !instance_variable_get(:@sync_store)
            instance_variable_set(:@sync_store, [])
          end

          assoc = { 
            assoc_name => one_to_one(
              assoc_name,
              foreign_key: opts[:foreign_key],
              assoc_dao: opts[:assoc_dao],
              reverse: false,
              block: block
            ) 
          }

          if @current_level == 0
            @store = {}
            @sync_store << assoc
            @sync_store
          else
            if block
              @store[block.object_id] ||= {}
              @store[block.object_id].merge!(assoc)
              @store[block.object_id]
            else
              @store.merge!(assoc)
              @store
            end
          end
        else
          if !instance_variable_get(:@threads)
            instance_variable_set(:@threads, []) 
          end
  
          t = Thread.new do
            items = one_to_one(
              assoc_name,
              foreign_key: opts[:foreign_key],
              assoc_dao: opts[:assoc_dao],
              reverse: false,
              block: block
            )

            @store[Thread.current.parent.object_id] ||= {}
            store = @store[Thread.current.parent.object_id]
            store.merge!({ assoc_name => items })
            store
          end
  
          if @threads.include?(find_parent_thread(t))
            t.join
            t.value
          else
            @threads << t
            @threads
          end
        end 
      end
    
      contract Symbol, Ksplat[
        foreign_key?: Symbol,
        assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?
      ], Optblock => Any
      def has_one(assoc_name, **opts, &block)
        if !instance_variable_get(:@store)
          instance_variable_set(:@store, {})
        end

        if ReeDao.load_sync_associations_enabled?
          if !instance_variable_get(:@sync_store)
            instance_variable_set(:@sync_store, [])
          end
          
          assoc = { 
            assoc_name => one_to_one(
              assoc_name,
              foreign_key: opts[:foreign_key],
              assoc_dao: opts[:assoc_dao],
              reverse: true,
              block: block
            )
          }

          if @current_level == 0
            @store = {}
            @sync_store << assoc
            @sync_store
          else
            @store.merge!(assoc)
            @store
          end
        else
          if !instance_variable_get(:@threads)
            instance_variable_set(:@threads, [])
          end
  
          t = Thread.new do
            items = one_to_one(
              assoc_name,
              foreign_key: opts[:foreign_key],
              assoc_dao: opts[:assoc_dao],
              reverse: true,
              block: block
            )

            @store[Thread.current.parent.object_id] ||= {}
            store = @store[Thread.current.parent.object_id]
            store.merge!({ assoc_name => items })
            store
          end
  
          if @threads.include?(find_parent_thread(t))
            t.join
            t.value
          else
            @threads << t
            @threads
          end
        end
      end
    
      contract Symbol, Ksplat[
        foreign_key?: Symbol,
        assoc_dao?: Sequel::Dataset # TODO: change to ReeDao::Dao class?
      ], Optblock => Any
      def has_many(assoc_name, **opts, &block)
        if !instance_variable_get(:@store)
          instance_variable_set(:@store, {})
        end

        if ReeDao.load_sync_associations_enabled?
          if !instance_variable_get(:@sync_store)
            instance_variable_set(:@sync_store, [])
          end

          assoc = {
            assoc_name => one_to_many(
              assoc_name,
              foreign_key: opts[:foreign_key],
              assoc_dao: opts[:assoc_dao],
              block: block
            )
          }

          if @current_level == 0
            @store = {}
            @sync_store << assoc
            @sync_store
          else
            if block
              @store[block.object_id] ||= {}
              @store[block.object_id].merge!(assoc)
              @store[block.object_id]
            else
              @store.merge!(assoc)
              @store
            end
          end
        else
          if !instance_variable_get(:@threads)
            instance_variable_set(:@threads, [])
          end
  
          t = Thread.new do
            items = one_to_many(
              assoc_name,
              foreign_key: opts[:foreign_key],
              assoc_dao: opts[:assoc_dao],
              block: block
            )

            @store[Thread.current.parent.object_id] ||= {}
            store = @store[Thread.current.parent.object_id]
            store.merge!({ assoc_name => items })
            store
          end
  
          if @threads.include?(find_parent_thread(t))
            t.join
            t.value
          else
            @threads << t
            @threads
          end
        end
      end
    
      contract(
        Symbol,
        Ksplat[
          assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?
          list?: Or[Sequel::Dataset, Array]
        ], Optblock => Any
      )
      def field(name, **opts, &block)
        if ReeDao.load_sync_associations_enabled?
          # TODO: sync custom field logic
        else
          list = opts[:list]
          return if list.empty?

          # TODO: complete custom field logic
        end
      end

      private

      def one_to_one(assoc_name, foreign_key: nil, assoc_dao: nil, reverse: true, block: nil)
        dto = current_level_store_dto
        list = if current_level_store_list.first.is_a?(Hash)
          current_level_store_list.map do |v|
            dto.new(**v)
          end
        else
          current_level_store_list
        end
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

        items = assoc_dao.where(foreign_key => root_ids).all

        if block
          @current_level += 1
          @nested_list_store[@current_level] ||= {}
          @nested_list_store[@current_level][:dto] = items.first.class
          @nested_list_store[@current_level][:list] = items

          nested_assoc = block.call(items)
          items.each do |item|
            nested_assoc.keys.each do |attr_name|
              setter = "set_#{attr_name}"
              value = nested_assoc[attr_name][item.id]
              ss = item.send(setter, value)
            end
          end

          @current_level -= 1
        end

        index_by(items) { _1.send(foreign_key) }
      end

      def one_to_many(assoc_name, foreign_key: nil, assoc_dao: nil, block: nil)
        dto = current_level_store_dto
        list = if current_level_store_list.first.is_a?(Hash)
          current_level_store_list.map do |v|
            dto.new(**v)
          end
        else
          current_level_store_list
        end
        return if list.empty?

        assoc_dao ||= self.instance_variable_get("@#{assoc_name}")

        foreign_key ||= "#{underscore(demodulize(list.first.class.name))}_id".to_sym

        root_ids = list.map(&:id)
        items = assoc_dao.where(foreign_key => root_ids).all

        if block
          @current_level += 1
          @nested_list_store[@current_level] = {}
          @nested_list_store[@current_level][:dto] = items.first.class
          @nested_list_store[@current_level][:list] = items

          nested_assoc = block.call(items)
          items.each do |item|
            nested_assoc.keys.each do |attr_name|
              setter = "set_#{attr_name}"
              value = nested_assoc[attr_name][item.id]
              ss = item.send(setter, value)
            end
          end

          @current_level -= 1
        end

        group_by(items) { _1.send(foreign_key) }
      end

      def find_parent_thread(thr)
        return thr if thr.parent == Thread.main

        find_parent_thread(thr.parent)
      end

      def current_level_store_list
        @nested_list_store[@current_level][:list]
      end

      def current_level_store_dto
        @nested_list_store[@current_level][:dto_class]
      end
    end
  end
end