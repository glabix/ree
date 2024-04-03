# frozen_string_literal: true

module ReeMapper::DSL
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
    base.include(Ree::Inspectable)
  end

  def self.extended(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  module InstanceMethods
    def build
      self.class.instance_variable_get(:@mapper)
    end
  end

  module ClassMethods
    include Ree::Contracts::Core
    include Ree::Contracts::ArgContracts

    contract Symbol, Optblock => Ree::Object
    def mapper(name, &proc)
      dsl = Ree::ObjectDsl.new(
        Ree.container.packages_facade, name, self, :object
      )

      dsl.instance_exec(&proc) if block_given?
      dsl.tags(["object", "mapper"])
      dsl.factory :build

      Ree.container.compile(dsl.package, name)
    end

    contract(
      Kwargs[
        register_as: Nilor[Symbol]
      ] => ReeMapper::MapperFactoryProxy
    )
    def build_mapper(register_as: nil)
      mapper_factory = ReeMapper.get_mapper_factory(Object.const_get(name.split('::').first))

      mapper_factory.call(register_as: register_as) do |mapper|
        self.instance_variable_set(:@mapper, mapper)
      end
    end
  end
end
