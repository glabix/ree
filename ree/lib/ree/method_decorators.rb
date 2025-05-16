# frozen_string_literal: true

module Ree::MethodDecorators
  autoload :DefinitionStorage, 'ree/method_decorators/definition_storage'
  autoload :DecoratorStorage, 'ree/method_decorators/decorator_storage'
  autoload :DecoratorBuilder, 'ree/method_decorators/decorator_builder'
  autoload :Decoratable, 'ree/method_decorators/decoratable'
  autoload :Base, 'ree/method_decorators/base'

  def self.enabled_decorators=(decorators)
    @enabled_decorators = decorators
  end

  def self.enabled_decorators
    @enabled_decorators
  end

  def self.disabled_decorators=(decorators)
    @disabled_decorators = decorators
  end

  def self.disabled_decorators
    @disabled_decorators
  end

  def self.decorator_disabled?(decorator_class)
    no_method_decorators? ||
      disabled_decorators&.include?(decorator_class) ||
      (enabled_decorators && !enabled_decorators.include?(decorator_class)) ||
      false
  end

  def self.no_method_decorators?
    return @no_method_decorators if defined?(@no_method_decorators)
    @no_method_decorators = false
  end

  def self.disable_decorators
    @no_method_decorators = true
  end

  def self.enable_decorators
    @no_method_decorators = false
  end
end
