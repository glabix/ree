module ReeDao
  module AggregateDSL
    def self.included(base)
      base.extend(ClassMethods)
      base.include(ReeDao::Associations)
    end

    def self.extended(base)
      base.extend(ClassMethods)
      base.include(ReeDao::Associations)
    end

    module ClassMethods
      def aggregate(name, &proc)
        dsl = Ree::ObjectDsl.new(
          Ree.container.packages_facade, name, self, :object
        )

        dsl.instance_exec(&proc) if block_given?
        dsl.tags(["aggregate"])
        dsl.freeze(false)
        dsl.object.set_as_compiled(false)

        Ree.container.compile(dsl.package, name)
      end
    end
  end
end