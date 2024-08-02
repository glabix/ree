module ReeDao
  module AggregateDSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.extended(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def aggregate(name, &proc)
        dsl = Ree::ObjectDsl.new(
          Ree.container.packages_facade, name, self, :fn
        )

        dsl.instance_exec(&proc) if block_given?
        dsl.tags(["aggregate"])
        dsl.freeze(false)
        dsl.object.set_as_compiled(false)
        dsl.link :agg_contract_for, from: :ree_dao

        Ree.container.compile(dsl.package, name)
      end
    end
  end
end