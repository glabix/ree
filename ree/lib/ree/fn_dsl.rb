# frozen_string_literal: true

module Ree::FnDSL
  def self.included(base)
    base.extend(ClassMethods)
  end

  def self.extended(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def fn(name, &proc)
      dsl = Ree::ObjectDsl.new(
        Ree.container.packages_facade, name, self, :fn
      )

      dsl.instance_exec(&proc) if block_given?
      dsl.object.set_as_compiled(false)

      Ree.container.compile(dsl.package, name)
    end
  end
end