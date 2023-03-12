module ReeActions
  module ActionDSL
    def self.included(base)
      base.extend(ClassMethods)
      base.include(ReeMapper::DSL)
    end

    def self.extended(base)
      base.extend(ClassMethods)
      base.include(ReeMapper::DSL)
    end

    module ClassMethods
      include Ree::Contracts::Core
      include Ree::Contracts::ArgContracts

      def action(name, &proc)
        dsl = Ree::ObjectDsl.new(
          Ree.container.packages_facade, name, self, :fn
        )

        dsl.instance_exec(&proc) if block_given?
        dsl.tags(["action"])
        dsl.freeze(false)
        dsl.object.set_as_compiled(false)

        Ree.container.compile(dsl.package, name)
      end

      def method_added(method_name)
        return super if method_name != :call

        if @__original_call_defined
          remove_instance_variable(:@__original_call_defined)
          return
        end

        @__original_call_defined = true

        alias_method(:__original_call, :call)

        define_method :call do |user_access, attrs|
          if self.class.const_defined?(:ActionCaster)
            caster = self.class.const_get(:ActionCaster)

            if !caster.respond_to?(:cast)
              raise ArgumentError.new("ActionCaster does not respond to `cast` method")
            end

            __original_call(user_access, caster.cast(attrs))
          else
            __original_call(user_access, attrs)
          end
        end

        nil
      end
    end
  end
end