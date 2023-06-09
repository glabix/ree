# frozen_string_literal: true

module ReeDao
  class Associations
    include Ree::LinkDSL

    attr_reader :agg_caller, :list, :local_vars, :only, :except, :global_opts

    def initialize(agg_caller, list, local_vars, **opts)
      @agg_caller = agg_caller
      @list = list
      @local_vars = local_vars
      @threads = [] if !self.class.sync_mode?
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

    def self.sync_mode?
      ReeDao.load_sync_associations_enabled?
    end

    contract(
      Symbol,
      Nilor[Sequel::Dataset, Array],
      Ksplat[
        assoc_dao?: Sequel::Dataset,
        setter?: Or[Symbol, Proc],
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
        setter?: Or[Symbol, Proc],
        foreign_key?: Symbol
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
        setter?: Or[Symbol, Proc],
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
        setter?: Or[Symbol, Proc]
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
        setter?: Or[Symbol, Proc],
      ],
      Optblock => Any
    )
    def association(assoc_type, assoc_name, scope = nil, **assoc_opts, &block)
      if self.class.sync_mode?
        return if association_is_not_included?(assoc_name)

        association = ReeDao::Association.new(self, list, **global_opts)
        association.load(assoc_type, assoc_name, scope, **assoc_opts, &block)
      else
        return @threads if association_is_not_included?(assoc_name)

        @threads << Thread.new do
          association = ReeDao::Association.new(self, list, **global_opts)
          association.load(assoc_type, assoc_name, scope, **assoc_opts, &block)
        end
      end
    end

    contract(Symbol => Bool)
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

    contract(Symbol, SplatOf[Any], Optblock => Any)
    def method_missing(method, *args, &block)
      return if !agg_caller.private_methods(false).include?(method)

      agg_caller.send(method, *args, &block)
    end
  end
end