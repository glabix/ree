# frozen_string_literal: true

module Ree::BeanDSL
  def self.included(base)
    base.extend(ClassMethods)
  end

  def self.extended(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def bean(name, &proc)
      path = caller[0].split(':').first

      dsl = Ree::ObjectDsl.new(
        Ree.container.packages_facade, name, self, path, :object
      )

      Ree.logger.debug("bean(:#{name}, path: #{path}), object_id=#{dsl.object_id}")

      dsl.instance_exec(&proc) if block_given?
      dsl.object.set_as_compiled(false)
      
      Ree.container.compile(dsl.package, name)
    end
  end
end