module ReeEnum
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.extended(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def enum(name, &proc)
        dsl = Ree::ObjectDsl.new(
          Ree.container.packages_facade, name, self, :object
        )

        dsl.instance_exec(&proc) if block_given?

        klass = dsl.object.klass
        klass.send(:include, ReeEnum::Enumerable)
        klass.setup_enum(dsl.object.name)
        Ree.container.compile(dsl.package, name)
      end
    end
  end
end