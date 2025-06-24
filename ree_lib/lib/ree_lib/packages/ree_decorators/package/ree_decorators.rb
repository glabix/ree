require 'securerandom'
require 'ostruct'
require 'set'

module ReeDecorators
  include Ree::PackageDSL

  package do
    depends_on :ree_string
  end

  # @param [Array<Class>] decorators
  def self.enabled_decorators=(decorators)
    @enabled_decorators = decorators
  end

  # @return [Array<Class>]
  def self.enabled_decorators
    @enabled_decorators
  end

  # @param [Array<Class>] decorators
  def self.disabled_decorators=(decorators)
    @disabled_decorators = decorators
  end

  # @return [Array<Class>]
  def self.disabled_decorators
    @disabled_decorators
  end

  # @param [Class] decorator
  # @return [Boolean]
  def self.decorator_disabled?(decorator)
    no_decorators? ||
      disabled_decorators&.include?(decorator) ||
      (enabled_decorators && !enabled_decorators.include?(decorator)) ||
      false
  end

  # @return [Boolean]
  def self.no_decorators?
    return @no_decorators if defined?(@no_decorators)
    @no_decorators = false
  end

  # @return [void]
  def self.disable_decorators
    @no_decorators = true
    nil
  end

  # @return [void]
  def self.enable_decorators
    @no_decorators = false
    nil
  end
end

require_relative "ree_decorators/dsl"

require_relative "ree_decorators/errors/base_contract_error"
require_relative "ree_decorators/errors/bad_contract_error"
require_relative "ree_decorators/errors/contract_error"
require_relative "ree_decorators/errors/return_contract_error"
