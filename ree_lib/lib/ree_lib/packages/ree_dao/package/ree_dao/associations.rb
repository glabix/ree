module ReeDao
  class Associations
    include Ree::LinkDSL

    attr_reader :agg_caller, :list, :local_vars, :only, :except, :parent_dao_name, :autoload_children, :global_opts

    def initialize(agg_caller, list, local_vars, parent_dao_name, autoload_children = false, **opts)
      @agg_caller = agg_caller
      @list = list
      @local_vars = local_vars
      @global_opts = opts || {}
      @only = opts[:only] if opts[:only]
      @except = opts[:except] if opts[:except]
      @parent_dao_name = parent_dao_name
      @autoload_children = autoload_children

      if @only && @except
        shared_keys = @only.intersection(@except)

        if shared_keys.size > 0
          raise ArgumentError.new("you can't use both :only and :except for #{shared_keys.map { "\"#{_1}\"" }.join(", ")} keys") 
        end
      end

      if !self.class.sync_mode?
        @assoc_threads = []
        @field_threads = []
      end

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
      Nilor[Proc, Sequel::Dataset],
      Optblock => Any
    )
    def belongs_to(assoc_name, __opts = nil, &block)
      association(__method__, assoc_name, __opts, &block)
    end

    contract(
      Symbol,
      Nilor[Proc, Sequel::Dataset],
      Optblock => Any
    )
    def has_one(assoc_name, __opts = nil, &block)
      association(__method__, assoc_name, __opts, &block)
    end

    contract(
      Symbol,
      Nilor[Proc, Sequel::Dataset],
      Optblock => Any
    )
    def has_many(assoc_name, __opts = nil, &block)
      association(__method__, assoc_name, __opts, &block)
    end

    contract(Symbol, Proc => Any)
    def field(assoc_name, proc)
      association(__method__, assoc_name, proc)
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
      Nilor[Proc, Sequel::Dataset],
      Optblock => Any
    )
    def association(assoc_type, assoc_name, __opts, &block)
      if self.class.sync_mode?
        return if association_is_not_included?(assoc_name) || list.empty?

        association = Association.new(self, parent_dao_name, list, **global_opts)

        if assoc_type == :field
          association.handle_field(assoc_name, __opts)
        else
          association.load(assoc_type, assoc_name, **get_assoc_opts(__opts), &block)
        end
      else
        if association_is_not_included?(assoc_name) || list.empty?
          return { association_threads: @assoc_threads, field_threads: @field_threads }
        end

        association = Association.new(self, parent_dao_name, list, **global_opts)

        if assoc_type == :field
          field_proc = __opts
          {
            association_threads: @assoc_threads,
            field_threads: @field_threads << [
              association, field_proc
            ]
          }
        else
          {
            association_threads: @assoc_threads << [
              association, assoc_type, assoc_name, get_assoc_opts(__opts), block
            ],
            field_threads: @field_threads
          }
        end
      end
    end

    contract(Symbol => Bool)
    def association_is_not_included?(assoc_name)
      return false if !only && !except

      if only
        return false if only && only.include?(assoc_name)

        if only && !only.include?(assoc_name)
          if autoload_children
            return true if except && except.include?(assoc_name)
            return false
          end
          return true
        end
      end

      if except
        return true if except && except.include?(assoc_name)
        return false if except && !except.include?(assoc_name)
      end
    end

    contract(Symbol, SplatOf[Any], Optblock => Any)
    def method_missing(method, *args, &block)
      return super if !agg_caller.private_methods(false).include?(method)

      agg_caller.send(method, *args, &block)
    end

    def get_assoc_opts(opts)
      if opts.is_a?(Proc)
        opts.call
      elsif opts.is_a?(Sequel::Dataset)
        { scope: opts }
      else
        {}
      end
    end
  end
end