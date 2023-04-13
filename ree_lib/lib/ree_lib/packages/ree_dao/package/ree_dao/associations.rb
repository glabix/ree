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
        assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?,
        list?: Or[Sequel::Dataset, Array]
      ] => Any
      def belongs_to(assoc_name, **opts)
        if !instance_variable_get(:@threads)
          instance_variable_set(:@threads, []) 
        end

        @threads << Thread.new do
          list = opts[:list]
          return if list.empty?
  
          assoc_dao = if !opts[:assoc_dao]
             self.instance_variable_get("@#{assoc_name}s")
          else
            opts[:assoc_dao]
          end
  
          foreign_key = if opts.key?(:foreign_key)
            opts[:foreign_key]
          else
            :id
          end
  
          root_ids = list.map(&:"#{foreign_key}")
  
          { assoc_name => index_by(assoc_dao.where(foreign_key => root_ids).all) { _1.send(foreign_key) } }
        end

        @threads
      end
    
      contract Symbol, Ksplat[
        foreign_key?: Symbol,
        primary_key?: Symbol,
        assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?
        list?: Or[Sequel::Dataset, Array]
      ] => Any
      def has_one(assoc_name, **opts)
        if !instance_variable_get(:@threads)
          instance_variable_set(:@threads, [])
        end

        @threads << Thread.new do
          list = opts[:list]
          return if list.empty?
  
          assoc_dao = if !opts[:assoc_dao]
            self.instance_variable_get("@#{assoc_name}s")
          else
            opts[:assoc_dao]
          end
  
          primary_key = if opts.key?(:primary_key)
            opts[:primary_key]
          else
            :id
          end
  
          foreign_key = if opts.key?(:foreign_key)
            opts[:foreign_key]
          else
            name = underscore(demodulize(list.first.class.name))
            "#{name}_id".to_sym
          end
  
          root_ids = list.map(&:id)
  
          { assoc_name => index_by(assoc_dao.where(foreign_key => root_ids).all) { _1.send(foreign_key) } }
        end

        @threads
      end
    
      contract Symbol, Ksplat[
        foreign_key?: Symbol,
        primary_key?: Symbol,
        assoc_dao?: Sequel::Dataset, # TODO: change to ReeDao::Dao class?
        list?: Or[Sequel::Dataset, Array]
      ], Optblock => Any
      def has_many(assoc_name, **opts, &block)
        if !instance_variable_get(:@threads)
          instance_variable_set(:@threads, [])
        end

        t = Thread.new do
          list = opts[:list]

          return if list.empty?
  
          assoc_dao = if !opts[:assoc_dao]
            self.instance_variable_get("@#{assoc_name}")
          else
            opts[:assoc_dao]
          end

          foreign_key = if opts.key?(:foreign_key)
            opts[:foreign_key]
          else
            name = underscore(demodulize(list.first.class.name))
            "#{name}_id".to_sym
          end

          root_ids = list.map(&:id)

          items = assoc_dao.where(foreign_key => root_ids).all

          nested_assoc = if block_given?
            block.call(items)
          end

          if nested_assoc
            attr = nested_assoc.keys.first

            items.each do |item|
              setter = "set_#{attr}"
              value = nested_assoc[attr][item.id]
              item.send(setter, value)
            end
          end
          
          { assoc_name => group_by(items) { _1.send(foreign_key) } }
        end

        if !block_given?
          t.join
          t.value
        else
          @threads << t
          @threads
        end
      end
    
      def field(name, **opts)
        # TODO
      end
    end
  end
end