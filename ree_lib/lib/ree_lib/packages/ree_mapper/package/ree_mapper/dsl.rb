# frozen_string_literal: true

module ReeMapper::DSL
  def self.included(base)
    setup_semaphore(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  def self.extended(base)
    setup_semaphore(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  def self.setup_semaphore(base)
    mod = Object.const_get(base.name.split('::').first)
    return if mod.const_defined?(:MAPPER_SEMAPHORE)

    mod.const_set(:MAPPER_SEMAPHORE, Mutex.new)
    mod.private_constant :MAPPER_SEMAPHORE
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
      path = caller[0].split(':').first

      dsl = Ree::ObjectDsl.new(
        Ree.container.packages_facade, name, self, path, :object
      )

      dsl.instance_exec(&proc) if block_given?
      dsl.factory :build

      Ree.container.compile(dsl.package, name)
    end

    contract(
      Kwargs[
        register_as: Nilor[Symbol],
        mapper_factory: Nilor[Any],
      ] => ReeMapper::MapperFactoryProxy
    )
    def build_mapper(register_as: nil, mapper_factory: nil)
      build_or_get_mapper_factory(mapper_factory).call(register_as: register_as) do |mapper|
        self.instance_variable_set(:@mapper, mapper)
      end
    end

    private

    def build_or_get_mapper_factory(custom_factory)
      mod = Object.const_get(name.split('::').first)
      factory = mod.instance_variable_get(:@mapper_factory)
      return factory if factory

      mod.const_get(:MAPPER_SEMAPHORE).synchronize do
        factory = custom_factory || build_mapper_factory(mod)
        mod.instance_variable_set(:@mapper_factory, factory)
      end

      factory
    end

    def build_mapper_factory(mod)
      pckg_name = ReeString::Underscore.new.call(mod.name)
      factory_path = "#{pckg_name}/mapper_factory"

      mapper_factory_klass = if package_file_exists?(factory_path) && mod != ReeMapper
        package_require(factory_path)
        Object.const_get("#{mod.name}::MapperFactory")
      else
        ReeMapper::DefaultFactory
      end

      mapper_factory_klass.new
    end
  end
end
