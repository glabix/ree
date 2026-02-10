# frozen_string_literal: true
package_require("ree_mapper/errors/type_error")
package_require("ree_mapper/errors/coercion_error")
package_require("ree_actions/method_plugin")

module ReeActions
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(Ree::MethodAddedHook)
      base.include(ReeMapper::DSL)
      base.include(Ree::Inspectable)
    end

    def self.extended(base)
      base.extend(ClassMethods)
      base.extend(Ree::MethodAddedHook)
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
    end
  end
end

# Register the method plugin if the plugin system is available
if defined?(Ree) && Ree.respond_to?(:register_method_added_plugin)
  Ree.register_method_added_plugin(ReeActions::MethodPlugin)
end